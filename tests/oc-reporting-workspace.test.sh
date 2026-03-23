#!/usr/bin/env bash
set -euo pipefail

# Test: openclaw-reporting-workspace.md contains required sections
# This is a documentation test - it verifies the blueprint doc exists and has key content

BLUEPRINT_DOC="docs/handbook/openclaw-reporting-workspace.md"

echo "Testing: $BLUEPRINT_DOC exists and contains required sections"

# Fail if doc doesn't exist
if [ ! -f "$BLUEPRINT_DOC" ]; then
  echo "FAIL: $BLUEPRINT_DOC does not exist"
  exit 1
fi

echo "PASS: $BLUEPRINT_DOC exists"

# Check for required content patterns
required_patterns=(
  "Lane 1"
  "Lane 2"
  "Lane 3"
  "reports/openclaw-daily"
  "overview.md"
  "local source-update"
  "Hostinger prod"
  "Hostinger staging"
  "daily report"
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -q "$pattern" "$BLUEPRINT_DOC"; then
    echo "FAIL: '$pattern' not found in $BLUEPRINT_DOC"
    exit 1
  fi
  echo "PASS: found '$pattern'"
done

echo ""
echo "All reporting workspace blueprint tests passed!"
