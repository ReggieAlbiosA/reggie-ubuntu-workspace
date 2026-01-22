#!/usr/bin/env bash
# claude-code-setup.sh
# Automated Claude Code installation with Node.js/npm dependency checking
#
# Flags:
#   -y, --yes    Auto-accept all prompts

# Note: using -uo pipefail instead of -Eeuo pipefail to allow graceful error handling
set -uo pipefail

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
# Argument Parsing
#######################################
AUTO_YES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

#######################################
# Globals
#######################################
EXPECTED_MCPS=("better-auth" "sequential-thinking" "github")

# Track installation status
INSTALLED_COMPONENTS=()
SKIPPED_COMPONENTS=()
FAILED_COMPONENTS=()

log_installed() {
    INSTALLED_COMPONENTS+=("$1")
}

log_skipped() {
    SKIPPED_COMPONENTS+=("$1")
}

log_failed() {
    FAILED_COMPONENTS+=("$1")
    echo -e "  ${RED}✗ Failed: $1${NC}"
}

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
    if [ "$AUTO_YES" = true ]; then
        echo -e "  ${CYAN}> Auto-accepting: $prompt${NC}"
        return 0
    fi
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
        log_installed "Node.js $(node --version)"
        return 0
    fi

    echo -e "  ${YELLOW}! Node.js not found${NC}"
    prompt_yes_no "Install Node.js (required)?" || {
        echo -e "  ${YELLOW}! Node.js skipped by user. Some features may not work.${NC}"
        log_skipped "Node.js (user declined)"
        return 1
    }

    echo -e "  ${CYAN}> Installing Node.js LTS...${NC}"
    if curl -fsSL https://deb.nodesource.com/setup_lts.x | as_root bash - && \
       as_root apt-get install -y nodejs; then
        if command_exists node; then
            echo -e "  ${GREEN}✓ Node.js installed: $(node --version)${NC}"
            log_installed "Node.js $(node --version)"
            return 0
        fi
    fi

    log_failed "Node.js (installation error)"
    return 1
}

check_npm() {
    echo -e "\n${NC}[2/4] Checking npm...${NC}"
    if command_exists npm; then
        echo -e "  ${GREEN}+ npm v$(npm --version)${NC}"
        log_installed "npm v$(npm --version)"
        return 0
    else
        log_failed "npm (not found - Node.js may have failed)"
        return 1
    fi
}

#######################################
# Claude Code
#######################################
install_claude_code() {
    echo -e "\n${NC}[3/4] Checking Claude Code...${NC}"

    if command_exists claude; then
        echo -e "  ${GREEN}+ Found $(claude --version 2>/dev/null)${NC}"
        log_installed "Claude Code"
        return 0
    fi

    echo -e "  ${YELLOW}! Claude Code not installed${NC}"
    prompt_yes_no "Install Claude Code?" || {
        log_skipped "Claude Code (user declined)"
        return 0
    }

    echo -e "  ${CYAN}> Installing Claude Code...${NC}"
    if as_root npm install -g @anthropic-ai/claude-code; then
        if command_exists claude; then
            echo -e "  ${GREEN}✓ Claude Code installed${NC}"
            log_installed "Claude Code"
            return 0
        fi
    fi

    log_failed "Claude Code (npm install error)"
    return 1
}

#######################################
# MCP Helpers
#######################################
get_mcp_status() {
    local name="$1"
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
show_summary() {
    echo -e "\n${MAGENTA}==========================================${NC}"
    echo -e "${MAGENTA}   Installation Summary${NC}"
    echo -e "${MAGENTA}==========================================${NC}"

    if [ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]; then
        echo -e "\n${GREEN}Installed/Found:${NC}"
        for item in "${INSTALLED_COMPONENTS[@]}"; do
            echo -e "  ${GREEN}✓${NC} $item"
        done
    fi

    if [ ${#SKIPPED_COMPONENTS[@]} -gt 0 ]; then
        echo -e "\n${GRAY}Skipped:${NC}"
        for item in "${SKIPPED_COMPONENTS[@]}"; do
            echo -e "  ${GRAY}○${NC} $item"
        done
    fi

    if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
        echo -e "\n${RED}Failed:${NC}"
        for item in "${FAILED_COMPONENTS[@]}"; do
            echo -e "  ${RED}✗${NC} $item"
        done
        echo -e "\n${YELLOW}Some components failed. You can retry by running this script again.${NC}"
    fi
}

main() {
    echo -e "${MAGENTA}==========================================${NC}"
    echo -e "${MAGENTA}   Claude Code Installation Script${NC}"
    echo -e "${MAGENTA}==========================================${NC}"
    echo -e "${CYAN}Scope: ${MCP_SCOPE}${NC}"

    local npm_available=false

    # Step 1: Node.js (required for npm)
    if install_nodejs; then
        # Step 2: Check npm (required for Claude Code)
        if check_npm; then
            npm_available=true
        fi
    else
        echo -e "  ${YELLOW}! Skipping npm check (Node.js not available)${NC}"
        log_skipped "npm check (Node.js required)"
    fi

    # Step 3: Claude Code (requires npm)
    if [ "$npm_available" = true ]; then
        install_claude_code || true
    else
        echo -e "\n${NC}[3/4] Checking Claude Code...${NC}"
        echo -e "  ${YELLOW}! Skipping Claude Code (npm not available)${NC}"
        log_skipped "Claude Code (npm required)"
    fi

    # Step 4: MCP Servers (requires Claude Code)
    if command_exists claude; then
        add_mcp_servers || true
    else
        echo -e "\n${NC}[4/4] Configuring MCP Servers...${NC}"
        echo -e "  ${YELLOW}! Skipping MCP servers (Claude Code not available)${NC}"
        log_skipped "MCP Servers (Claude Code required)"
    fi

    show_summary

    if command_exists claude; then
        echo -e "\n${GREEN}Setup complete!${NC}"
        echo -e "${CYAN}Run 'claude' to start.${NC}"
    else
        echo -e "\n${YELLOW}Setup finished with issues. Claude Code is not available.${NC}"
    fi
}

main
