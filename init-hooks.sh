#!/bin/bash
# Initialize Git hooks for automatic setup

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Initializing Git hooks...${NC}"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Configure git to use .githooks directory
echo -e "${BLUE}Configuring Git to use .githooks directory...${NC}"
git config core.hooksPath .githooks

# Make hooks executable
chmod +x .githooks/post-checkout
chmod +x .githooks/post-merge

echo -e "${GREEN}✓ Git hooks initialized${NC}"
echo ""
echo -e "${BLUE}Hooks installed:${NC}"
echo "  • post-checkout: Runs setup after clone/checkout"
echo "  • post-merge: Updates binaries if versions.conf changed"
echo ""
echo -e "${BLUE}These hooks will run automatically on:${NC}"
echo "  • git clone"
echo "  • git checkout"
echo "  • git merge"
echo ""
echo "To disable hooks temporarily:"
echo "  git config --local core.hooksPath /dev/null"
echo ""
echo "To re-enable hooks:"
echo "  git config core.hooksPath .githooks"
