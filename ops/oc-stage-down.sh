#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/openclaw-host.sh"

# Parse arguments
PURGE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge)
      PURGE=1
      ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--purge]

Stop and remove the staging container. Optionally purge staging state.

Options:
  --purge    Also delete staging state directory
  -h,--help  Show this help

Staging is safely recreated from prod state, so teardown is safe.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

echo "Stopping staging container: $STAGE_CONTAINER"
ssh_host "
  docker rm -f '$STAGE_CONTAINER' 2>/dev/null || true
"

if [[ "$PURGE" -eq 1 ]]; then
  echo "Purging staging state: $STAGE_STATE_DIR/.openclaw"
  ssh_host "rm -rf '$STAGE_STATE_DIR/.openclaw'"
fi

echo "Staging stopped. Prod remains untouched: $PROD_CONTAINER"
