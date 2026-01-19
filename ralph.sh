#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}

# Reset progress file with proper format
reset_progress_file() {
  local project_name=$(jq -r '.project // "Unknown"' "$PRD_FILE" 2>/dev/null || echo "Unknown")
  local story_count=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo "0")

  cat > "$PROGRESS_FILE" << EOF
# Ralph Progress Log - ${project_name}

## Codebase Patterns
<!-- Add reusable patterns discovered during implementation -->

## Session Start
Project: ${project_name}
Stories: ${story_count} total
Started: $(date)

---

EOF
}

# Time formatting helper
format_duration() {
  local seconds=$1
  local hours=$((seconds / 3600))
  local minutes=$(((seconds % 3600) / 60))
  local secs=$((seconds % 60))

  if [ $hours -gt 0 ]; then
    printf "%dh %dm %ds" $hours $minutes $secs
  elif [ $minutes -gt 0 ]; then
    printf "%dm %ds" $minutes $secs
  else
    printf "%ds" $secs
  fi
}

# Track start time
START_TIME=$SECONDS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  reset_progress_file
fi

echo "Starting Ralph - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  ITER_START=$SECONDS
  ELAPSED=$((SECONDS - START_TIME))

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS  [elapsed: $(format_duration $ELAPSED)]"
  echo "═══════════════════════════════════════════════════════"

  # Run claude with the ralph prompt
  OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | claude --dangerously-skip-permissions -p 2>&1 | tee /dev/stderr) || true

  ITER_DURATION=$((SECONDS - ITER_START))
  ELAPSED=$((SECONDS - START_TIME))

  # Check for completion signal (must be on its own line to avoid false positives
  # when the agent mentions the signal in reasoning)
  if echo "$OUTPUT" | grep -q "^<promise>COMPLETE</promise>$"; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Ralph completed all tasks!"
    echo "  Iterations: $i of $MAX_ITERATIONS"
    echo "  Total time: $(format_duration $ELAPSED)"
    echo "═══════════════════════════════════════════════════════"
    exit 0
  fi

  echo ""
  echo "  Iteration $i complete in $(format_duration $ITER_DURATION) [total: $(format_duration $ELAPSED)]"
  sleep 2
done

ELAPSED=$((SECONDS - START_TIME))
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Ralph reached max iterations ($MAX_ITERATIONS)"
echo "  Total time: $(format_duration $ELAPSED)"
echo "  Check $PROGRESS_FILE for status."
echo "═══════════════════════════════════════════════════════"

exit 1
