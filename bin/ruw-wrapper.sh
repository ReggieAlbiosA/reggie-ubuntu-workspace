#!/usr/bin/env bash
# ruw-wrapper.sh - Smart wrapper for ruw CLI
# Uses Go version if available, falls back to bash

set -e

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Go version is in PATH
if command -v ruw >/dev/null 2>&1; then
    # Check if it's the Go binary (not this script recursively!)
    RUW_PATH=$(command -v ruw)
    if [[ "$RUW_PATH" != *"bin/ruw-wrapper"* ]] && [[ "$RUW_PATH" != "$(readlink -f "${BASH_SOURCE[0]}")" ]]; then
        # Use Go version (better!)
        exec ruw "$@"
    fi
fi

# Fallback to bash implementation
echo -e "${YELLOW}Note: Using legacy bash version${NC}" >&2
echo -e "${YELLOW}For better experience, build Go CLI: cd cmd/ruw && make install${NC}" >&2
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASH_RUW="$SCRIPT_DIR/ruw.bash.bak"

if [[ -f "$BASH_RUW" ]]; then
    exec bash "$BASH_RUW" "$@"
else
    echo "Error: Neither Go ruw nor bash fallback found" >&2
    echo "Please build Go CLI or restore bin/ruw.bash.bak" >&2
    exit 1
fi
