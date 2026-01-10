#!/usr/bin/env bash
# cleanup-ghosts.sh - Remove redundant files after Go/Python integration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Ghost Files Cleanup${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

REMOVED=0
KEPT=0

# 1. Remove duplicate bin/ruw (keep backup)
if [ -f bin/ruw ] && [ -f bin/ruw.bash.bak ]; then
    SIZE=$(du -h bin/ruw | cut -f1)
    echo -e "${YELLOW}[1/2] Removing duplicate bin/ruw ($SIZE)${NC}"
    echo -e "  ${CYAN}→ Backup exists at bin/ruw.bash.bak${NC}"
    rm bin/ruw
    echo -e "  ${GREEN}✓ Removed${NC}\n"
    ((REMOVED++))
elif [ ! -f bin/ruw ]; then
    echo -e "${GREEN}[1/2] bin/ruw already removed${NC}\n"
    ((KEPT++))
else
    echo -e "${RED}[1/2] bin/ruw exists but no backup found - keeping it${NC}\n"
    ((KEPT++))
fi

# 2. Remove old installer (replaced by Makefile)
if [ -f bin/install-ruw.sh ]; then
    SIZE=$(du -h bin/install-ruw.sh | cut -f1)
    echo -e "${YELLOW}[2/2] Removing obsolete bin/install-ruw.sh ($SIZE)${NC}"
    echo -e "  ${CYAN}→ Replaced by: cd cmd/ruw && make install${NC}"
    rm bin/install-ruw.sh
    echo -e "  ${GREEN}✓ Removed${NC}\n"
    ((REMOVED++))
else
    echo -e "${GREEN}[2/2] bin/install-ruw.sh already removed${NC}\n"
    ((KEPT++))
fi

# 3. Create symlink from bin/ruw to wrapper
echo -e "${CYAN}[+] Creating convenience symlink...${NC}"
if [ ! -e bin/ruw ]; then
    cd bin
    ln -s ruw-wrapper.sh ruw
    cd ..
    echo -e "  ${GREEN}✓ Created: bin/ruw -> ruw-wrapper.sh${NC}\n"
else
    echo -e "  ${YELLOW}○ bin/ruw already exists (skipping)${NC}\n"
fi

# Summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Cleanup Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ $REMOVED -gt 0 ]; then
    echo -e "${GREEN}Removed: $REMOVED ghost file(s)${NC}"
fi

if [ $KEPT -gt 0 ]; then
    echo -e "${YELLOW}Already clean: $KEPT file(s)${NC}"
fi

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Current State${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${GREEN}Active Files:${NC}"
ls -lh bin/ | tail -n +2 | awk '{printf "  %s %s -> %s\n", $9, $5, $11}'

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Next Steps${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "1. ${CYAN}Build Go CLI:${NC}"
echo -e "   ${GREEN}cd cmd/ruw && make install${NC}\n"

echo -e "2. ${CYAN}Test tools:${NC}"
echo -e "   ${GREEN}ruw status${NC}"
echo -e "   ${GREEN}ruw doctor${NC}\n"

echo -e "3. ${CYAN}Verify integration:${NC}"
echo -e "   ${GREEN}./setup.sh${NC}\n"

echo -e "${GREEN}✓ Cleanup complete!${NC}\n"
