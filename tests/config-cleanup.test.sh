#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$SSH_LOG"

case "$*" in
  *"grep -Fx 'preferred-openclaw'"*)
    exit 0
    ;;
  *"docker ps --format '{{.Names}}'"*)
    printf '%s\n' "openclaw-ylld-openclaw-1"
    exit 0
    ;;
  *"openclaw doctor --non-interactive --fix"*)
    printf '%s\n' "doctor ok"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF

chmod +x "$TMP_DIR/ssh"

SSH_LOG="$TMP_DIR/ssh.log"
export SSH_LOG

PATH="$TMP_DIR:$PATH" OPENCLAW_CONTAINER="preferred-openclaw" \
  "$ROOT_DIR/scripts/config-cleanup.sh" >/tmp/config-cleanup.out 2>/tmp/config-cleanup.err || {
    cat /tmp/config-cleanup.out
    cat /tmp/config-cleanup.err
    exit 1
  }

if grep -F "docker ps --filter 'name=openclaw'" "$SSH_LOG" >/dev/null; then
  echo "cleanup script should not scan docker ps when OPENCLAW_CONTAINER is set" >&2
  cat "$SSH_LOG" >&2
  exit 1
fi

grep -F "sudo docker exec preferred-openclaw openclaw doctor --non-interactive --fix" "$SSH_LOG"
grep -F "sudo docker exec preferred-openclaw openclaw health --json" "$SSH_LOG"
