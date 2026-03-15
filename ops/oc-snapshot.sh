#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/openclaw-host.sh"

C="${1:-$PROD_CONTAINER}"

echo "=== container ==="
ssh_host "
  docker ps --filter 'name=$C' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' || true
"

echo ""
echo "=== version ==="
ssh_host "
  docker exec $C openclaw --version 2>/dev/null || echo 'Unable to get version'
"

echo ""
echo "=== mounts ==="
ssh_host "
  docker inspect $C --format '{{range .Mounts}}{{println .Source \"->\" .Destination}}{{end}}' 2>/dev/null || echo 'Unable to get mounts'
"

echo ""
echo "=== extensions on disk ==="
ssh_host "
  docker exec $C sh -lc 'find /data/.openclaw/extensions -maxdepth 2 -mindepth 1 -type d 2>/dev/null | sort' || echo 'No extensions found'
"

echo ""
echo "=== configured plugin records ==="
ssh_host "
  docker exec $C sh -lc 'grep -n \"lossless-claw\\|instinct8\\|bmad\\|\"plugins\"\" /data/.openclaw/openclaw.json 2>/dev/null || echo \"No plugin records found\"'
"

echo ""
echo "=== openclaw status ==="
ssh_host "
  docker exec $C openclaw status --json 2>/dev/null || echo 'Unable to get status'
"

echo ""
echo "=== openclaw health ==="
ssh_host "
  docker exec $C openclaw health --json 2>/dev/null || echo 'Unable to get health'
"

echo ""
echo "=== recent sessions ==="
ssh_host "
  docker exec $C sh -lc 'find /data/.openclaw/agents -name sessions.json -print -exec ls -l {} \; 2>/dev/null || echo \"No sessions found\"'
"

echo ""
echo "=== recent logs ==="
ssh_host "
  docker logs --tail 120 $C 2>&1 || echo 'Unable to get logs'
"
