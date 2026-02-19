# Technical Report: Flightclaw

## Context

This report documents the architecture, build pipeline, and deployment of flightclaw — an MCP server for flight search and price tracking via Google Flights. The project evolved from standalone CLI scripts into a packaged MCP server distributed as self-contained scie binaries.

## 1. System Architecture

```
┌─────────────────────────────────────────────────────────┐
│  MCP Client (Claude Code / Claude Desktop)              │
│                                                         │
│  ┌───────────────────────┐                              │
│  │  JSON-RPC over STDIO  │                              │
│  └───────────┬───────────┘                              │
└──────────────┼──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  server.py (FastMCP)                                    │
│                                                         │
│  ┌────────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │ search_flights  │  │ search_dates│  │ track_flight │ │
│  ├────────────────┤  ├─────────────┤  ├──────────────┤ │
│  │ check_prices   │  │ list_tracked│  │remove_tracked│ │
│  └───────┬────────┘  └──────┬──────┘  └──────┬───────┘ │
│          │                  │                 │         │
│  ┌───────▼──────────────────▼─────────────────▼───────┐ │
│  │  search_utils.py (currency detection, raw API)     │ │
│  └───────────────────────┬────────────────────────────┘ │
│                          │                              │
│  ┌───────────────────────▼────────────────────────────┐ │
│  │  fli library (Google Flights API client)           │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │  ~/.flightclaw/data/tracked.json (persistence)     │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Transport

STDIO only. The server reads JSON-RPC requests from stdin and writes responses to stdout. No HTTP, no ports. The MCP client (Claude Code or Claude Desktop) spawns the server as a subprocess and communicates over pipes.

### Data Flow

1. Client sends tool invocation (e.g., `search_flights`) via JSON-RPC
2. `server.py` parses parameters, expands multi-route/date combinations via `_expand_routes()`
3. `search_utils.search_with_currency()` makes raw POST to Google Flights API
4. Currency is extracted from base64 booking tokens in the response
5. Results are formatted and returned as a text string to the client
6. For tracking tools, state is persisted to `tracked.json`

## 2. Source Files

| File | Lines | Role |
|------|-------|------|
| `server.py` | 627 | MCP server — 6 tools, route expansion, tracking persistence |
| `scripts/search_utils.py` | 104 | Currency detection, raw Google Flights API calls |
| `scripts/search-flights.py` | 138 | CLI: search flights |
| `scripts/track-flight.py` | 167 | CLI: add route tracking |
| `scripts/check-prices.py` | 152 | CLI: check tracked prices (cron-friendly) |
| `scripts/list-tracked.py` | 61 | CLI: list tracked flights |
| `build.sh` | 43 | Scie binary build script |
| `.github/workflows/release.yml` | 74 | CI: 4-platform release workflow |

**Total**: ~1,366 lines across all source files.

## 3. MCP Tools

### search_flights

Searches Google Flights with full filtering. Supports comma-separated origins/destinations (cartesian product) and date ranges. Parameters: origin, destination, date, date_to, return_date, cabin (4 classes), stops (4 options), results count, passenger types (adults/children/infants), airlines, max_price, max_duration, time restrictions (departure/arrival windows), max_layover_duration, sort_by.

### search_dates

Calendar view of cheapest prices across a date range. Returns one price per day. Supports optional trip_duration for flexible round-trip return dates.

### track_flight / check_prices / list_tracked / remove_tracked

Price tracking lifecycle. `track_flight` creates a persistent entry with optional target_price. `check_prices` re-queries all tracked routes, appends to price_history, and alerts on threshold breaches. State lives in `~/.flightclaw/data/tracked.json` (configurable via `FLIGHTCLAW_DATA_DIR` env var).

## 4. Build Pipeline

### Scie Binary Format

The distribution uses **scie** (Self-Contained Interpreted Executable) — a hybrid binary format that concatenates a native Rust launcher (scie-jump) with a PEX archive containing all Python dependencies. The "lazy" variant downloads a Python Build Standalone (PBS) interpreter on first run (~18MB), caching it in `~/.nce/`.

```
┌──────────────────────────────────────┐
│  scie-jump (native Mach-O / ELF)     │  ~5.3 MB
├──────────────────────────────────────┤
│  PEX archive (wheels + source)       │  ~39 MB
│   ├── flights + transitive deps      │
│   ├── mcp[cli] + transitive deps     │
│   ├── server.py                      │
│   └── search_utils.py                │
├──────────────────────────────────────┤
│  lift.json manifest                  │  ~2 KB
└──────────────────────────────────────┘
```

### build.sh

```
Input:   server.py, scripts/search_utils.py, PyPI packages
Tool:    PEX 2.90.1
Output:  dist/flightclaw (~44 MB)
```

Key PEX flags:

| Flag | Purpose |
|------|---------|
| `-M server` | Bundle server.py as importable module |
| `-M search_utils@scripts` | Bundle scripts/search_utils.py |
| `-m server` | Entry point: `python -m server` |
| `--scie lazy` | Lazy PBS download on first run |
| `--scie-python-version 3.13` | Target CPython 3.13 |
| `--scie-pbs-release 20260211` | Pin PBS release (avoids GitHub API rate limits) |
| `--venv` | Real venv at runtime (required for native extensions) |
| `--venv-site-packages-copies` | Copy packages for portability |

Environment variables for CI: `OUTPUT_SUFFIX`, `SCIE_PLATFORM`, `PBS_RELEASE`, `PYTHON_VERSION`.

### Runtime Bootstrap (first run)

```
./flightclaw
  → scie-jump reads lift.json from EOF
  → ptex downloads CPython 3.13 PBS (~18 MB) to ~/.nce/
  → PEX creates venv, installs wheels from embedded archive
  → python -m server runs → mcp.run() → STDIO transport
  → Subsequent runs: ~50ms startup (cached)
