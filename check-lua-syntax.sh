#!/bin/bash

# BetterResting Lua Syntax Checker
# Checks all Lua files for syntax errors without running the game

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find Lua compiler
LUAC=""
if command -v luac &> /dev/null; then
    LUAC="luac"
elif command -v lua5.1 &> /dev/null; then
    LUAC="lua5.1 -c"
elif command -v lua5.2 &> /dev/null; then
    LUAC="lua5.2 -c"
elif command -v lua5.3 &> /dev/null; then
    LUAC="lua5.3 -c"
elif command -v lua5.4 &> /dev/null; then
    LUAC="lua5.4 -c"
fi

# Check if Lua is installed
if [ -z "$LUAC" ]; then
    echo -e "${YELLOW}Lua compiler (luac) not found!${NC}"
    echo ""
    echo "To install Lua on macOS, run:"
    echo "  brew install lua"
    echo ""
    echo "After installation, run this script again."
    exit 1
fi

echo -e "${GREEN}Checking Lua syntax...${NC}"
echo "Using: $LUAC"
echo ""

# Find all Lua files in the mod directory
MOD_DIR="mods/BetterResting/42/media/lua"
ERRORS=0
FILES_CHECKED=0

# Check if mod directory exists
if [ ! -d "$MOD_DIR" ]; then
    echo -e "${RED}Error: Mod directory not found: $MOD_DIR${NC}"
    exit 1
fi

# Find and check all .lua files
while IFS= read -r -d '' file; do
    FILES_CHECKED=$((FILES_CHECKED + 1))
    echo -n "Checking: $file ... "
    
    # Use luac to check syntax (outputs to /dev/null, only errors to stderr)
    if $LUAC -p "$file" 2>&1 | grep -q .; then
        echo -e "${RED}ERROR${NC}"
        $LUAC -p "$file" 2>&1 | sed 's/^/  /'
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}OK${NC}"
    fi
done < <(find "$MOD_DIR" -name "*.lua" -type f -print0)

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All $FILES_CHECKED file(s) passed syntax check!${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s) in $FILES_CHECKED file(s)${NC}"
    exit 1
fi

