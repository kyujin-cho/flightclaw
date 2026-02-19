Test the flightclaw MCP server by verifying it starts without errors.

Steps:
1. Check if `.venv` exists and is activated. If not, suggest `python3 -m venv .venv && source .venv/bin/activate && pip install flights "mcp[cli]"`.
2. Run `timeout 5 python3 server.py 2>&1` — the server should start cleanly with no errors (exit code 124 from timeout is expected since it waits for STDIO input).
3. If `dist/flightclaw` exists, also test the scie binary: `timeout 5 ./dist/flightclaw 2>&1`.
4. Report whether each entry point started successfully.
