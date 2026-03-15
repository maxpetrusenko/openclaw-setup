#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Export for subprocess access
export TMP_DIR

# Create mock directories
mkdir -p "$TMP_DIR/prod/data/.openclaw/extensions/test"
echo "test-config" > "$TMP_DIR/prod/data/.openclaw/config.json"

# Write the state file path to a temp file for the mock to read
echo "$TMP_DIR" > "$TMP_DIR/.state_path"

# Mock SSH that simulates clone operations
cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Read the state path
STATE_PATH="$(cat "$TMP_DIR/.state_path" 2>/dev/null || echo "$TMP_DIR")"

# Parse commands - check the full command string
cmd="$*"

# Docker ps check for staging container - return empty (no container running)
if echo "$cmd" | grep -q "docker ps.*filter.*name=openclaw-stage-1"; then
  # Return empty - no staging container running
  exit 1
fi

# Prod state exists check
if echo "$cmd" | grep -q "test -d.*/data/.openclaw"; then
  exit 0
fi

# Create stage dir
if echo "$cmd" | grep -q "mkdir -p.*/data"; then
  mkdir -p "$STATE_PATH/stage/data"
  exit 0
fi

# Clean stage dir
if echo "$cmd" | grep -q "rm -rf.*/data/.openclaw"; then
  rm -rf "$STATE_PATH/stage/data/.openclaw" 2>/dev/null || true
  exit 0
fi

# Copy prod state to stage (rsync or cp)
if echo "$cmd" | grep -q "rsync -a.*--exclude.*/data/.openclaw/.*/data/.openclaw"; then
  mkdir -p "$STATE_PATH/stage/data/.openclaw"
  rsync -a --exclude='*.db-shm' --exclude='*.db-wal' --exclude='*.sock' "$STATE_PATH/prod/data/.openclaw/" "$STATE_PATH/stage/data/.openclaw/"
  exit 0
fi

# Legacy cp -a support
if echo "$cmd" | grep -q "cp -a.*/data/.openclaw.*/data/.openclaw"; then
  cp -a "$STATE_PATH/prod/data/.openclaw" "$STATE_PATH/stage/data/.openclaw"
  exit 0
fi

# Set permissions
if echo "$cmd" | grep -q "chmod -R.*/data/.openclaw"; then
  chmod -R go-rwx "$STATE_PATH/stage/data/.openclaw" 2>/dev/null || true
  exit 0
fi

exit 0
EOF

chmod +x "$TMP_DIR/ssh"

# Override env vars for test
export OPENCLAW_PROD_STATE_DIR="$TMP_DIR/prod/data"
export OPENCLAW_STAGE_STATE_DIR="$TMP_DIR/stage/data"

# Run clone script
PATH="$TMP_DIR:$PATH" bash "$ROOT_DIR/ops/oc-stage-clone.sh" >/tmp/oc-stage-clone.out 2>/tmp/oc-stage-clone.err || {
  cat /tmp/oc-stage-clone.out
  cat /tmp/oc-stage-clone.err
  exit 1
}

# Verify expected operations were performed
output="$(cat /tmp/oc-stage-clone.out)"

# Should indicate cloning happened
if ! echo "$output" | grep -qi "clone\|copying\|creating"; then
  echo "FAIL: Expected clone indication in output" >&2
  echo "Output: $output" >&2
  exit 1
fi

# Verify prod path was never mutated
if echo "$output" | grep -qi "removing.*prod\|deleting.*prod\|rm.*prod"; then
  echo "FAIL: Prod state should not be mutated" >&2
  exit 1
fi

# Verify staging state was actually created
if [[ ! -d "$TMP_DIR/stage/data/.openclaw" ]]; then
  echo "FAIL: Staging state was not created" >&2
  echo "Contents of TMP_DIR:" >&2
  ls -la "$TMP_DIR" >&2
  exit 1
fi

# Verify staging has the copied data
if [[ ! -f "$TMP_DIR/stage/data/.openclaw/config.json" ]]; then
  echo "FAIL: Staging state does not have copied data" >&2
  ls -la "$TMP_DIR/stage/data/.openclaw" >&2
  exit 1
fi

# Verify prod is unchanged
if [[ ! -f "$TMP_DIR/prod/data/.openclaw/config.json" ]]; then
  echo "FAIL: Prod state was mutated" >&2
  exit 1
fi

echo "PASS: oc-stage-clone.sh clones prod to staging without mutating prod"
