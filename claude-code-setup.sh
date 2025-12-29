#!/bin/bash
# claude-code-setup.sh
# Automated Claude Code installation with Node.js/npm dependency checking

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Helper function to prompt user
prompt_install() {
    read -p "  > Install $1? (Y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Helper function to prompt for reconfiguration
prompt_reconfigure() {
    read -p "  > $1 failed to connect. Reconfigure? (Y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check and install Node.js
install_nodejs() {
    echo -e "\n${NC}[1/4] Checking Node.js...${NC}"

    if command_exists node; then
        echo -e "  ${GREEN}+ Already installed: $(node --version)${NC}"
        return 0
    fi

    echo -e "  ${YELLOW}! Not installed${NC}"

    if prompt_install "Node.js (required for Claude Code)"; then
        echo -e "  ${CYAN}> Installing Node.js...${NC}"

        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs

        if command_exists node; then
            echo -e "  ${GREEN}+ Installed: $(node --version)${NC}"
            return 0
        else
            echo -e "  ${YELLOW}! Installed but not detected. You may need to restart your terminal.${NC}"
            return 1
        fi
    else
        echo -e "  ${RED}! Node.js is required for Claude Code. Setup cancelled.${NC}"
        return 1
    fi
}

# Check npm availability
check_npm() {
    echo -e "\n${NC}[2/4] Checking npm...${NC}"

    if command_exists npm; then
        echo -e "  ${GREEN}+ Already installed: v$(npm --version)${NC}"
        return 0
    fi

    echo -e "  ${RED}! npm not found. npm should come with Node.js installation.${NC}"
    echo -e "  ${YELLOW}! Please restart your terminal or reinstall Node.js.${NC}"
    return 1
}

# Install Claude Code
install_claude_code() {
    echo -e "\n${NC}[3/4] Checking Claude Code...${NC}"

    if command_exists claude; then
        local claude_version=$(claude --version 2>/dev/null)
        echo -e "  ${GREEN}+ Already installed: $claude_version${NC}"
        return 0
    fi

    echo -e "  ${YELLOW}! Not installed${NC}"

    if prompt_install "Claude Code"; then
        echo -e "  ${CYAN}> Installing Claude Code via npm...${NC}"

        sudo npm install -g @anthropic-ai/claude-code

        if [ $? -eq 0 ]; then
            if command_exists claude; then
                local claude_version=$(claude --version 2>/dev/null)
                echo -e "  ${GREEN}+ Installed successfully: $claude_version${NC}"
                return 0
            else
                echo -e "  ${YELLOW}! Installed but not detected. Restart your terminal to use 'claude'.${NC}"
                return 0
            fi
        else
            echo -e "  ${RED}! Installation failed${NC}"
            return 1
        fi
    else
        echo -e "  ${GRAY}> Skipped${NC}"
        return 1
    fi
}

# Get MCP server status
get_mcp_status() {
    local server_name="$1"
    local mcp_list=$(claude mcp list 2>/dev/null)

    if echo "$mcp_list" | grep -q "^$server_name:.*Connected"; then
        echo "connected"
    elif echo "$mcp_list" | grep -q "^$server_name:.*Failed"; then
        echo "failed"
    else
        echo "notfound"
    fi
}

# Configure MCP Servers
add_mcp_servers() {
    echo -e "\n${NC}[4/4] Configuring MCP Servers...${NC}"

    if ! command_exists claude; then
        echo -e "  ${RED}! Claude Code not found. Cannot configure MCP servers.${NC}"
        return 1
    fi

    local success=true

    # Add better-auth MCP server
    echo -e "  ${CYAN}> Checking better-auth MCP server...${NC}"
    local better_auth_status=$(get_mcp_status "better-auth")

    if [ "$better_auth_status" = "connected" ]; then
        echo -e "  ${GREEN}+ better-auth connected${NC}"
    elif [ "$better_auth_status" = "failed" ]; then
        if prompt_reconfigure "better-auth"; then
            claude mcp remove better-auth --scope user 2>/dev/null
            echo -e "  ${CYAN}> Reconfiguring better-auth...${NC}"
            claude mcp add better-auth --scope user --transport http https://mcp.chonkie.ai/better-auth/better-auth-builder/mcp
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}+ better-auth reconfigured${NC}"
            else
                echo -e "  ${RED}! Failed to reconfigure better-auth${NC}"
                success=false
            fi
        else
            echo -e "  ${YELLOW}! better-auth skipped (not connected)${NC}"
        fi
    else
        claude mcp add better-auth --scope user --transport http https://mcp.chonkie.ai/better-auth/better-auth-builder/mcp
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}+ better-auth added${NC}"
        else
            echo -e "  ${RED}! Failed to add better-auth${NC}"
            success=false
        fi
    fi

    # Add Sequential Thinking MCP server
    echo -e "  ${CYAN}> Checking sequential-thinking MCP server...${NC}"
    local seq_think_status=$(get_mcp_status "sequential-thinking")

    if [ "$seq_think_status" = "connected" ]; then
        echo -e "  ${GREEN}+ sequential-thinking connected${NC}"
    elif [ "$seq_think_status" = "failed" ]; then
        if prompt_reconfigure "sequential-thinking"; then
            claude mcp remove sequential-thinking --scope user 2>/dev/null
            echo -e "  ${CYAN}> Reconfiguring sequential-thinking...${NC}"
            claude mcp add sequential-thinking --scope user -- npx @modelcontextprotocol/server-sequential-thinking
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}+ sequential-thinking reconfigured${NC}"
            else
                echo -e "  ${RED}! Failed to reconfigure sequential-thinking${NC}"
                success=false
            fi
        else
            echo -e "  ${YELLOW}! sequential-thinking skipped (not connected)${NC}"
        fi
    else
        claude mcp add sequential-thinking --scope user -- npx @modelcontextprotocol/server-sequential-thinking
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}+ sequential-thinking added${NC}"
        else
            echo -e "  ${RED}! Failed to add sequential-thinking${NC}"
            success=false
        fi
    fi

    # Add GitHub MCP server
    echo -e "  ${CYAN}> Checking github MCP server...${NC}"
    local github_status=$(get_mcp_status "github")

    if [ "$github_status" = "connected" ]; then
        echo -e "  ${GREEN}+ github connected${NC}"
    elif [ "$github_status" = "failed" ] || [ "$github_status" = "notfound" ]; then
        local action="Configure"
        if [ "$github_status" = "failed" ]; then
            action="Reconfigure"
            if ! prompt_reconfigure "github"; then
                echo -e "  ${YELLOW}! github skipped (not connected)${NC}"
                return $success
            fi
            claude mcp remove github --scope user 2>/dev/null
        fi

        echo -e "  ${CYAN}> $action github MCP server...${NC}"
        read -p "  > Enter your GitHub Personal Access Token: " github_token

        if [ -z "$github_token" ]; then
            echo -e "  ${YELLOW}! No token provided, skipping github MCP server${NC}"
        else
            # Set GITHUB_TOKEN in .bashrc for persistence
            echo -e "  ${CYAN}> Setting GITHUB_TOKEN environment variable...${NC}"

            # Remove old GITHUB_TOKEN if exists
            sed -i '/^export GITHUB_TOKEN=/d' "$HOME/.bashrc"

            # Add new GITHUB_TOKEN
            echo "export GITHUB_TOKEN=\"$github_token\"" >> "$HOME/.bashrc"

            # Set for current session
            export GITHUB_TOKEN="$github_token"

            echo -e "  ${GREEN}+ GITHUB_TOKEN set${NC}"

            # Add GitHub MCP server
            echo -e "  ${CYAN}> Adding github MCP server...${NC}"
            claude mcp add github --scope user -- npx @modelcontextprotocol/server-github

            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}+ github added${NC}"
                echo -e "  ${YELLOW}! Restart terminal for GITHUB_TOKEN to take full effect${NC}"
            else
                echo -e "  ${RED}! Failed to add github${NC}"
                success=false
            fi
        fi
    fi

    return $success
}

