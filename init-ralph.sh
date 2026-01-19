#!/bin/bash
# Initialize Ralph in a target project
# Usage: ./init-ralph.sh [target_directory] [unsecured-host] [unsecured-path]
#
# When unsecured-host is provided, generates a project-specific SSH deploy key,
# adds it to GitHub, transfers it to the unsecured system, and clones the repo there.

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

# Optional: remote deployment parameters
UNSECURED_HOST="$2"
UNSECURED_PATH="$3"

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

cp "$SCRIPT_DIR/prettify-ralph.sh" "$TARGET_DIR/prettify-ralph.sh"
chmod +x "$TARGET_DIR/prettify-ralph.sh"
echo "  - prettify-ralph.sh (executable)"

cp "$SCRIPT_DIR/prompt.md" "$TARGET_DIR/prompt.md"
echo "  - prompt.md"

cp "$SCRIPT_DIR/prd.json.example" "$TARGET_DIR/prd.json.example"
echo "  - prd.json.example"

# Copy Claude commands
echo "Copying Claude commands..."

cp "$SCRIPT_DIR/.claude/commands/ralph-prd.md" "$TARGET_DIR/.claude/commands/ralph-prd.md"
echo "  - .claude/commands/ralph-prd.md"

cp "$SCRIPT_DIR/.claude/commands/ralph-prd-to-json.md" "$TARGET_DIR/.claude/commands/ralph-prd-to-json.md"
echo "  - .claude/commands/ralph-prd-to-json.md"

cp "$SCRIPT_DIR/.claude/commands/ralph-fix-inconsistencies.md" "$TARGET_DIR/.claude/commands/ralph-fix-inconsistencies.md"
echo "  - .claude/commands/ralph-fix-inconsistencies.md"

cp "$SCRIPT_DIR/.claude/commands/ralph-git-init.md" "$TARGET_DIR/.claude/commands/ralph-git-init.md"
echo "  - .claude/commands/ralph-git-init.md"

cp "$SCRIPT_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/settings.local.json"
echo "  - .claude/settings.local.json"

# Update .gitignore
echo "Updating .gitignore..."

GITIGNORE_ENTRIES="# OS files
.DS_Store"

GITIGNORE_FILE="$TARGET_DIR/.gitignore"

if [ -f "$GITIGNORE_FILE" ]; then
  # Check if .DS_Store already ignored
  if grep -q ".DS_Store" "$GITIGNORE_FILE"; then
    echo "  - .gitignore already has .DS_Store entry, skipping"
  else
    echo "" >> "$GITIGNORE_FILE"
    echo "$GITIGNORE_ENTRIES" >> "$GITIGNORE_FILE"
    echo "  - Added .DS_Store to existing .gitignore"
  fi
else
  echo "$GITIGNORE_ENTRIES" > "$GITIGNORE_FILE"
  echo "  - Created .gitignore"
fi

