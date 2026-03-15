#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Track SSH calls
SSH_LOG="$TMP_DIR/ssh.log"
export SSH_LOG

# Mock SSH that records commands
cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$SSH_LOG"

# Simulate responses
if [[ "$*" == *"docker ps"*"grep"*"openclaw"* ]]; then
  # Simulate both prod and stage running
  echo "openclaw-gateway"
  echo "openclaw-stage-1"
elif [[ "$*" == *"docker rm"*"openclaw-stage-1"* ]]; then
  echo "openclaw-stage-1 removed"
elif [[ "$*" == *"rm -rf"*"openclaw-stage"* ]]; then
  echo "stage state purged"
elif [[ "$*" == *"docker ps"* ]]; then
  echo "openclaw-gateway"
fi
EOF

chmod +x "$TMP_DIR/ssh"

# Test 1: Default behavior stops staging but keeps state
: >"$SSH_LOG"
export OPENCLAW_SSH="$TMP_DIR/ssh"
PATH="$TMP_DIR:$PATH" "$ROOT_DIR/ops/oc-stage-down.sh" >/dev/null 2>&1 || {
  echo "FAIL: Script should exit cleanly"
  exit 1
}

# Assert: removes staging container
if ! grep -q "docker rm -f.*openclaw-stage-1" "$SSH_LOG"; then
  echo "FAIL: Should stop/remove staging container"
  exit 1
fi

# Assert: does NOT purge state
if grep -q "rm -rf.*openclaw-stage/data" "$SSH_LOG"; then
  echo "FAIL: Should NOT purge state without --purge flag"
  exit 1
fi

# Test 2: --purge flag removes both container and state
: >"$SSH_LOG"
export OPENCLAW_SSH="$TMP_DIR/ssh"
PATH="$TMP_DIR:$PATH" "$ROOT_DIR/ops/oc-stage-down.sh" --purge >/dev/null 2>&1 || {
  echo "FAIL: Purge mode should exit cleanly"
  exit 1
}

# Assert: removes staging container
if ! grep -q "docker rm -f.*openclaw-stage-1" "$SSH_LOG"; then
  echo "FAIL: Purge should remove staging container"
  exit 1
fi

# Assert: ALSO purges state
if ! grep -q "rm -rf.*openclaw-stage/data/.openclaw" "$SSH_LOG"; then
  echo "FAIL: Purge should remove staging state"
  exit 1
fi

# Test 3: Never touches prod
if grep -q "openclaw-gateway.*rm\|rm.*openclaw-prod" "$SSH_LOG"; then
  echo "FAIL: Should never touch prod container or state"
  exit 1
fi

echo "PASS: oc-stage-down.sh test suite"
