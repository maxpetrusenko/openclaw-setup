#!/bin/bash
# capture-task.sh - Capture a task to memory files
# Usage: ./capture-task.sh "task text" [source] [channel]

set -e

TASK_TEXT="$1"
SOURCE="${2:-OpenClaw}"
CHANNEL="${3:-telegram}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE_DIR/memory"
ACTIVE_TASKS="$MEMORY_DIR/active-tasks.md"
TODAY=$(date +%Y-%m-%d)
DAILY_LOG="$MEMORY_DIR/$TODAY.md"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TIME=$(date +%H:%M)

if [ -z "$TASK_TEXT" ]; then
    echo "Usage: capture-task.sh \"task text\" [source] [channel]"
    exit 1
fi

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Ensure daily log exists
if [ ! -f "$DAILY_LOG" ]; then
    cat > "$DAILY_LOG" << EOF
# $TODAY

## Log

EOF
fi

# Create task block
TASK_BLOCK="\`\`\`text
Task: $TASK_TEXT
Owner: $SOURCE
Status: not_started
Success criteria:
Notes:
- Captured from $CHANNEL at $TIMESTAMP
Next action:
\`\`\`
"

# Add to active-tasks.md - append after ## Current section marker
# Using awk for safer multi-line insertion
awk -v block="$TASK_BLOCK" '
/^## Current$/ {
    print
    print ""
    printf "%s", block
    next
}
{ print }
' "$ACTIVE_TASKS" > "$ACTIVE_TASKS.tmp" && mv "$ACTIVE_TASKS.tmp" "$ACTIVE_TASKS"

# Add to daily log
LOG_ENTRY="- [$TIME] Task captured from $CHANNEL: $TASK_TEXT"
awk -v entry="$LOG_ENTRY" '
/^## Log$/ {
    print
    print entry
    next
}
{ print }
' "$DAILY_LOG" > "$DAILY_LOG.tmp" && mv "$DAILY_LOG.tmp" "$DAILY_LOG"

echo "✓ Captured: $TASK_TEXT"
echo "  → $ACTIVE_TASKS"
echo "  → $DAILY_LOG"