# Remote deployment: generate deploy key and set up unsecured system
if [ -n "$UNSECURED_HOST" ]; then
  echo ""
  echo "Setting up remote deployment..."

  # Validate unsecured path is provided
  if [ -z "$UNSECURED_PATH" ]; then
    echo -e "${RED}Error: unsecured-path is required when unsecured-host is provided${NC}"
    echo "Usage: ./init-ralph.sh [target_directory] [unsecured-host] [unsecured-path]"
    exit 1
  fi

  # Get git remote URL (or ask for it)
  cd "$TARGET_DIR"
  if git remote get-url origin &>/dev/null; then
    REMOTE_URL=$(git remote get-url origin)
  else
    echo "No git remote 'origin' configured."
    read -p "Enter GitHub SSH URL (e.g., git@github.com:user/repo.git): " REMOTE_URL
    if [ -z "$REMOTE_URL" ]; then
      echo -e "${RED}Error: Remote URL is required for deploy key setup${NC}"
      exit 1
    fi
  fi

  REPO_NAME=$(basename "$TARGET_DIR")
  KEY_NAME="ralph-${REPO_NAME}"
  KEY_PATH="${TARGET_DIR}/${KEY_NAME}"

  # Generate keypair
  echo "Generating SSH deploy key..."
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "ralph-deploy-key-${REPO_NAME}"
  echo "  - Generated ${KEY_NAME} keypair"

  # Add to GitHub (if gh available) or show manual instructions
  if command -v gh &> /dev/null; then
    echo "Adding deploy key to GitHub..."
    gh repo deploy-key add "${KEY_PATH}.pub" --title "Ralph: ${REPO_NAME}" --allow-write
    echo "  - Deploy key added to GitHub"
  else
    echo ""
    echo -e "${YELLOW}========================================"
    echo "MANUAL STEP REQUIRED: Add this deploy key to GitHub"
    echo "========================================"
    echo ""
    echo "1. Go to your repository settings → Deploy keys"
    echo "2. Click 'Add deploy key'"
    echo "3. Title: Ralph: ${REPO_NAME}"
    echo "4. Paste this public key:"
    echo ""
    cat "${KEY_PATH}.pub"
    echo ""
    echo "5. Check 'Allow write access'"
    echo "6. Click 'Add key'"
    echo -e "========================================${NC}"
    echo ""
    read -p "Press Enter when done..."
  fi

  # Transfer private key to unsecured system
  echo "Transferring deploy key to ${UNSECURED_HOST}..."
  scp "$KEY_PATH" "${UNSECURED_HOST}:~/.ssh/${KEY_NAME}"
  ssh "$UNSECURED_HOST" "chmod 600 ~/.ssh/${KEY_NAME}"
  echo "  - Private key transferred to ~/.ssh/${KEY_NAME}"

  # Create project directory and copy Ralph files to remote
  REMOTE_PROJECT="${UNSECURED_PATH}/${REPO_NAME}"
  echo "Creating project directory on remote..."
  ssh "$UNSECURED_HOST" "mkdir -p ${REMOTE_PROJECT}/.claude/commands"

  echo "Copying Ralph files to remote..."
  scp "$TARGET_DIR/ralph.sh" "${UNSECURED_HOST}:${REMOTE_PROJECT}/ralph.sh"
  scp "$TARGET_DIR/prettify-ralph.sh" "${UNSECURED_HOST}:${REMOTE_PROJECT}/prettify-ralph.sh"
  scp "$TARGET_DIR/prompt.md" "${UNSECURED_HOST}:${REMOTE_PROJECT}/prompt.md"
  scp "$TARGET_DIR/.claude/commands/"*.md "${UNSECURED_HOST}:${REMOTE_PROJECT}/.claude/commands/"
  scp "$TARGET_DIR/.claude/settings.local.json" "${UNSECURED_HOST}:${REMOTE_PROJECT}/.claude/settings.local.json"
  ssh "$UNSECURED_HOST" "chmod +x ${REMOTE_PROJECT}/ralph.sh ${REMOTE_PROJECT}/prettify-ralph.sh"
  echo "  - Ralph files copied to remote"

  # Initialize git repo on remote with deploy key
  echo "Initializing git repository on remote..."
  ssh "$UNSECURED_HOST" "cd ${REMOTE_PROJECT} && \
    git init -b main && \
    git config core.sshCommand 'ssh -i ~/.ssh/${KEY_NAME} -o IdentitiesOnly=yes' && \
    git remote add origin ${REMOTE_URL} && \
    git add -A && \
    git commit -m 'Initial commit: Ralph setup

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>' && \
    git push -u origin main"
  echo "  - Git initialized and pushed to ${REMOTE_URL}"

  # Clean up local private key (keep public key for reference)
  rm "$KEY_PATH"
  echo "  - Local private key deleted (public key kept at ${KEY_PATH}.pub)"

  echo ""
  echo -e "${GREEN}Remote deployment configured!${NC}"
  echo ""
  echo "The unsecured system can now:"
  echo "  - Push/pull from ${REMOTE_URL}"
  echo "  - Access ONLY this repository (not your other repos)"
  echo ""
  echo "To run Ralph on the unsecured system:"
  echo "  ssh ${UNSECURED_HOST}"
  echo "  cd ${UNSECURED_PATH}/${REPO_NAME}"
  echo "  ./ralph.sh"
else
  # Print success message (local only)
  echo ""
  echo -e "${GREEN}Ralph initialized in $TARGET_DIR!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. cd $TARGET_DIR"
  echo "  2. Start Claude Code and create a PRD:"
  echo "     claude"
  echo "     /ralph-prd describe what you want to build"
  echo "  3. Convert PRD to Ralph format:"
  echo "     /ralph-prd-to-json PRD.md"
  echo "  4. Initialize git and push to GitHub:"
  echo "     /ralph-git-init"
  echo "  5. Run Ralph:"
  echo "     ./ralph.sh"
  echo ""
  echo "For remote deployment to an unsecured system, run:"
  echo "  ./init-ralph.sh $TARGET_DIR user@remote-host /remote/path"
fi