```

## 5. Release Workflow

**Trigger**: `git tag v* && git push upstream v*`

**Matrix**:

| Runner | Platform | Method |
|--------|----------|--------|
| `macos-14` | macOS arm64 | Native build |
| `macos-14` | macOS x86_64 | Cross-compile via `--scie-platform` |
| `ubuntu-latest` | Linux x86_64 | Native build |
| `ubuntu-24.04-arm` | Linux arm64 | Native build |

**Auth**: `SCIENCE_AUTH_API_GITHUB_COM_BEARER: ${{ github.token }}` — the `science` tool (invoked by PEX) fetches PBS release metadata from GitHub API. Without a token, it hits the 60 req/hr unauthenticated rate limit.

**Artifacts**: 4 platform binaries + `checksums.txt` (SHA-256), attached to GitHub Release with auto-generated release notes.

### Issues Encountered and Resolved

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `macos-13` runner unsupported | GitHub deprecated Intel macOS runners | Cross-compile from `macos-14` with `--scie-platform macos-x86_64` |
| `403 rate limit exceeded` on PBS lookup | `science` tool hits unauthenticated GitHub API | Set `SCIENCE_AUTH_API_GITHUB_COM_BEARER` (not `GITHUB_TOKEN`) |
| `PLATFORM_ARGS[@]: unbound variable` | Empty bash array expansion fails under `set -u` | Build `PEX_ARGS` array first, conditionally append `--scie-platform` |

## 6. Tracked Data Schema

```json
{
  "id": "LHR-JFK-2025-07-01",
  "origin": "LHR",
  "destination": "JFK",
  "date": "2025-07-01",
  "return_date": null,
  "cabin": "ECONOMY",
  "stops": "ANY",
  "target_price": 400.0,
  "currency": "USD",
  "added_at": "2025-02-19T14:30:00+00:00",
  "price_history": [
    {
      "timestamp": "2025-02-19T14:30:00+00:00",
      "best_price": 520.50,
      "airline": "British Airways"
    }
  ]
}
```

Location: `~/.flightclaw/data/tracked.json` (default) or `FLIGHTCLAW_DATA_DIR` env var override.

## 7. Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `FLIGHTCLAW_DATA_DIR` | `~/.flightclaw/data/` | Tracked flight data location |
| `PYTHON_VERSION` | `3.13` | PBS Python target for scie build |
| `PBS_RELEASE` | `20260211` | Pinned PBS release tag |
| `OUTPUT_SUFFIX` | (empty) | Platform suffix for binary name |
| `SCIE_PLATFORM` | (empty) | Cross-compilation target |
| `SCIENCE_AUTH_API_GITHUB_COM_BEARER` | (empty) | GitHub token for PBS API (CI) |

## 8. Git History

```
8f710c3  update: add CLAUDE.md, skills, and README install docs
f2454e9  fix: resolve scie build failures on macOS
53615f5  fix: update README with install guide and fix release workflow
eef0367  feat: add scie binary build and release workflow
a0b9fc6  Add full fli library support: passengers, airlines, times, dates
107fff2  Add MCP server for flight search and tracking tools
9bdbb6e  Add multi-day and multi-route support for search and tracking
b30b3f0  Initial commit
```

Remotes:
- `origin`: https://github.com/jackculpan/flightclaw (upstream fork source)
- `upstream`: https://github.com/kyujin-cho/flightclaw (primary)

## 9. Skill System

### japan-korea-flights-SKILL.md

A Claude Desktop Skill (250 lines) that teaches Claude to efficiently search all ~30 nonstop Japan-Korea airport pairs. Contains:
- Complete route map: 30+ Japanese origins to 6 Korean destinations
- 14 airline codes (FSC/LCC/hybrid)
- Batching strategy: ~10 API calls to cover all routes
- Google Flights booking link URL format
- Output template with ranked tables and summary stats

Installed as Claude Desktop project knowledge or per-conversation attachment.

### Claude Code Commands

| Command | Purpose |
|---------|---------|
| `/project:build` | Build scie binary locally |
| `/project:release` | Determine version, tag, push to trigger CI |
| `/project:test-server` | Verify MCP server starts without errors |
