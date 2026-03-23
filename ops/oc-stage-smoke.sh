#!/usr/bin/env bash
set -euo pipefail

# Staging smoke verification: health, status, extensions, plugins, logs
# Usage: ./ops/oc-stage-smoke.sh [--prompt-smoke "reminder text"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/openclaw-host.sh"

# Optional prompt smoke reminder (non-empty = print reminder)
PROMPT_SMOKE="${OPENCLAW_STAGE_PROMPT_SMOKE:-}"

C="${1:-$STAGE_CONTAINER}"

echo "==> Staging smoke test for ${C} on ${HOST}"
echo

# Section: Container status
echo "=== Container Status ==="
ssh_host "docker ps --filter 'name=${C}' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
echo

# Section: OpenClaw version
echo "=== OpenClaw Version ==="
ssh_host "docker exec ${C} openclaw --version || echo 'Version check failed'"
echo

# Section: Health check
echo "=== Health Check ==="
ssh_host "docker exec ${C} openclaw health --json || echo 'Health check failed'"
echo

# Section: Status
echo "=== Status ==="
ssh_host "docker exec ${C} openclaw status --json || echo 'Status check failed'"
echo

# Section: Extension directories
echo "=== Extensions on Disk ==="
ssh_host "docker exec ${C} sh -lc 'find /home/node/.openclaw/extensions -maxdepth 2 -mindepth 1 -type d 2>/dev/null | sort' || echo 'No extensions found'"
echo

# Section: Plugin configuration
echo "=== Plugin Config (openclaw.json) ==="
ssh_host "docker exec ${C} sh -lc 'grep -n \"lossless-claw\\|instinct8\\|bmad\" /home/node/.openclaw/openclaw.json 2>/dev/null || echo \"No known plugins found\"'"
echo

# Section: Recent logs
echo "=== Recent Logs (last 60 lines) ==="
ssh_host "docker logs --tail 60 ${C} 2>&1 || echo 'Log fetch failed'"
echo

# Section: Prompt smoke reminder if set
if [[ -n "$PROMPT_SMOKE" ]]; then
  echo "=== Prompt Smoke Reminder ==="
  echo "$PROMPT_SMOKE"
  echo
fi

echo "==> Smoke complete"