# Main execution
main() {
    echo ""
    echo -e "${MAGENTA}==========================================${NC}"
    echo -e "${MAGENTA}    Claude Code Installation Script${NC}"
    echo -e "${MAGENTA}==========================================${NC}"
    echo ""

    # Step 1: Install Node.js
    if ! install_nodejs; then
        echo -e "\n${RED}=== Setup Failed ===${NC}"
        echo -e "${YELLOW}Please install Node.js manually and try again.${NC}"
        exit 1
    fi

    # Step 2: Verify npm
    if ! check_npm; then
        echo -e "\n${RED}=== Setup Failed ===${NC}"
        echo -e "${YELLOW}npm is required but not found.${NC}"
        exit 1
    fi

    # Step 3: Install Claude Code
    if ! install_claude_code; then
        echo -e "\n${RED}=== Setup Failed ===${NC}"
        echo -e "${YELLOW}Please check the errors above and try again.${NC}"
        exit 1
    fi

    # Step 4: Configure MCP Servers
    add_mcp_servers

    # Success summary
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}    Setup Completed Successfully!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${CYAN}You can now run 'claude' to start!${NC}"
    echo -e "${CYAN}MCP servers are configured in user scope (~/.claude.json)${NC}"
    echo ""
}

# Run the setup
main
