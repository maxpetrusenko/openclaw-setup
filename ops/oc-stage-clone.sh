#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/openclaw-host.sh"

FORCE="${OPENCLAW_STAGE_CLONE_FORCE:-}"

# Check if staging container already exists
if [[ "$FORCE" != "--force" ]]; then
  if ssh_host "docker ps --filter 'name=${STAGE_CONTAINER}' --format '{{.Names}}' | grep -q '${STAGE_CONTAINER}'" 2>/dev/null; then
    echo "Error: Staging container '${STAGE_CONTAINER}' is already running."
    echo "Use --force to proceed anyway (will stop staging container)."
    exit 1
  fi
fi

echo "Cloning prod state to staging..."
echo "  Prod: ${PROD_STATE_DIR}"
echo "  Stage: ${STAGE_STATE_DIR}"

# Verify prod state exists
echo "Checking prod state..."
ssh_host "test -d '${PROD_STATE_DIR}/.openclaw'" || {
  echo "Error: Prod state not found at ${PROD_STATE_DIR}/.openclaw"
  exit 1
}

# Stop staging container if running and --force is set
if [[ "$FORCE" == "--force" ]]; then
  if ssh_host "docker ps --filter 'name=${STAGE_CONTAINER}' --format '{{.Names}}' | grep -q '${STAGE_CONTAINER}'" 2>/dev/null; then
    echo "Stopping existing staging container..."
    ssh_host "docker stop '${STAGE_CONTAINER}' 2>/dev/null || true"
    ssh_host "docker rm '${STAGE_CONTAINER}' 2>/dev/null || true"
  fi
fi

# Create staging state directory
echo "Creating staging state directory..."
ssh_host "mkdir -p '${STAGE_STATE_DIR}'"

# Clean existing staging state
echo "Cleaning existing staging state..."
ssh_host "rm -rf '${STAGE_STATE_DIR}/.openclaw'"

# Copy prod state to staging (exclude transient SQLite files)
echo "Copying prod state to staging..."
ssh_host "rsync -a --delete --exclude='*.db-shm' --exclude='*.db-wal' --exclude='*.sock' '${PROD_STATE_DIR}/.openclaw/' '${STAGE_STATE_DIR}/.openclaw/'"

# Secure permissions
echo "Securing staging state permissions..."
ssh_host "chmod -R go-rwx '${STAGE_STATE_DIR}/.openclaw'" || true

echo "Clone complete. Staging state ready at ${STAGE_STATE_DIR}/.openclaw"
echo "Use ./ops/oc-stage-up.sh to start staging container."
