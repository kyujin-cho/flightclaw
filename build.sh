#!/bin/bash
set -euo pipefail

PYTHON_VERSION="${PYTHON_VERSION:-3.13}"
PBS_RELEASE="${PBS_RELEASE:-20260211}"
OUTPUT_SUFFIX="${OUTPUT_SUFFIX:-}"
OUTPUT="dist/flightclaw${OUTPUT_SUFFIX:+-$OUTPUT_SUFFIX}"

echo "Building flightclaw scie binary (Python ${PYTHON_VERSION}, PBS ${PBS_RELEASE})..."

if ! command -v pex &>/dev/null; then
    echo "Error: pex not found. Install with: pip install pex"
    exit 1
fi

rm -f "$OUTPUT"
mkdir -p dist

PEX_ARGS=(
    flights
    "mcp[cli]"
    -M server
    -M search_utils@scripts
    -m server
    --scie lazy
    --scie-python-version "${PYTHON_VERSION}"
    --scie-pbs-release "${PBS_RELEASE}"
    --venv
    --venv-site-packages-copies
    -o "$OUTPUT"
)

if [[ -n "${SCIE_PLATFORM:-}" ]]; then
    PEX_ARGS+=(--scie-platform "$SCIE_PLATFORM")
fi

pex "${PEX_ARGS[@]}"

echo ""
echo "Built: ${OUTPUT} ($(du -h "$OUTPUT" | cut -f1))"
echo ""
echo "Run:   ./${OUTPUT}"
echo "Claude Code:  claude mcp add flightclaw -- \$(pwd)/${OUTPUT}"
