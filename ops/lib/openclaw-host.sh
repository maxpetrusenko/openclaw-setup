#!/usr/bin/env bash
set -euo pipefail

# Shared Hostinger OpenClaw ops helper
# Sourced by ops scripts to provide common SSH and container config

readonly HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
readonly USER_NAME="${OPENCLAW_VPS_USER:-root}"
readonly KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
readonly PROD_CONTAINER="${OPENCLAW_PROD_CONTAINER:-openclaw-ylld-openclaw-1}"
readonly STAGE_CONTAINER="${OPENCLAW_STAGE_CONTAINER:-openclaw-stage-1}"
readonly PROD_STATE_DIR="${OPENCLAW_PROD_STATE_DIR:-/docker/openclaw-ylld/data}"
readonly STAGE_STATE_DIR="${OPENCLAW_STAGE_STATE_DIR:-/docker/openclaw-stage/data}"

ssh_host() {
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "${USER_NAME}@${HOST}" "$@"
}
