#!/bin/bash
# cli-tools-setup.sh
# Modern CLI tools installation script
#
# Install overrides:
#   -y, --yes           Auto-accept all prompts
#   --reinstall         Force reinstall of already installed tools
#   --update            Same as --reinstall (update existing tools)

# Note: set -e removed to allow graceful error handling - script continues on failures

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
FAILED_TOOLS=()

log_installed() {
    INSTALLED_TOOLS+=("$1")
}

log_skipped() {
    SKIPPED_TOOLS+=("$1")
}

log_updated() {
    UPDATED_TOOLS+=("$1")
}

log_failed() {
    FAILED_TOOLS+=("$1")
    echo -e "  ${RED}✗ Failed: $1${NC}"
}

# ============================================
# Tool Installation Functions
# ============================================

# fzf - Fuzzy finder
install_fzf() {
    echo -e "\n${WHITE}[1/14] fzf${NC} ${GRAY}(fuzzy finder)${NC}"

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

        # Run install script non-interactively (enables shell integration)
        yes | "$HOME/.fzf/install" --all --no-update-rc 2>/dev/null || true

        show_realtime_footer

        if [ -f "$HOME/.fzf/bin/fzf" ]; then
            echo -e "  ${GREEN}✓ Installed successfully${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "fzf"
            else
                log_installed "fzf"
            fi
        else
            log_failed "fzf"
        fi
    else
        log_skipped "fzf"
    fi
}

# ripgrep - Fast code search
install_ripgrep() {
    echo -e "\n${WHITE}[2/14] ripgrep${NC} ${GRAY}(fast code search - rg)${NC}"

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
            log_failed "ripgrep"
        fi
    else
        log_skipped "ripgrep"
    fi
}

# fd - Modern find
install_fd() {
    echo -e "\n${WHITE}[3/14] fd${NC} ${GRAY}(modern find)${NC}"

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
            log_failed "fd"
        fi
    else
        log_skipped "fd"
    fi
}

# bat - cat with syntax highlighting
install_bat() {
    echo -e "\n${WHITE}[4/14] bat${NC} ${GRAY}(cat with syntax highlighting)${NC}"

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
            log_failed "bat"
        fi
    else
        log_skipped "bat"
    fi
}

# eza - Modern ls (exa replacement)
install_eza() {
    echo -e "\n${WHITE}[5/14] eza${NC} ${GRAY}(modern ls replacement)${NC}"

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
            log_failed "eza"
        fi
    else
        log_skipped "eza"
    fi
}

# zoxide - Smart cd
install_zoxide() {
    echo -e "\n${WHITE}[6/14] zoxide${NC} ${GRAY}(smart cd)${NC}"

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
            log_failed "zoxide"
        fi
    else
        log_skipped "zoxide"
    fi
}

