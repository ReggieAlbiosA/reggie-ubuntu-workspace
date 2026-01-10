#!/usr/bin/env bash
# migrate.sh - Migrate to enhanced Go/Python tooling
# Run this after building the new tools

set -Eeuo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}  Migration to Enhanced Tools${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

MIGRATED=0
SKIPPED=0
FAILED=0

#######################################
# 1. Migrate Git Identities
#######################################
echo -e "${CYAN}[1/3] Git Identities${NC}"

OLD_IDENTITIES="$HOME/.git-identities"
NEW_IDENTITIES="$HOME/.git-identities.json"

if [[ -f "$OLD_IDENTITIES" ]] && [[ ! -f "$NEW_IDENTITIES" ]]; then
    echo -e "  ${YELLOW}○ Found old format: $OLD_IDENTITIES${NC}"

    if command -v python3 >/dev/null; then
        echo -e "  ${CYAN}> Migrating to JSON format...${NC}"

        python3 <<'PYTHON'
import json
import sys
from pathlib import Path

old_file = Path.home() / ".git-identities"
new_file = Path.home() / ".git-identities.json"

identities = []
try:
    with open(old_file) as f:
        for line in f:
            line = line.strip()
            if '|' in line:
                parts = line.split('|')
                if len(parts) >= 3:
                    identities.append({
                        "email": parts[0].strip(),
                        "name": parts[1].strip(),
                        "label": parts[2].strip()
                    })

    if identities:
        with open(new_file, 'w') as f:
            json.dump({"identities": identities}, f, indent=2)

        # Backup old file
        backup_file = Path.home() / ".git-identities.bak"
        old_file.rename(backup_file)

        print(f"✓ Migrated {len(identities)} identities")
        print(f"✓ JSON config: {new_file}")
        print(f"✓ Backup saved: {backup_file}")
        sys.exit(0)
    else:
        print("No identities found in old file")
        sys.exit(1)

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON

        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓ Git identities migrated${NC}"
            ((MIGRATED++))
        else
            echo -e "  ${RED}✗ Migration failed${NC}"
            ((FAILED++))
        fi
    else
        echo -e "  ${RED}✗ Python not available for migration${NC}"
        ((FAILED++))
    fi
elif [[ -f "$NEW_IDENTITIES" ]]; then
    echo -e "  ${GREEN}✓ Already using JSON format${NC}"
    ((SKIPPED++))
else
    echo -e "  ${YELLOW}○ No git identities to migrate${NC}"
    ((SKIPPED++))
fi

#######################################
# 2. Build Go CLI
#######################################
echo -e "\n${CYAN}[2/3] Go CLI (ruw)${NC}"

if command -v ruw >/dev/null; then
    echo -e "  ${GREEN}✓ ruw already installed${NC}"
    ruw version | head -1
    ((SKIPPED++))
else
    echo -e "  ${YELLOW}○ ruw not installed${NC}"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    RUW_DIR="$SCRIPT_DIR/../cmd/ruw"

    if [[ -d "$RUW_DIR" ]]; then
        if command -v go >/dev/null; then
            echo -e "  ${CYAN}> Building and installing ruw...${NC}"

            cd "$RUW_DIR"
            if make install; then
                echo -e "  ${GREEN}✓ ruw installed to ~/.local/bin${NC}"
                echo -e "  ${YELLOW}  Restart terminal or run: source ~/.bashrc${NC}"
                ((MIGRATED++))
            else
                echo -e "  ${RED}✗ Build failed${NC}"
                ((FAILED++))
            fi
            cd - > /dev/null
        else
            echo -e "  ${RED}✗ Go not installed${NC}"
            echo -e "  ${YELLOW}  Install with: sudo snap install go --classic${NC}"
            ((FAILED++))
        fi
    else
        echo -e "  ${RED}✗ cmd/ruw directory not found${NC}"
        ((FAILED++))
    fi
fi

#######################################
# 3. Setup Python Scripts
#######################################
echo -e "\n${CYAN}[3/3] Python Utilities${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -x "$SCRIPT_DIR/mcp_manager.py" ]]; then
    echo -e "  ${GREEN}✓ Python scripts already executable${NC}"
    ((SKIPPED++))
else
    echo -e "  ${CYAN}> Making Python scripts executable...${NC}"

    if chmod +x "$SCRIPT_DIR"/*.py; then
        echo -e "  ${GREEN}✓ Python scripts ready${NC}"
        ((MIGRATED++))
    else
        echo -e "  ${RED}✗ Failed to chmod${NC}"
        ((FAILED++))
    fi
fi

#######################################
# Summary
#######################################
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}  Migration Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [[ $MIGRATED -gt 0 ]]; then
    echo -e "${GREEN}Migrated: $MIGRATED${NC}"
fi

if [[ $SKIPPED -gt 0 ]]; then
    echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
fi

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi

#######################################
# Next Steps
#######################################
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}  Next Steps${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [[ $MIGRATED -gt 0 ]]; then
    echo -e "1. ${CYAN}Restart your terminal or run:${NC}"
    echo -e "   ${WHITE}source ~/.bashrc${NC}\n"
fi

echo -e "2. ${CYAN}Test the new tools:${NC}"
echo -e "   ${WHITE}ruw status${NC}"
echo -e "   ${WHITE}ruw doctor${NC}"
echo -e "   ${WHITE}./scripts/mcp_manager.py status${NC}"
echo -e "   ${WHITE}./scripts/git_identity.py status${NC}\n"

echo -e "3. ${CYAN}Read the guides:${NC}"
echo -e "   ${WHITE}cat INTEGRATION_GUIDE.md${NC}"
echo -e "   ${WHITE}cat QUICK_REFERENCE.md${NC}\n"

if [[ $FAILED -gt 0 ]]; then
    echo -e "${YELLOW}⚠  Some migrations failed. See errors above.${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ Migration complete!${NC}\n"
