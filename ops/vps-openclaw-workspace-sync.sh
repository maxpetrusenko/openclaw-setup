#!/usr/bin/env bash
set -euo pipefail

# Sync OpenClaw workspace files out of (and optionally back into) the VPS container.
# This is the easiest way to "see what the clawdbot has" locally for editing.

HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
USER_NAME="${OPENCLAW_VPS_USER:-root}"
KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
CONTAINER_NAME="${OPENCLAW_CONTAINER:-openclaw-ylld-openclaw-1}"

LOCAL_DIR="${OPENCLAW_LOCAL_DIR:-$PWD/clawdbot}"

cmd="${1:-pull}"

ssh_base=(
  ssh
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  "${USER_NAME}@${HOST}"
)

case "$cmd" in
  pull)
    mkdir -p "$LOCAL_DIR"
    # Stream a tarball from inside the container to local disk.
    "${ssh_base[@]}" "sudo docker exec ${CONTAINER_NAME} sh -lc 'cd /data/.openclaw && tar -czf - workspace'" \
      | tar -xzf - -C "$LOCAL_DIR" --strip-components=1
    echo "Pulled to: $LOCAL_DIR"
    ;;
  push)
    if [[ ! -d "$LOCAL_DIR" ]]; then
      echo "Local dir not found: $LOCAL_DIR" >&2
      exit 1
    fi
    # Stream local workspace back into the container.
    tar -czf - -C "$LOCAL_DIR" . \
      | "${ssh_base[@]}" "sudo docker exec -i ${CONTAINER_NAME} sh -lc 'mkdir -p /data/.openclaw/workspace && tar -xzf - -C /data/.openclaw/workspace && chown -R node:node /data/.openclaw/workspace'"
    echo "Pushed from: $LOCAL_DIR"
    ;;
  push-paths)
    shift || true
    if [[ $# -lt 1 ]]; then
      echo "Usage: ./vps-openclaw-workspace-sync.sh push-paths <path> [path...]" >&2
      exit 2
    fi
    if [[ ! -d "$LOCAL_DIR" ]]; then
      echo "Local dir not found: $LOCAL_DIR" >&2
      exit 1
    fi
    # Push only selected paths to reduce blast radius (recommended when verifying changes).
    # Paths are relative to $LOCAL_DIR (workspace root).
    tar -czf - -C "$LOCAL_DIR" "$@" \
      | "${ssh_base[@]}" "sudo docker exec -i ${CONTAINER_NAME} sh -lc 'mkdir -p /data/.openclaw/workspace && tar -xzf - -C /data/.openclaw/workspace && chown -R node:node /data/.openclaw/workspace'"
    echo "Pushed paths from: $LOCAL_DIR"
    printf '  - %s\n' "$@"
    ;;
  where)
    echo "Remote (in container): /data/.openclaw/workspace"
    echo "Local: $LOCAL_DIR"
    ;;
  *)
    cat <<EOF
Usage: ./vps-openclaw-workspace-sync.sh [pull|push|where]
       ./vps-openclaw-workspace-sync.sh push-paths <path> [path...]

Defaults:
  VPS: ${USER_NAME}@${HOST} (key: ${KEY_PATH})
  Container: ${CONTAINER_NAME}
  Local dir: ${LOCAL_DIR}
EOF
    exit 1
    ;;
esac
