#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
REPORT_DIR="$TMP_DIR/reports"
trap 'rm -rf "$TMP_DIR"' EXIT

export REPORT_DIR

# Mock SSH that returns test data
cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Parse command to determine what to return
case "$*" in
  *"openclaw status"*"docker exec"*)
    # Return mock status JSON
    cat <<'STATUS'
{"status":"healthy","plugins":3,"sessions":1}
STATUS
    ;;
  *"find"*"sessions.json"*)
    # Return mock session timestamps
    echo "/data/.openclaw/agents/test/sessions.json"
    ;;
  *"docker logs"*"tail"*)
    # Return mock logs
    echo "[2026-03-15 10:00:00] INFO: Plugin installed: test-plugin"
    echo "[2026-03-15 11:00:00] INFO: Task completed"
    ;;
  *"find"*"extensions"*"type d"*)
    # Return mock extensions
    echo "/data/.openclaw/extensions/bmad-claw"
    echo "/data/.openclaw/extensions/instinct8"
    ;;
  *"grep"*"openclaw.json"*)
    # Return mock plugin records
    echo '1:  "bmad-claw": {'
    echo '2:    "enabled": true'
    ;;
  *)
    echo "mock ssh: $*" >&2
    ;;
esac
EOF

chmod +x "$TMP_DIR/ssh"

# Mock date to return fixed date
cat >"$TMP_DIR/date" <<'EOF'
#!/usr/bin/env bash
echo "2026-03-15"
EOF
chmod +x "$TMP_DIR/date"

PATH="$TMP_DIR:$PATH" "$ROOT_DIR/ops/oc-daily-report.sh" >/dev/null 2>&1 || {
  echo "FAIL: Script should exit cleanly"
  exit 1
}

# Assert: creates daily report directory
REPORT_PATH="$REPORT_DIR/openclaw-daily/2026-03-15"
if [[ ! -d "$REPORT_PATH" ]]; then
  echo "FAIL: Expected report directory at $REPORT_PATH"
  exit 1
fi

# Assert: creates overview.md
OVERVIEW="$REPORT_PATH/overview.md"
if [[ ! -f "$OVERVIEW" ]]; then
  echo "FAIL: Expected overview.md at $OVERVIEW"
  exit 1
fi

# Assert: overview contains required sections
if ! grep -q "^## Status" "$OVERVIEW"; then
  echo "FAIL: Overview missing Status section"
  exit 1
fi

if ! grep -q "^## Work Done" "$OVERVIEW"; then
  echo "FAIL: Overview missing Work Done section"
  exit 1
fi

if ! grep -q "^## Risks" "$OVERVIEW"; then
  echo "FAIL: Overview missing Risks section"
  exit 1
fi

if ! grep -q "^## Next" "$OVERVIEW"; then
  echo "FAIL: Overview missing Next section"
  exit 1
fi

# Assert: overview is short (less than 100 lines for typical day)
LINE_COUNT=$(wc -l < "$OVERVIEW")
if [[ "$LINE_COUNT" -gt 100 ]]; then
  echo "FAIL: Overview too long ($LINE_COUNT lines), should be under 100"
  exit 1
fi

# Test: "no meaningful activity" case
: >"$OVERVIEW"

cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  *"openclaw status"*)
    echo '{"status":"healthy","plugins":0,"sessions":0}'
    ;;
  *"docker logs"*)
    echo "[2026-03-15 00:00:00] INFO: No activity"
    ;;
  *)
    echo "mock ssh empty: $*" >&2
    ;;
esac
EOF

PATH="$TMP_DIR:$PATH" "$ROOT_DIR/ops/oc-daily-report.sh" >/dev/null 2>&1 || {
  echo "FAIL: Empty activity case should exit cleanly"
  exit 1
}

if ! grep -qi "no meaningful activity" "$OVERVIEW"; then
  echo "FAIL: Empty case should mention 'no meaningful activity'"
  exit 1
fi

echo "PASS: oc-daily-report.sh test suite"
