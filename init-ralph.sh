#!/bin/bash
# Initialize Ralph in a target project
# Usage: ./init-ralph.sh [target_directory]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Ralph Initializer"
echo "================="
echo ""

# Get target directory
if [ -n "$1" ]; then
  TARGET_DIR="$1"
else
  read -p "Enter target project directory: " TARGET_DIR
fi

# Expand ~ to home directory
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# Create directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
  echo "Creating directory: $TARGET_DIR"
  mkdir -p "$TARGET_DIR"
fi

# Convert to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Check if it's the same directory as the script
if [ "$TARGET_DIR" = "$SCRIPT_DIR" ]; then
  echo -e "${RED}Error: Cannot initialize Ralph in its own directory${NC}"
  exit 1
fi

echo "Initializing Ralph in: $TARGET_DIR"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$TARGET_DIR/.claude/commands"

# Copy core files
echo "Copying core files..."

cp "$SCRIPT_DIR/ralph.sh" "$TARGET_DIR/ralph.sh"
chmod +x "$TARGET_DIR/ralph.sh"
echo "  - ralph.sh (executable)"

cp "$SCRIPT_DIR/prompt.md" "$TARGET_DIR/prompt.md"
echo "  - prompt.md"

cp "$SCRIPT_DIR/prd.json.example" "$TARGET_DIR/prd.json.example"
echo "  - prd.json.example"

# Copy Claude commands
echo "Copying Claude commands..."

cp "$SCRIPT_DIR/.claude/commands/prd.md" "$TARGET_DIR/.claude/commands/prd.md"
echo "  - .claude/commands/prd.md"

cp "$SCRIPT_DIR/.claude/commands/ralph.md" "$TARGET_DIR/.claude/commands/ralph.md"
echo "  - .claude/commands/ralph.md"

cp "$SCRIPT_DIR/.claude/commands/ralph-fix-inconsistencies.md" "$TARGET_DIR/.claude/commands/ralph-fix-inconsistencies.md"
echo "  - .claude/commands/ralph-fix-inconsistencies.md"

cp "$SCRIPT_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"
echo "  - .claude/settings.local.json"

# Update .gitignore
echo "Updating .gitignore..."

GITIGNORE_ENTRIES="# Ralph internal state files (not prd.json/progress.txt - those are tracked)
.last-branch
.prd.json.bak
.progress.txt.bak
archive/"

GITIGNORE_FILE="$TARGET_DIR/.gitignore"

if [ -f "$GITIGNORE_FILE" ]; then
  # Check if Ralph entries already exist
  if grep -q "# Ralph" "$GITIGNORE_FILE"; then
    echo "  - .gitignore already has Ralph entries, skipping"
  else
    echo "" >> "$GITIGNORE_FILE"
    echo "$GITIGNORE_ENTRIES" >> "$GITIGNORE_FILE"
    echo "  - Added Ralph entries to existing .gitignore"
  fi
else
  echo "$GITIGNORE_ENTRIES" > "$GITIGNORE_FILE"
  echo "  - Created .gitignore with Ralph entries"
fi

# Print success message
echo ""
echo -e "${GREEN}Ralph initialized in $TARGET_DIR!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Create a PRD (start Claude Code, then run the command):"
echo "     claude"
echo "     /prd describe what you want to build"
echo "  3. Convert PRD to Ralph format:"
echo "     /ralph tasks/prd-your-project.md"
echo "  4. Run Ralph:"
echo "     ./ralph.sh"
echo ""
