#!/bin/bash
# ensure-daily.sh - Ensure today's and yesterday's memory files exist
# Usage: ./ensure-daily.sh [workspace_dir]

set -e

WORKSPACE_DIR="${1:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE_DIR/memory"

# Get dates
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)

# Template for new daily files
create_template() {
    local date=$1
    echo "# $date

## Log

"
}

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Ensure today's file
TODAY_FILE="$MEMORY_DIR/$TODAY.md"
if [ ! -f "$TODAY_FILE" ]; then
    create_template "$TODAY" > "$TODAY_FILE"
    echo "Created: $TODAY_FILE"
else
    echo "Exists: $TODAY_FILE"
fi

# Ensure yesterday's file
YEST_FILE="$MEMORY_DIR/$YESTERDAY.md"
if [ ! -f "$YEST_FILE" ]; then
    create_template "$YESTERDAY" > "$YEST_FILE"
    echo "Created: $YEST_FILE"
else
    echo "Exists: $YEST_FILE"
fi
