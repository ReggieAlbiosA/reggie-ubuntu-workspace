#!/bin/bash
# cli-tools-setup.sh
# Modern CLI tools installation script
#
# Install overrides:
#   -y, --yes           Auto-accept all prompts
#   --reinstall         Force reinstall of already installed tools
#   --update            Same as --reinstall (update existing tools)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default flags
AUTO_YES=false
FORCE_REINSTALL=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --reinstall|--update)
            FORCE_REINSTALL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: cli-tools-setup.sh [-y|--yes] [--reinstall|--update]"
            exit 1
            ;;
    esac
done

# ============================================
# Helper Functions
# ============================================

command_exists() {
    command -v "$1" &> /dev/null
}

# Prompt for installation (respects AUTO_YES)
prompt_install() {
    if [ "$AUTO_YES" = true ]; then
        echo -e "  ${CYAN}> Auto-accepting${NC}"
        return 0
    fi
    while true; do
        read -p "  > Install $1? (y/n): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        else
            echo -e "  ${RED}! Invalid input. Please enter 'y' or 'n'${NC}"
        fi
    done
}

show_realtime_header() {
    echo -e "  ${YELLOW}┌─ Installation Output ─┐${NC}"
}

show_realtime_footer() {
    echo -e "  ${YELLOW}└───────────────────────┘${NC}"
}

# Track installation
INSTALLED_TOOLS=()
SKIPPED_TOOLS=()
UPDATED_TOOLS=()

log_installed() {
    INSTALLED_TOOLS+=("$1")
}

log_skipped() {
    SKIPPED_TOOLS+=("$1")
}

log_updated() {
    UPDATED_TOOLS+=("$1")
}

# ============================================
# Tool Installation Functions
# ============================================

