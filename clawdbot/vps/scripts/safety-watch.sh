#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Safety Watch
# - runs inside the OpenClaw container
# - sends Telegram alerts if something looks weird/unsafe
#
# Env:
# - ALERT_TELEGRAM_CHAT_ID (required, numeric)
# - DISK_WARN_PCT (default 80)
# - LOG_WARN_BYTES (default 1073741824, 1GiB)
# - ALERT_DRY_RUN=1 (print alerts to stdout, do not send)

ALERT_TELEGRAM_CHAT_ID="${ALERT_TELEGRAM_CHAT_ID:-}"
DISK_WARN_PCT="${DISK_WARN_PCT:-80}"
LOG_WARN_BYTES="${LOG_WARN_BYTES:-1073741824}"
ALERT_DRY_RUN="${ALERT_DRY_RUN:-0}"

if [[ -z "$ALERT_TELEGRAM_CHAT_ID" ]]; then
  echo "ALERT_TELEGRAM_CHAT_ID is required" >&2
  exit 2
fi

# Store watcher state OUTSIDE the workspace so the watcher doesn't trigger
# "workspace changed" alerts by updating its own state file.
state_dir="/data/.openclaw/vps-stats"
state_file="$state_dir/safety-watch.state"
mkdir -p "$state_dir"

now_epoch="$(date +%s)"

read_state() {
  local key="$1"
  if [[ -f "$state_file" ]]; then
    awk -F= -v k="$key" '$1==k{print substr($0, index($0,$2))}' "$state_file" 2>/dev/null | tail -n 1
  fi
}

write_state() {
  local key="$1"
  local value="$2"
  if [[ -f "$state_file" ]] && grep -q "^${key}=" "$state_file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$state_file"
  else
    echo "${key}=${value}" >>"$state_file"
  fi
}

cooldown_ok() {
  local key="$1"
  local cooldown="$2"
  local last
  last="$(read_state "$key" || true)"
  if [[ -z "${last:-}" ]]; then
    return 0
  fi
  (( now_epoch - last >= cooldown ))
}

send_alert() {
  local title="$1"
  local body="$2"
  local key="last_alert_${title//[^A-Za-z0-9]/_}"
  if ! cooldown_ok "$key" 10800; then
    return 0
  fi
  write_state "$key" "$now_epoch"
  if [[ "$ALERT_DRY_RUN" == "1" ]]; then
    echo "DRY_RUN alert: ${title} :: ${body}"
    return 0
  fi
  openclaw message send \
    --channel telegram \
    --target "$ALERT_TELEGRAM_CHAT_ID" \
    --message "OpenClaw Alert: ${title}\n${body}" >/dev/null
}

check_disk() {
  local pct
  pct="$(df -P /data | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
  if [[ -n "${pct:-}" ]] && (( pct >= DISK_WARN_PCT )); then
    send_alert "disk" "Disk usage is ${pct}% on /data (threshold ${DISK_WARN_PCT}%)."
  fi
}

check_logs() {
  local biggest_file biggest_bytes
  biggest_file=""
  biggest_bytes="0"
  if [[ -d /tmp/openclaw ]]; then
    while IFS= read -r f; do
      b="$(wc -c <"$f" 2>/dev/null || echo 0)"
      if [[ "$b" =~ ^[0-9]+$ ]] && (( b > biggest_bytes )); then
        biggest_bytes="$b"
        biggest_file="$f"
      fi
    done < <(find /tmp/openclaw -maxdepth 1 -type f -name 'openclaw-*.log' 2>/dev/null || true)
  fi

  if (( biggest_bytes >= LOG_WARN_BYTES )); then
    send_alert "logs" "Large log file: ${biggest_file} is ${biggest_bytes} bytes (threshold ${LOG_WARN_BYTES})."
  fi
}

check_security_audit() {
  local out
  # Lightweight: `openclaw status` includes a security audit summary.
  out="$(openclaw status 2>/dev/null || true)"
  if echo "$out" | grep -q "CRITICAL"; then
    send_alert "security" "Security audit reports CRITICAL findings. Run: openclaw security audit"
  fi
}

check_workspace_changed() {
  local h prev
  if find --help 2>/dev/null | grep -q -- "-printf"; then
    h="$(find /data/.openclaw/workspace -type f -not -path '*/.git/*' -printf '%P\t%s\t%T@\n' 2>/dev/null | sort | sha256sum | awk '{print $1}')"
  else
    h="$(find /data/.openclaw/workspace -type f -not -path '*/.git/*' -exec sh -lc 'printf \"%s\\t%s\\n\" \"$1\" \"$(wc -c <\"$1\" 2>/dev/null || echo 0)\"' sh {} \\; 2>/dev/null | sort | sha256sum | awk '{print $1}')"
  fi
  prev="$(read_state workspace_hash || true)"
  if [[ -n "${prev:-}" ]] && [[ "$h" != "$prev" ]]; then
    send_alert "workspace" "Workspace changed on VPS. Run on laptop: ./vps-openclaw-workspace-sync.sh pull"
  fi
  write_state workspace_hash "$h"
}

main() {
  check_disk
  check_logs
  check_security_audit
  check_workspace_changed
}

main
