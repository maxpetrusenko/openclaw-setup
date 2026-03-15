#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$SSH_LOG"
if [[ "$*" == *"/data/.openclaw/openclaw.json"* ]]; then
  printf 'test-token'
  exit 0
fi
exit 0
EOF

cat >"$TMP_DIR/open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$OPEN_LOG"
EOF

chmod +x "$TMP_DIR/ssh" "$TMP_DIR/open"

SSH_LOG="$TMP_DIR/ssh.log"
OPEN_LOG="$TMP_DIR/open.log"
export SSH_LOG OPEN_LOG

PATH="$TMP_DIR:$PATH" "$ROOT_DIR/ops/vps-openclaw.sh" tunnel >/tmp/vps-openclaw-tunnel-default.out 2>/tmp/vps-openclaw-tunnel-default.err || {
  cat /tmp/vps-openclaw-tunnel-default.out
  cat /tmp/vps-openclaw-tunnel-default.err
  exit 1
}

grep -F "Forwarding http://127.0.0.1:57439 -> 187.77.7.226:57439" /tmp/vps-openclaw-tunnel-default.out
grep -F "Tunnel ready at http://127.0.0.1:57439/?token=test-token" /tmp/vps-openclaw-tunnel-default.out
if grep -F "Opening http://127.0.0.1:57439/?token=test-token" /tmp/vps-openclaw-tunnel-default.out >/dev/null; then
  echo "unexpected browser open in default tunnel mode" >&2
  exit 1
fi
if [[ -s "$OPEN_LOG" ]]; then
  echo "unexpected open() call in default tunnel mode" >&2
  exit 1
fi

: >"$OPEN_LOG"

PATH="$TMP_DIR:$PATH" "$ROOT_DIR/ops/vps-openclaw.sh" tunnel --open >/tmp/vps-openclaw-tunnel-open.out 2>/tmp/vps-openclaw-tunnel-open.err || {
  cat /tmp/vps-openclaw-tunnel-open.out
  cat /tmp/vps-openclaw-tunnel-open.err
  exit 1
}

grep -F "Opening http://127.0.0.1:57439/?token=test-token" /tmp/vps-openclaw-tunnel-open.out
grep -F "/data/.openclaw/openclaw.json" "$SSH_LOG"
grep -F -- "-N -L 57439:127.0.0.1:57439 root@187.77.7.226" "$SSH_LOG"
grep -F "http://127.0.0.1:57439/?token=test-token" "$OPEN_LOG"