# curl - Transfer data with URLs
install_curl() {
    echo -e "\n${WHITE}[7/14] curl${NC} ${GRAY}(transfer data with URLs)${NC}"

    local already_installed=false
    if command_exists curl; then
        local version=$(curl --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "curl (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "curl"; then
        echo -e "  ${CYAN}> Installing curl...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y curl
        show_realtime_footer

        if command_exists curl; then
            local version=$(curl --version 2>/dev/null | head -1)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "curl"
            else
                log_installed "curl"
            fi
        else
            log_failed "curl"
        fi
    else
        log_skipped "curl"
    fi
}

# tealdeer - Fast tldr client
install_tealdeer() {
    echo -e "\n${WHITE}[8/14] tealdeer${NC} ${GRAY}(fast tldr client)${NC}"

    local already_installed=false
    if command_exists tldr; then
        local version=$(tldr --version 2>/dev/null)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "tealdeer (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "tealdeer"; then
        echo -e "  ${CYAN}> Installing tealdeer...${NC}"
        show_realtime_header
        
        sudo apt-get update
        sudo apt-get install -y tealdeer
        
        # Ensure tldr command is available (tealdeer might install as tldr or tealdeer)
        if ! command_exists tldr && command_exists tealdeer; then
             # Create symlink if needed (though apt usually handles this via alternatives)
             mkdir -p "$HOME/.local/bin"
             ln -sf "$(which tealdeer)" "$HOME/.local/bin/tldr"
        fi
        
        # Initialize cache
        if command_exists tldr; then
             echo "Updating tldr cache..."
             tldr --update 2>/dev/null || true
        fi
        
        show_realtime_footer

        if command_exists tldr; then
            local version=$(tldr --version 2>/dev/null)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            echo -e "  ${CYAN}  Note: Use 'tldr command' for quick help${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "tealdeer"
            else
                log_installed "tealdeer"
            fi
        else
            log_failed "tealdeer"
        fi
    else
        log_skipped "tealdeer"
    fi
}

# cht.sh - Command-line cheat sheets
install_cht() {
    echo -e "\n${WHITE}[9/14] cht.sh${NC} ${GRAY}(command-line cheat sheets)${NC}"

    local already_installed=false
    if command_exists cht.sh || [ -f "$HOME/.local/bin/cht.sh" ]; then
        echo -e "  ${GREEN}✓ Already installed${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "cht.sh (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "cht.sh"; then
        echo -e "  ${CYAN}> Installing cht.sh...${NC}"
        show_realtime_header

        # Download and install cht.sh
        mkdir -p "$HOME/.local/bin"
        curl -s https://cht.sh/:cht.sh > "$HOME/.local/bin/cht.sh"
        chmod +x "$HOME/.local/bin/cht.sh"

        show_realtime_footer

        if [ -f "$HOME/.local/bin/cht.sh" ]; then
            echo -e "  ${GREEN}✓ Installed successfully${NC}"
            echo -e "  ${CYAN}  Note: Use 'cht.sh command' or 'cht.sh language/query'${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "cht.sh"
            else
                log_installed "cht.sh"
            fi
        else
            log_failed "cht.sh"
        fi
    else
        log_skipped "cht.sh"
    fi
}

# gh - GitHub CLI
install_gh() {
    echo -e "\n${WHITE}[10/14] gh${NC} ${GRAY}(GitHub CLI)${NC}"

    local already_installed=false
    if command_exists gh; then
        local version=$(gh --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "gh (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "gh"; then
        echo -e "  ${CYAN}> Installing GitHub CLI...${NC}"
        show_realtime_header

        # Install via official apt repository
        # Get the keyring if it doesn't exist
        if [ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        fi
        
        sudo apt-get update
        sudo apt-get install -y gh

        show_realtime_footer

        if command_exists gh; then
            local version=$(gh --version 2>/dev/null | head -1)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            echo -e "  ${CYAN}  Note: Run 'gh auth login' to authenticate${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "gh"
            else
                log_installed "gh"
            fi
        else
            log_failed "gh"
        fi
    else
        log_skipped "gh"
    fi
}

# tree - Directory listing as tree
install_tree() {
    echo -e "\n${WHITE}[11/14] tree${NC} ${GRAY}(directory listing as tree)${NC}"

    local already_installed=false
    if command_exists tree; then
        local version=$(tree --version 2>/dev/null | head -1)
        echo -e "  ${GREEN}✓ Already installed: $version${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "tree (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "tree"; then
        echo -e "  ${CYAN}> Installing tree...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y tree
        show_realtime_footer

        if command_exists tree; then
            local version=$(tree --version 2>/dev/null | head -1)
            echo -e "  ${GREEN}✓ Installed: $version${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "tree"
            else
                log_installed "tree"
            fi
        else
            log_failed "tree"
        fi
    else
        log_skipped "tree"
    fi
}

# neofetch - System info display
install_neofetch() {
    echo -e "\n${WHITE}[12/14] neofetch${NC} ${GRAY}(system info display)${NC}"

    local already_installed=false
    if command_exists neofetch; then
        echo -e "  ${GREEN}✓ Already installed${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "neofetch (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "neofetch"; then
        echo -e "  ${CYAN}> Installing neofetch...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y neofetch
        show_realtime_footer

        if command_exists neofetch; then
            echo -e "  ${GREEN}✓ Installed successfully${NC}"
            echo -e "  ${CYAN}  Note: Run 'neofetch' to display system info${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "neofetch"
            else
                log_installed "neofetch"
            fi
        else
            log_failed "neofetch"
        fi
    else
        log_skipped "neofetch"
    fi
}

# cmatrix - Matrix-style terminal animation
install_cmatrix() {
    echo -e "\n${WHITE}[13/14] cmatrix${NC} ${GRAY}(Matrix terminal animation)${NC}"

    local already_installed=false
    if command_exists cmatrix; then
        echo -e "  ${GREEN}✓ Already installed${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "cmatrix (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "cmatrix"; then
        echo -e "  ${CYAN}> Installing cmatrix...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y cmatrix
        show_realtime_footer

        if command_exists cmatrix; then
            echo -e "  ${GREEN}✓ Installed successfully${NC}"
            echo -e "  ${CYAN}  Note: Run 'cmatrix' for the Matrix effect (q to quit)${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "cmatrix"
            else
                log_installed "cmatrix"
            fi
        else
            log_failed "cmatrix"
        fi
    else
        log_skipped "cmatrix"
    fi
}

# chemtool - 2D chemical structure editor
install_chemtool() {
    echo -e "\n${WHITE}[14/14] chemtool${NC} ${GRAY}(2D chemical structure editor)${NC}"

    local already_installed=false
    if command_exists chemtool; then
        echo -e "  ${GREEN}✓ Already installed${NC}"
        already_installed=true

        if [ "$FORCE_REINSTALL" = false ]; then
            log_skipped "chemtool (already installed)"
            return 0
        fi
        echo -e "  ${CYAN}> Reinstall mode enabled${NC}"
    else
        echo -e "  ${YELLOW}○ Not installed${NC}"
    fi

    if prompt_install "chemtool"; then
        echo -e "  ${CYAN}> Installing chemtool...${NC}"
        show_realtime_header
        sudo apt-get update
        sudo apt-get install -y chemtool
        show_realtime_footer

        if command_exists chemtool; then
            echo -e "  ${GREEN}✓ Installed successfully${NC}"
            echo -e "  ${CYAN}  Note: Run 'chemtool' to draw chemical structures${NC}"
            if [ "$already_installed" = true ]; then
                log_updated "chemtool"
            else
                log_installed "chemtool"
            fi
        else
            log_failed "chemtool"
        fi
    else
        log_skipped "chemtool"
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
    echo -e "  ${WHITE}fzf${NC}       - Fuzzy finder (universal)"
    echo -e "  ${WHITE}ripgrep${NC}   - Fast code search (rg)"
    echo -e "  ${WHITE}fd${NC}        - Modern find"
    echo -e "  ${WHITE}bat${NC}       - cat with syntax highlight"
    echo -e "  ${WHITE}eza${NC}       - Modern ls (exa replacement)"
    echo -e "  ${WHITE}zoxide${NC}    - Smart cd"
    echo -e "  ${WHITE}curl${NC}      - Transfer data with URLs"
    echo -e "  ${WHITE}tealdeer${NC}  - Fast tldr client"
    echo -e "  ${WHITE}cht.sh${NC}    - Command-line cheat sheets"
    echo -e "  ${WHITE}gh${NC}        - GitHub CLI"
    echo -e "  ${WHITE}tree${NC}      - Directory listing as tree"
    echo -e "  ${WHITE}neofetch${NC}  - System info display"
    echo -e "  ${WHITE}cmatrix${NC}   - Matrix terminal animation"
    echo -e "  ${WHITE}chemtool${NC}  - 2D chemical structure editor"

    # Install each tool (continue on errors)
    install_fzf || true
    install_ripgrep || true
    install_fd || true
    install_bat || true
    install_eza || true
    install_zoxide || true
    install_curl || true
    install_tealdeer || true
    install_cht || true
    install_gh || true
    install_tree || true
    install_neofetch || true
    install_cmatrix || true
    install_chemtool || true

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

    if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
        echo -e "\n${RED}Failed:${NC}"
        for tool in "${FAILED_TOOLS[@]}"; do
            echo -e "  ${RED}✗${NC} $tool"
        done
        echo -e "\n${YELLOW}Some tools failed to install. You can retry with: ./cli-tools.sh --reinstall${NC}"
    fi

    echo ""
    echo -e "${YELLOW}Restart your terminal for all changes to take effect.${NC}"
    echo ""
    echo -e "${CYAN}Quick reference:${NC}"
    echo -e "  ${WHITE}fzf${NC}       Ctrl+R (history), Ctrl+T (files)"
    echo -e "  ${WHITE}rg${NC}        rg 'pattern' (fast grep)"
    echo -e "  ${WHITE}fd${NC}        fd 'pattern' (fast find)"
    echo -e "  ${WHITE}bat${NC}       bat file.txt (syntax highlight)"
    echo -e "  ${WHITE}eza${NC}       ll, la, lt (modern ls)"
    echo -e "  ${WHITE}z${NC}         z dirname (smart cd)"
    echo -e "  ${WHITE}curl${NC}      curl url (transfer data)"
    echo -e "  ${WHITE}tealdeer${NC}  tldr command (fast help)"
    echo -e "  ${WHITE}cht.sh${NC}    cht.sh language/query"
    echo -e "  ${WHITE}gh${NC}        gh repo create (github cli)"
    echo -e "  ${WHITE}tree${NC}      tree (directory structure)"
    echo -e "  ${WHITE}neofetch${NC}  neofetch (system info)"
    echo -e "  ${WHITE}cmatrix${NC}   cmatrix (Matrix effect, q to quit)"
    echo -e "  ${WHITE}chemtool${NC}  chemtool (draw chemicals)"
    echo ""
}

# Run the setup
main
