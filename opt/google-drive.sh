#!/bin/bash
# google-drive.sh
# Google Drive integration via GNOME Online Accounts
#
# Install overrides:
#   -y, --yes           Auto-accept all prompts
#   --open              Open settings panel after installation

# Note: set -e removed to allow graceful error handling - script continues on failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default flags
AUTO_YES=false
AUTO_OPEN=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --open)
            AUTO_OPEN=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: google-drive.sh [-y|--yes] [--open]"
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

package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

prompt_yes_no() {
    if [ "$AUTO_YES" = true ]; then
        echo -e "  ${CYAN}> Auto-accepting${NC}"
        return 0
    fi
    while true; do
        read -p "  > $1 (y/n): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        else
            echo -e "  ${RED}! Invalid input. Please enter 'y' or 'n'${NC}"
        fi
    done
}

# Track installation
INSTALLED=()
SKIPPED=()
FAILED=()

log_installed() {
    INSTALLED+=("$1")
}

log_skipped() {
    SKIPPED+=("$1")
}

log_failed() {
    FAILED+=("$1")
    echo -e "  ${RED}✗ Failed: $1${NC}"
}

# ============================================
# Header
# ============================================
echo -e "\n${CYAN}===================================${NC}"
echo -e "${WHITE}     Google Drive Integration${NC}"
echo -e "${CYAN}===================================${NC}"

# ============================================
# [1/3] Install gnome-control-center
# ============================================
echo -e "\n${WHITE}[1/3] Checking gnome-control-center${NC}"

if package_installed gnome-control-center; then
    echo -e "  ${GREEN}✓ Already installed${NC}"
    log_skipped "gnome-control-center (already installed)"
else
    echo -e "  ${YELLOW}○ Not installed${NC}"
    if prompt_yes_no "Install gnome-control-center?"; then
        echo -e "  ${CYAN}> Installing...${NC}"
        if sudo apt install -y gnome-control-center; then
            echo -e "  ${GREEN}✓ Installed gnome-control-center${NC}"
            log_installed "gnome-control-center"
        else
            log_failed "gnome-control-center"
        fi
    else
        log_skipped "gnome-control-center"
    fi
fi

# ============================================
# [2/3] Install gnome-online-accounts
# ============================================
echo -e "\n${WHITE}[2/3] Checking gnome-online-accounts${NC}"

if package_installed gnome-online-accounts; then
    echo -e "  ${GREEN}✓ Already installed${NC}"
    log_skipped "gnome-online-accounts (already installed)"
else
    echo -e "  ${YELLOW}○ Not installed${NC}"
    if prompt_yes_no "Install gnome-online-accounts?"; then
        echo -e "  ${CYAN}> Installing...${NC}"
        if sudo apt install -y gnome-online-accounts; then
            echo -e "  ${GREEN}✓ Installed gnome-online-accounts${NC}"
            log_installed "gnome-online-accounts"
        else
            log_failed "gnome-online-accounts"
        fi
    else
        log_skipped "gnome-online-accounts"
    fi
fi

# ============================================
# [3/3] Instructions & Open Settings
# ============================================
echo -e "\n${WHITE}[3/3] Setup Instructions${NC}"

echo -e "\n  ${CYAN}To connect Google Drive:${NC}"
echo -e "  ${GRAY}─────────────────────────────────────${NC}"
echo -e "  1. In the settings window, click ${WHITE}Google${NC}"
echo -e "  2. Sign in with your Google account"
echo -e "  3. Select desired access permissions"
echo -e "  4. Your Google Drive will appear in ${WHITE}Files${NC}"
echo -e "  ${GRAY}─────────────────────────────────────${NC}"

# Check if we should open settings
SHOULD_OPEN=false

if [ "$AUTO_OPEN" = true ]; then
    SHOULD_OPEN=true
elif [ ${#FAILED[@]} -eq 0 ]; then
    # Only offer to open if no failures
    if prompt_yes_no "Open Online Accounts settings now?"; then
        SHOULD_OPEN=true
    fi
fi

if [ "$SHOULD_OPEN" = true ]; then
    if command_exists gnome-control-center; then
        echo -e "\n  ${CYAN}> Opening settings...${NC}"
        gnome-control-center online-accounts &
        echo -e "  ${GREEN}✓ Settings panel opened${NC}"
    else
        echo -e "  ${YELLOW}! gnome-control-center not available${NC}"
    fi
fi

# ============================================
# Summary
# ============================================
echo -e "\n${CYAN}===================================${NC}"
echo -e "${WHITE}           Summary${NC}"
echo -e "${CYAN}===================================${NC}"

if [ ${#INSTALLED[@]} -gt 0 ]; then
    echo -e "\n${GREEN}Installed:${NC}"
    for item in "${INSTALLED[@]}"; do
        echo -e "  ${GREEN}✓${NC} $item"
    done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo -e "\n${GRAY}Skipped:${NC}"
    for item in "${SKIPPED[@]}"; do
        echo -e "  ${GRAY}○${NC} $item"
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed:${NC}"
    for item in "${FAILED[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
fi

echo -e "\n${GREEN}✔ Google Drive setup complete!${NC}\n"