# fzf - Fuzzy finder
install_fzf() {
    echo -e "\n${WHITE}[1/6] fzf${NC} ${GRAY}(fuzzy finder)${NC}"

    local already_installed=false
    if command_exists fzf; then
        local version=$(fzf --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "fzf (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "fzf"; then
        echo -e "  ${CYAN}> Installing fzf...${NC}"
        show_realtime_header

        # Install via git (recommended method for full features)
        if [ -d "$HOME/.fzf" ]; then
            echo "Updating existing fzf installation..."
            cd "$HOME/.fzf" && git pull
        else
            echo "Cloning fzf repository..."
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        fi

        # Run install script (enables shell integration)
        "$HOME/.fzf/install" --all --no-update-rc

        show_realtime_footer

        if [ -f "$HOME/.fzf/bin/fzf" ]; then
            echo -e "  ${GREEN}✓ Installed successfully${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "fzf"
            else
                log_installed "fzf"
            fi
        else
            echo -e "  ${RED}✗ Installation failed${NC}"
        fi
    else
        log_skipped "fzf"
    fi
}

# ripgrep - Fast code search
install_ripgrep() {
    echo -e "\n${WHITE}[2/6] ripgrep${NC} ${GRAY}(fast code search - rg)${NC}"

    local already_installed=false
    if command_exists rg; then
        local version=$(rg --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "ripgrep (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "ripgrep"; then
        echo -e "  ${CYAN}> Installing ripgrep...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y ripgrep
        show_realtime_footer

        if command_exists rg; then
            local version=$(rg --version 2>/dev/null | head -1)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "ripgrep"
            else
                log_installed "ripgrep"
            fi
        else
            echo -e "  ${RED}✗ Installation failed${NC}"
        fi
    else
        log_skipped "ripgrep"
    fi
}

# fd - Modern find
install_fd() {
    echo -e "\n${WHITE}[3/6] fd${NC} ${GRAY}(modern find)${NC}"

    local already_installed=false
    # On Ubuntu, the binary is called 'fdfind' due to name conflict
    if command_exists fd || command_exists fdfind; then
        local version=""
        if command_exists fd; then
            version=$(fd --version 2>/dev/null)
        else
            version=$(fdfind --version 2>/dev/null)
        fi
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "fd (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "fd"; then
        echo -e "  ${CYAN}> Installing fd-find...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y fd-find

        # Create symlink so 'fd' works (Ubuntu installs as 'fdfind')
        if command_exists fdfind && ! command_exists fd; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
            echo "Created symlink: fd -> fdfind"
        fi

        show_realtime_footer

        if command_exists fdfind; then
            local version=$(fdfind --version 2>/dev/null)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            echo -e "  ${CYAN}  Note: Use 'fd' or 'fdfind' command${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "fd"
            else
                log_installed "fd"
            fi
        else
            echo -e "  ${RED}✗ Installation failed${NC}"
        fi
    else
        log_skipped "fd"
    fi
}

# bat - cat with syntax highlighting
install_bat() {
    echo -e "\n${WHITE}[4/6] bat${NC} ${GRAY}(cat with syntax highlighting)${NC}"

    local already_installed=false
    # On Ubuntu, the binary is called 'batcat' due to name conflict
    if command_exists bat || command_exists batcat; then
        local version=""
        if command_exists bat; then
            version=$(bat --version 2>/dev/null)
        else
            version=$(batcat --version 2>/dev/null)
        fi
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "bat (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "bat"; then
        echo -e "  ${CYAN}> Installing bat...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y bat

        # Create symlink so 'bat' works (Ubuntu installs as 'batcat')
        if command_exists batcat && ! command_exists bat; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
            echo "Created symlink: bat -> batcat"
        fi

        show_realtime_footer

        if command_exists batcat; then
            local version=$(batcat --version 2>/dev/null)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            echo -e "  ${CYAN}  Note: Use 'bat' or 'batcat' command${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "bat"
            else
                log_installed "bat"
            fi
        else
            echo -e "  ${RED}✗ Installation failed${NC}"
        fi
    else
        log_skipped "bat"
    fi
}

# eza - Modern ls (exa replacement)
install_eza() {
    echo -e "\n${WHITE}[5/6] eza${NC} ${GRAY}(modern ls replacement)${NC}"

    local already_installed=false
    if command_exists eza; then
        local version=$(eza --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "eza (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "eza"; then
        echo -e "  ${CYAN}> Installing eza...${NC}"
        show_realtime_header

        # eza requires adding the GPG key and repository
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        sudo apt-get install -y eza

        show_realtime_footer

        if command_exists eza; then
            local version=$(eza --version 2>/dev/null | head -1)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "eza"
            else
                log_installed "eza"
            fi
        else
            echo -e "  ${RED}✗ Installation failed${NC}"
        fi
    else
        log_skipped "eza"
    fi
}

# zoxide - Smart cd
install_zoxide() {
    echo -e "\n${WHITE}[6/6] zoxide${NC} ${GRAY}(smart cd)${NC}"

    local already_installed=false
    if command_exists zoxide; then
        local version=$(zoxide --version 2>/dev/null)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "zoxide (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "zoxide"; then
        echo -e "  ${CYAN}> Installing zoxide...${NC}"
        show_realtime_header

        # Install via official install script
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

        # Add zoxide init to bashrc if not present
        BASHRC="$HOME/.bashrc"
        ZOXIDE_INIT='eval "$(zoxide init bash)"'

        if ! grep -q "zoxide init" "$BASHRC" 2>/dev/null; then
            echo "" >> "$BASHRC"
            echo "# zoxide - smart cd" >> "$BASHRC"
            echo "$ZOXIDE_INIT" >> "$BASHRC"
            echo "Added zoxide init to .bashrc"
        fi

        show_realtime_footer

        # Check if installed (might be in ~/.local/bin)
        if command_exists zoxide || [ -f "$HOME/.local/bin/zoxide" ]; then
            local version=$("$HOME/.local/bin/zoxide" --version 2>/dev/null || zoxide --version 2>/dev/null)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            echo -e "  ${CYAN}  Note: Use 'z' command after restart${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "zoxide"
            else
                log_installed "zoxide"
            fi
        else
            echo -e "  ${RED}✗ Installation failed${NC}"
        fi
    else
        log_skipped "zoxide"
    fi
}

# ============================================
# Shell Integration Setup
# ============================================
setup_shell_integration() {
    echo -e "\n${WHITE}Setting up shell integration...${NC}"

    BASHRC="$HOME/.bashrc"
    START_MARKER="# >>> MODERN-CLI-TOOLS >>>"
    END_MARKER="# <<< MODERN-CLI-TOOLS <<<"

    # Build aliases based on what's installed
    ALIASES_CONTENT="$START_MARKER
# Modern CLI tools aliases and configuration"

    # eza aliases (if installed)
    if command_exists eza; then
        ALIASES_CONTENT+="
# eza - modern ls
alias ls='eza'
alias ll='eza -la --icons --git'
alias la='eza -a --icons'
alias lt='eza --tree --icons --level=2'"
    fi

    # bat alias (if installed)
    if command_exists batcat && ! command_exists bat; then
        ALIASES_CONTENT+="
# bat - syntax highlighting
alias bat='batcat'"
    fi

    # fd alias (if installed)
    if command_exists fdfind && ! command_exists fd; then
        ALIASES_CONTENT+="
# fd - modern find
alias fd='fdfind'"
    fi

    ALIASES_CONTENT+="
$END_MARKER"

    # Update .bashrc
    if grep -q "$START_MARKER" "$BASHRC" 2>/dev/null; then
        # Remove old block and add new
        sed -i "/$START_MARKER/,/$END_MARKER/d" "$BASHRC"
    fi

    echo "" >> "$BASHRC"
    echo "$ALIASES_CONTENT" >> "$BASHRC"

    echo -e "  ${GREEN}✓ Shell integration configured${NC}"
}

# ============================================
# Main Execution
# ============================================

main() {
    echo ""
    echo -e "${MAGENTA}==========================================${NC}"
    echo -e "${WHITE}   Modern CLI Tools Installation${NC}"
    echo -e "${MAGENTA}==========================================${NC}"

    if [ "$AUTO_YES" = true ]; then
        echo -e "${GRAY}  Mode: Auto-accept all${NC}"
    fi
    if [ "$FORCE_REINSTALL" = true ]; then
        echo -e "${GRAY}  Mode: Force reinstall/update${NC}"
    fi

    echo -e "\n${CYAN}Tools to install:${NC}"
    echo -e "  ${WHITE}fzf${NC}      - Fuzzy finder (universal)"
    echo -e "  ${WHITE}ripgrep${NC}  - Fast code search (rg)"
    echo -e "  ${WHITE}fd${NC}       - Modern find"
    echo -e "  ${WHITE}bat${NC}      - cat with syntax highlight"
    echo -e "  ${WHITE}eza${NC}      - Modern ls (exa replacement)"
    echo -e "  ${WHITE}zoxide${NC}   - Smart cd"

    # Install each tool
    install_fzf
    install_ripgrep
    install_fd
    install_bat
    install_eza
    install_zoxide

    # Setup shell integration
    if [ ${#INSTALLED_TOOLS[@]} -gt 0 ] || [ ${#UPDATED_TOOLS[@]} -gt 0 ]; then
        setup_shell_integration
    fi

    # Summary
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${WHITE}   Installation Complete${NC}"
    echo -e "${GREEN}==========================================${NC}"

    if [ ${#INSTALLED_TOOLS[@]} -gt 0 ]; then
        echo -e "\n${GREEN}Installed:${NC}"
        for tool in "${INSTALLED_TOOLS[@]}"; do
            echo -e "  ${GREEN}✓${NC} $tool"
        done
    fi

    if [ ${#UPDATED_TOOLS[@]} -gt 0 ]; then
        echo -e "\n${CYAN}Updated:${NC}"
        for tool in "${UPDATED_TOOLS[@]}"; do
            echo -e "  ${CYAN}↑${NC} $tool"
        done
    fi

    if [ ${#SKIPPED_TOOLS[@]} -gt 0 ]; then
        echo -e "\n${GRAY}Skipped:${NC}"
        for tool in "${SKIPPED_TOOLS[@]}"; do
            echo -e "  ${GRAY}○${NC} $tool"
        done
    fi

    echo ""
    echo -e "${YELLOW}Restart your terminal for all changes to take effect.${NC}"
    echo ""
    echo -e "${CYAN}Quick reference:${NC}"
    echo -e "  ${WHITE}fzf${NC}      Ctrl+R (history), Ctrl+T (files)"
    echo -e "  ${WHITE}rg${NC}       rg 'pattern' (fast grep)"
    echo -e "  ${WHITE}fd${NC}       fd 'pattern' (fast find)"
    echo -e "  ${WHITE}bat${NC}      bat file.txt (syntax highlight)"
    echo -e "  ${WHITE}eza${NC}      ll, la, lt (modern ls)"
    echo -e "  ${WHITE}z${NC}        z dirname (smart cd)"
    echo ""
}

# Run the setup
main
