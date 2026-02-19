# Flightclaw

MCP server for flight search and price tracking via Google Flights.

## Architecture

- `server.py` — MCP server entry point. Exposes 6 tools via `FastMCP` (from `mcp` package). Runs on STDIO transport.
- `scripts/search_utils.py` — Shared utility for currency detection and raw Google Flights API calls. Imported by `server.py` via `sys.path` insert.
- `scripts/*.py` — Standalone CLI tools (search, track, check prices, list tracked). Not part of the MCP server.
- `build.sh` — Builds a self-contained scie binary using PEX with lazy PBS Python fetching.
- `.github/workflows/release.yml` — Builds scie binaries for 4 platforms on release tag push.

## Dependencies

Direct: `flights` (provides `fli` module), `mcp[cli]` (provides `FastMCP`).

Install for development:
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install flights "mcp[cli]"
```

## Key Patterns

- Data directory: controlled by `FLIGHTCLAW_DATA_DIR` env var, defaults to `~/.flightclaw/data/`.
- Multi-route expansion: comma-separated airport codes and date ranges expand into all combinations via `_expand_routes()`.
- Currency detection: `search_utils.search_with_currency()` extracts currency from base64 booking tokens in the Google Flights response.

## Build

```bash
# Local build (auto-detects platform)
bash build.sh

# CI build (with platform suffix and cross-compilation)
OUTPUT_SUFFIX=macos-arm64 SCIE_PLATFORM=macos-x86_64 bash build.sh
```

Build output goes to `dist/`. The scie binary targets Python 3.13 via PBS.

## Release

Tag with `v*` pattern and push to trigger the release workflow:
```bash
git tag v0.x.0 && git push upstream v0.x.0
```

Produces binaries for: `macos-arm64`, `macos-x86_64`, `linux-x86_64`, `linux-arm64`.

## Testing

Run the MCP server locally:
```bash
python3 server.py                    # from source
./dist/flightclaw                    # from scie binary
```

The server runs on STDIO — it waits for JSON-RPC input from an MCP client. To test with Claude Code:
```bash
claude mcp add flightclaw -- python3 server.py
```
