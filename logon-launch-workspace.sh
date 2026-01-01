#!/bin/bash
# logon-launch-workspace.sh
# Sets up workspace launcher to run at login via XDG autostart
# Can be run standalone or called from setup.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="launch-workspace.sh"
SCRIPT_DEST="$HOME/Desktop/$SCRIPT_NAME"
AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/reggie-workspace.desktop"
GITHUB_RAW_URL="https://raw.githubusercontent.com/blueivy828/reggie-ubuntu-workspace/main"

echo -e "\n${CYAN}=== Setting up Workspace Launcher ===${NC}"

# --- Step 1: Install workspace launcher to Desktop ---
echo -e "\n${NC}[1/3] Installing workspace launcher${NC}"

# Determine script location (local or remote)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
LOCAL_LAUNCHER="$SCRIPT_DIR/$SCRIPT_NAME"

if [ -f "$LOCAL_LAUNCHER" ]; then
    # Local: copy the script
    cp "$LOCAL_LAUNCHER" "$SCRIPT_DEST"
    echo -e "  ${GREEN}+ Copied from local: $LOCAL_LAUNCHER${NC}"
else
    # Remote: download from GitHub
    LAUNCHER_URL="$GITHUB_RAW_URL/$SCRIPT_NAME"
    echo -e "  ${CYAN}> Downloading $SCRIPT_NAME...${NC}"
    curl -fsSL "$LAUNCHER_URL" -o "$SCRIPT_DEST"
    echo -e "  ${GREEN}+ Downloaded from GitHub${NC}"
fi

chmod +x "$SCRIPT_DEST"
echo -e "  ${GREEN}+ Installed to: $SCRIPT_DEST${NC}"

# --- Step 2: Clean up old autostart entries ---
echo -e "\n${NC}[2/3] Cleaning up old autostart entries${NC}"

# Create autostart directory if it doesn't exist
mkdir -p "$AUTOSTART_DIR"

# Remove old autostart entry if exists
if [ -f "$DESKTOP_FILE" ]; then
    rm "$DESKTOP_FILE"
    echo -e "  ${YELLOW}+ Removed old autostart entry${NC}"
else
    echo -e "  ${GRAY}  No old entry found${NC}"
fi

# --- Step 3: Create XDG autostart entry ---
echo -e "\n${NC}[3/3] Creating autostart entry${NC}"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Reggie Workspace
Comment=Opens browser tabs and apps on login
Exec=$SCRIPT_DEST
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo -e "  ${GREEN}+ Autostart entry created: $DESKTOP_FILE${NC}"

# --- Summary ---
echo -e "\n${CYAN}=== Workspace Launcher Setup Complete ===${NC}"
echo -e "  ${GREEN}+ Launcher installed to Desktop${NC}"
echo -e "  ${GREEN}+ Autostart configured (runs at login)${NC}"
echo -e "\n${YELLOW}To customize:${NC}"
echo -e "  Edit: $SCRIPT_DEST"
echo -e "  Add your own browser tabs and applications"
echo -e "\n${YELLOW}To test now:${NC}"
echo -e "  Run: $SCRIPT_DEST"
echo -e "\n${YELLOW}To disable autostart:${NC}"
echo -e "  Delete: $DESKTOP_FILE"
