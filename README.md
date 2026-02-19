# flightclaw

Track flight prices from Google Flights. Search routes, monitor prices over time, and get alerts when prices drop.

## Install

### Pre-built binary (recommended)

Download a self-contained binary from the [latest release](https://github.com/kyujin-cho/flightclaw/releases/latest). No Python installation required.

| Platform | Binary |
|----------|--------|
| macOS (Apple Silicon) | `flightclaw-macos-arm64` |
| macOS (Intel) | `flightclaw-macos-x86_64` |
| Linux (x86_64) | `flightclaw-linux-x86_64` |
| Linux (arm64) | `flightclaw-linux-arm64` |

```bash
# Download (example: macOS Apple Silicon)
curl -Lo flightclaw https://github.com/kyujin-cho/flightclaw/releases/latest/download/flightclaw-macos-arm64
chmod +x flightclaw
```

#### Claude Code

```bash
claude mcp add flightclaw -- /path/to/flightclaw
```

#### Claude Desktop

Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "flightclaw": {
      "command": "/path/to/flightclaw"
    }
  }
}
```

Config file location by OS:

| OS | Path |
|----|------|
| macOS | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Windows | `%APPDATA%\Claude\claude_desktop_config.json` |
| Linux | `~/.config/Claude/claude_desktop_config.json` |

The first run downloads a Python runtime (~18MB) and sets up the environment. Subsequent runs start instantly.

Price tracking data is stored in `~/.flightclaw/data/`. Set `FLIGHTCLAW_DATA_DIR` to customize.

### From source

```bash
pip install flights "mcp[cli]"
claude mcp add flightclaw -- python3 /path/to/flightclaw/server.py
```

### Japan-Korea Flight Search Skill

The [`japan-korea-flights-SKILL.md`](japan-korea-flights-SKILL.md) skill teaches Claude how to efficiently search all nonstop routes from Japan to South Korea using flightclaw. It includes a complete airport route map, batching strategy, and output formatting instructions.

To install as a Claude Desktop Skill:

1. Open **Claude Desktop** and go to the conversation where you want the skill available
2. Click the **Attach** (📎) button, then select **Add from computer**
3. Choose the `japan-korea-flights-SKILL.md` file from this repository
4. Claude will now follow the skill instructions when you ask about Japan-Korea flights

Alternatively, add it to a **Claude Desktop Project** for persistent use:

1. Go to **Projects** and create or open a project
2. Under **Project knowledge**, click **Add content** and upload `japan-korea-flights-SKILL.md`
3. All conversations within this project will have access to the skill

## MCP Server

FlightClaw runs as a local [MCP](https://modelcontextprotocol.io) server, giving any MCP-compatible client (Claude Code, Claude Desktop, etc.) access to flight search and tracking tools.

### Tools

| Tool | Description |
|------|-------------|
| `search_flights` | Search Google Flights for prices on a route |
| `search_dates` | Find cheapest dates to fly across a date range (calendar view) |
| `track_flight` | Add a route to price tracking with optional target price |
| `check_prices` | Check all tracked flights for price changes and alerts |
| `list_tracked` | List all tracked flights with price history |
| `remove_tracked` | Remove a route from tracking |

### Search filters

All search tools support:

- **Passengers** - adults, children, infants (in seat or on lap)
- **Airlines** - filter to specific carriers (e.g. `BA,AA,DL`)
- **Price limit** - max price in USD
- **Duration** - max total flight time in minutes
- **Times** - earliest/latest departure and arrival hours
- **Layovers** - max layover duration in minutes
- **Sorting** - by BEST, CHEAPEST, DEPARTURE, ARRIVAL, or DURATION
- **Multi-airport** - comma-separated codes (e.g. `LHR,MAN`)
- **Date ranges** - `date_to` for searching each day in a range

### Example prompts

- "Search flights from LHR to JFK on 2025-08-01 in business class"
- "Find nonstop BA or VS flights LHR to JFK departing after 8am"
- "What are the cheapest dates to fly LHR to JFK in July?"
- "Search for 2 adults and 1 child, LHR to JFK, under $500"
- "Track LHR to SFO on 2025-07-01 with a target price of $400"
- "Check my tracked flights for price drops"

## CLI Scripts

The original CLI scripts are still available in `scripts/`:

```bash
# Search flights
python scripts/search-flights.py LHR JFK 2025-07-01 --cabin BUSINESS

# Multiple airports and date ranges
python scripts/search-flights.py LHR,MAN JFK,EWR 2025-07-01 --date-to 2025-07-05

# Track a route
python scripts/track-flight.py LHR JFK 2025-07-01 --target-price 400

# Check for price drops (good for cron)
python scripts/check-prices.py --threshold 5

# List tracked flights
python scripts/list-tracked.py
```

## How it works

- Queries Google Flights via the `fli` library
- Prices returned in user's local currency (auto-detected from IP)
- Price history persists in `~/.flightclaw/data/tracked.json` (binary) or `data/tracked.json` (source)
- Supports one-way and round trips, all cabin classes (economy to first)
- Filter by airline, price, duration, departure/arrival times, layover duration
- Multi-airport and date-range searches expand into all combinations
- Date search finds the cheapest day to fly across a range

## Install (OpenClaw)

```bash
npx skills add jackculpan/flightclaw
```
