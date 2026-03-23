#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Mock SSH that outputs expected sections based on command
cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    *docker*ps*)
      echo "openclaw-ylld-openclaw-1   ghcr.io/maxpetrusenko/openclaw:latest   Up 2 hours"
      exit 0
      ;;
    *openclaw*--version*)
      echo "OpenClaw v0.1.0"
      exit 0
      ;;
    *docker*inspect*Mounts*)
      echo "/docker/openclaw-ylld/data -> /data"
      exit 0
      ;;
    *find*extensions*)
      echo "/data/.openclaw/extensions/lossless-claw"
      echo "/data/.openclaw/extensions/instinct8"
      echo "/data/.openclaw/extensions/bmad"
      exit 0
      ;;
    *grep*openclaw.json*)
      echo '"lossless-claw"'
      echo '"instinct8"'
      echo '"bmad"'
      exit 0
      ;;
    *openclaw*status*)
      echo '{"status":"healthy","agents":2}'
      exit 0
      ;;
    *openclaw*health*)
      echo '{"health":"ok"}'
      exit 0
      ;;
    *find*sessions.json*)
      echo "/data/.openclaw/agents/default/sessions.json"
      exit 0
      ;;
    *docker*logs*)
      echo "2026-03-15T10:00:00Z [INFO] Starting OpenClaw"
      echo "2026-03-15T10:01:00Z [INFO] Agent initialized"
      exit 0
      ;;
  esac
done
EOF

chmod +x "$TMP_DIR/ssh"

PATH="$TMP_DIR:$PATH" bash "$ROOT_DIR/ops/oc-snapshot.sh" >/tmp/oc-snapshot.out 2>/tmp/oc-snapshot.err || {
  cat /tmp/oc-snapshot.out
  cat /tmp/oc-snapshot.err
  exit 1
}

# Assert all required sections are present
output="$(cat /tmp/oc-snapshot.out)"

# Check section headers (=== section ===)
for section in "container" "version" "mounts" "extensions on disk" "configured plugin records" "openclaw status" "openclaw health" "recent sessions" "recent logs"; do
  if ! echo "$output" | grep -F "=== $section ===" >/dev/null 2>&1; then
    echo "FAIL: Missing section '$section' in output" >&2
    echo "Output was:" >&2
    echo "$output" >&2
    exit 1
  fi
done

# Check that actual data exists under sections
if ! echo "$output" | grep -q "openclaw-ylld-openclaw-1"; then
  echo "FAIL: Missing container data" >&2
  exit 1
fi

if ! echo "$output" | grep -q "OpenClaw v"; then
  echo "FAIL: Missing version data" >&2
  exit 1
fi

if ! echo "$output" | grep -q "/docker/openclaw-ylld/data"; then
  echo "FAIL: Missing mount data" >&2
  exit 1
fi

echo "PASS: oc-snapshot.sh outputs all required sections"
