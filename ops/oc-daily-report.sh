#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/openclaw-host.sh"

REPORT_DATE="${OPENCLAW_REPORT_DATE:-$(date +%Y-%m-%d)}"

# Use REPORT_DIR if set (for testing), otherwise use ROOT_DIR
if [[ -n "${REPORT_DIR:-}" ]]; then
  BASE_REPORT_DIR="$REPORT_DIR"
else
  BASE_REPORT_DIR="$ROOT_DIR"
fi

# Always use openclaw-daily subdirectory
REPORT_PATH="$BASE_REPORT_DIR/openclaw-daily/$REPORT_DATE"
OVERVIEW="$REPORT_PATH/overview.md"

# Ensure report directory exists
mkdir -p "$REPORT_PATH"
mkdir -p "$REPORT_PATH/features"

# Collect data from VPS
collect_data() {
  ssh_host "
    docker exec $PROD_CONTAINER openclaw status --json 2>/dev/null || echo '{}'
    docker exec $PROD_CONTAINER sh -lc 'find /data/.openclaw/agents -name sessions.json -print -exec ls -l {} \;' 2>/dev/null || echo 'no sessions found'
    docker logs --tail 50 $PROD_CONTAINER 2>&1 || echo 'no logs available'
    docker exec $PROD_CONTAINER sh -lc 'find /data/.openclaw/extensions -maxdepth 1 -mindepth 1 -type d | sort' 2>/dev/null || echo 'no extensions'
    docker exec $PROD_CONTAINER sh -lc 'grep -n \"lossless-claw\\|instinct8\\|bmad\" /data/.openclaw/openclaw.json || true' 2>/dev/null || echo 'no plugin records'
  " 2>/dev/null || echo "error connecting to VPS"
}

# Generate overview
generate_overview() {
  local data="$1"
  local has_activity=0

  cat >"$OVERVIEW" <<EOF
# Daily Report: $REPORT_DATE

EOF

  # Status section
  cat >>"$OVERVIEW" <<EOF
## Status

EOF

  # Extract status from data
  if echo "$data" | grep -q '"status":"healthy"'; then
    echo "OpenClaw: Healthy" >>"$OVERVIEW"
  else
    echo "OpenClaw: Unknown or degraded" >>"$OVERVIEW"
  fi

  # Count extensions
  local ext_count
  ext_count=$(echo "$data" | grep -c "/data/.openclaw/extensions" 2>/dev/null) || ext_count=0
  echo "Extensions: $ext_count" >>"$OVERVIEW"
  echo "" >>"$OVERVIEW"

  # Work Done section
  cat >>"$OVERVIEW" <<EOF
## Work Done

EOF

  # Check for recent activity in logs
  local today_logs plugin_installs
  today_logs=$(echo "$data" | grep -c "$REPORT_DATE" 2>/dev/null) || today_logs=0
  plugin_installs=$(echo "$data" | grep -ic "plugin installed" 2>/dev/null) || plugin_installs=0

  if [[ "$plugin_installs" -gt 0 ]]; then
    echo "- $plugin_installs plugin(s) installed" >>"$OVERVIEW"
    has_activity=1
  fi

  if [[ "$today_logs" -gt 0 ]]; then
    echo "- $today_logs log entries today" >>"$OVERVIEW"
    has_activity=1
  fi

  if [[ "$has_activity" -eq 0 ]]; then
    echo "No meaningful activity." >>"$OVERVIEW"
  fi
  echo "" >>"$OVERVIEW"

  # Risks section
  cat >>"$OVERVIEW" <<EOF
## Risks

No critical risks identified.
EOF
  echo "" >>"$OVERVIEW"

  # Next section
  cat >>"$OVERVIEW" <<EOF
## Next

Routine monitoring.
EOF

  # Raw data appendix (truncated)
  cat >>"$OVERVIEW" <<EOF

---

## Raw Data

\`\`\`
$(echo "$data" | head -50)
\`\`\`
EOF
}

# Main
main() {
  DATA="$(collect_data)"
  generate_overview "$DATA"

  echo "Report generated: $OVERVIEW"
  ls -la "$REPORT_PATH"
}

main
