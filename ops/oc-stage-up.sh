#!/usr/bin/env bash
set -euo pipefail

# Bring staging container up on isolated loopback port 18790
# Usage: ./ops/oc-stage-up.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/openclaw-host.sh"

# Get the repo root (where compose file lives)
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.stage.yml"

echo "==> Bringing up staging container on ${HOST}"
echo "    Container: ${STAGE_CONTAINER}"
echo "    Port: 127.0.0.1:18790"
echo "    State dir: ${STAGE_STATE_DIR}"

# Ensure staging state directory exists
ssh_host "mkdir -p '${STAGE_STATE_DIR}'"

# Copy compose file to a temp location on VPS
TEMP_COMPOSE="/tmp/docker-compose.stage.$$.yml"
scp -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new \
  "$COMPOSE_FILE" "${USER_NAME}@${HOST}:${TEMP_COMPOSE}"

# Start staging container
ssh_host "
  export OPENCLAW_IMAGE='${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:v2026.3.13-1}'
  export OPENCLAW_STAGE_STATE_DIR='${STAGE_STATE_DIR}'
  export OPENCLAW_GATEWAY_TOKEN='${OPENCLAW_GATEWAY_TOKEN:-}'
  export CLAUDE_AI_SESSION_KEY='${CLAUDE_AI_SESSION_KEY:-}'
  export CLAUDE_WEB_SESSION_KEY='${CLAUDE_WEB_SESSION_KEY:-}'
  export CLAUDE_WEB_COOKIE='${CLAUDE_WEB_COOKIE:-}'
  export OPENAI_API_KEY='${OPENAI_API_KEY:-}'
  export ANTHROPIC_API_KEY='${ANTHROPIC_API_KEY:-}'
  docker compose -f '${TEMP_COMPOSE}' up -d
  rm -f '${TEMP_COMPOSE}'
"

echo "==> Staging container ${STAGE_CONTAINER} is up"
echo "    Access via SSH tunnel: ssh -L 18790:127.0.0.1:18790 ${USER_NAME}@${HOST}"
