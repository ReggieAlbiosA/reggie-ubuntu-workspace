#!/usr/bin/env bash
# claude-code-setup.sh
# Automated Claude Code installation with Node.js/npm dependency checking

set -Eeuo pipefail

#######################################
# Colors
#######################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'

#######################################
# Globals
#######################################
EXPECTED_MCPS=("better-auth" "sequential-thinking" "github")

if [[ $EUID -eq 0 ]]; then
    MCP_SCOPE="system"
    BASHRC_PATH="/root/.bashrc"
else
    MCP_SCOPE="user"
    BASHRC_PATH="$HOME/.bashrc"
fi

#######################################
# Helpers
#######################################
as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

prompt_yes_no() {
    local prompt="$1"
    while true; do
        read -rp "  > $prompt (y/n): " reply
        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo -e "  ${RED}! Please answer y or n${NC}" ;;
        esac
    done
}

#######################################
# Node.js
#######################################
install_nodejs() {
    echo -e "\n${NC}[1/4] Checking Node.js...${NC}"

    if command_exists node; then
        echo -e "  ${GREEN}+ Found $(node --version)${NC}"
        return
    fi

    echo -e "  ${YELLOW}! Node.js not found${NC}"
    prompt_yes_no "Install Node.js (required)?" || {
        echo -e "${RED}Node.js required. Aborting.${NC}"
        exit 1
    }

    echo -e "  ${CYAN}> Installing Node.js LTS...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | as_root bash -
    as_root apt-get install -y nodejs
}

check_npm() {
    echo -e "\n${NC}[2/4] Checking npm...${NC}"
    command_exists npm || {
        echo -e "${RED}npm not found after Node.js install${NC}"
        exit 1
    }
    echo -e "  ${GREEN}+ npm v$(npm --version)${NC}"
}

#######################################
# Claude Code
#######################################
install_claude_code() {
    echo -e "\n${NC}[3/4] Checking Claude Code...${NC}"

    if command_exists claude; then
        echo -e "  ${GREEN}+ Found $(claude --version 2>/dev/null)${NC}"
        return
    fi

    echo -e "  ${YELLOW}! Claude Code not installed${NC}"
    prompt_yes_no "Install Claude Code?" || return

    echo -e "  ${CYAN}> Installing Claude Code...${NC}"
    as_root npm install -g @anthropic-ai/claude-code
}

#######################################
# MCP Helpers
#######################################

# Detect if Python MCP manager is available
use_python_mcp_manager() {
    [[ -x "$(dirname "${BASH_SOURCE[0]}")/../scripts/mcp_manager.py" ]] && command_exists python3
}

get_mcp_status() {
    local name="$1"

    # Use Python MCP manager if available (better parsing)
    if use_python_mcp_manager; then
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local status
        status=$(python3 "$script_dir/../scripts/mcp_manager.py" list 2>/dev/null | grep "^✓ $name:" && echo "connected" || \
                 python3 "$script_dir/../scripts/mcp_manager.py" list 2>/dev/null | grep "^✗ $name:" && echo "failed" || \
                 echo "missing")
        echo "$status"
        return
    fi

    # Fallback to bash parsing
    local output
    output="$(claude mcp list 2>/dev/null || true)"

    if grep -Fq "$name:" <<<"$output"; then
        if grep -Fq "Connected" <<<"$output"; then
            echo "connected"
        else
            echo "failed"
        fi
    else
        echo "missing"
    fi
}

#######################################
# GitHub MCP
#######################################
install_github_mcp() {
    echo -e "  ${CYAN}> Configuring GitHub MCP...${NC}"

    read -rsp "  > Enter GitHub Personal Access Token: " github_token
    echo

    [[ -z $github_token ]] && {
        echo -e "  ${YELLOW}! No token provided, skipping GitHub MCP${NC}"
        return 1
    }

    sed -i.bak '/^export GITHUB_TOKEN=/d' "$BASHRC_PATH"
    echo "export GITHUB_TOKEN=\"$github_token\"" >> "$BASHRC_PATH"
    export GITHUB_TOKEN="$github_token"

    claude mcp add github --scope "$MCP_SCOPE" -- \
        npx @modelcontextprotocol/server-github
}

#######################################
# MCP Setup
#######################################
add_mcp_servers() {
    echo -e "\n${NC}[4/4] Configuring MCP Servers (${MCP_SCOPE})...${NC}"

    # Try using Python MCP manager for better experience
    if use_python_mcp_manager; then
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        echo -e "${CYAN}Using enhanced Python MCP manager...${NC}"

        # Show status with Python tool
        python3 "$script_dir/../scripts/mcp_manager.py" status

        # Get missing servers
        local missing_output
        missing_output=$(python3 "$script_dir/../scripts/mcp_manager.py" list 2>/dev/null | grep "^○" | awk '{print $2}' | tr -d ':')

        if [[ -z "$missing_output" ]]; then
            echo -e "${GREEN}All MCP servers already configured.${NC}"
            return
        fi

        prompt_yes_no "Install missing MCP servers?" || return

        # Get GitHub token if needed
        local github_token=""
        if echo "$missing_output" | grep -q "github"; then
            read -rsp "  > Enter GitHub Personal Access Token (or Enter to skip): " github_token
            echo
        fi

        # Use Python to install (better structured)
        if [[ -n "$github_token" ]]; then
            python3 "$script_dir/../scripts/mcp_manager.py" install --scope "$MCP_SCOPE" --github-token "$github_token"
        else
            python3 "$script_dir/../scripts/mcp_manager.py" install --scope "$MCP_SCOPE"
        fi

        return
    fi

    # Fallback to bash implementation
    echo -e "${YELLOW}Note: Install Python for enhanced MCP management${NC}"

    local missing=()

    for mcp in "${EXPECTED_MCPS[@]}"; do
        [[ $(get_mcp_status "$mcp") == "connected" ]] || missing+=("$mcp")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo -e "${GREEN}All MCP servers already configured.${NC}"
        return
    fi

    echo -e "${YELLOW}${#missing[@]} MCP server(s) missing:${NC} ${missing[*]}"
    prompt_yes_no "Configure missing MCP servers?" || return

    for mcp in "${missing[@]}"; do
        echo -e "\n  ${CYAN}> Installing $mcp...${NC}"
        claude mcp remove "$mcp" --scope "$MCP_SCOPE" 2>/dev/null || true

        case "$mcp" in
            better-auth)
                claude mcp add better-auth --scope "$MCP_SCOPE" --transport http \
                    https://mcp.chonkie.ai/better-auth/better-auth-builder/mcp
                ;;
            sequential-thinking)
                claude mcp add sequential-thinking --scope "$MCP_SCOPE" -- \
                    npx @modelcontextprotocol/server-sequential-thinking
                ;;
            github)
                install_github_mcp
                ;;
        esac
    done
}

#######################################
# Main
#######################################
main() {
    echo -e "${MAGENTA}==========================================${NC}"
    echo -e "${MAGENTA}   Claude Code Installation Script${NC}"
    echo -e "${MAGENTA}==========================================${NC}"
    echo -e "${CYAN}Scope: ${MCP_SCOPE}${NC}"

    install_nodejs
    check_npm
    install_claude_code
    add_mcp_servers

    echo -e "\n${GREEN}Setup complete!${NC}"
    echo -e "${CYAN}Run 'claude' to start.${NC}"
}

main
