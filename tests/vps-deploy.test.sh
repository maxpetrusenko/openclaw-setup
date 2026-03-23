#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat >"$TMP_DIR/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$SSH_LOG"
exit 0
EOF

cat >"$TMP_DIR/scp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$SCP_LOG"
exit 0
EOF

chmod +x "$TMP_DIR/ssh" "$TMP_DIR/scp"

cat >"$TMP_DIR/.env.prod" <<'EOF'
OPENCLAW_GATEWAY_TOKEN=test-token
OPENCLAW_DATA_DIR=/docker/openclaw-ylld/data
OPENCLAW_LEGACY_CONTAINER=openclaw-ylld-openclaw-1
EOF

cat >"$TMP_DIR/docker-compose.prod.yml" <<'EOF'
services:
  openclaw-gateway:
    image: example
EOF

SSH_LOG="$TMP_DIR/ssh.log"
SCP_LOG="$TMP_DIR/scp.log"
export SSH_LOG SCP_LOG

PATH="$TMP_DIR:$PATH" \
  OPENCLAW_ENV_FILE="$TMP_DIR/.env.prod" \
  OPENCLAW_COMPOSE_FILE="$TMP_DIR/docker-compose.prod.yml" \
  "$ROOT_DIR/ops/vps-deploy.sh" deploy --profile tailnet >/tmp/vps-deploy.out 2>/tmp/vps-deploy.err || {
    cat /tmp/vps-deploy.out
    cat /tmp/vps-deploy.err
    exit 1
  }

if grep -F "log_info" "$SSH_LOG" >/dev/null; then
  echo "deploy script should not reference local shell functions inside remote ssh commands" >&2
  cat "$SSH_LOG" >&2
  exit 1
fi

grep -F "docker compose --profile tailnet pull" "$SSH_LOG"
grep -F "docker compose --profile tailnet up -d" "$SSH_LOG"
grep -F "openclaw health --json" "$SSH_LOG"
