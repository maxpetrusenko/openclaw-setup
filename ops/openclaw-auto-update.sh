#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${OPENCLAW_CONTAINER:-openclaw-ylld-openclaw-1}"
IDLE_MINUTES="${OPENCLAW_UPDATE_IDLE_MINUTES:-60}"
TIMEOUT_SECONDS="${OPENCLAW_UPDATE_TIMEOUT_SECONDS:-1800}"
STATE_DIR="${OPENCLAW_UPDATE_STATE_DIR:-/var/lib/openclaw-auto-update}"
STATE_FILE="${STATE_DIR}/state.env"
MIRROR_STATE_PATH="${OPENCLAW_UPDATE_MIRROR_STATE_PATH:-/data/.openclaw/workspace/vps/stats/auto-update.state}"
ALERT_TELEGRAM_CHAT_ID="${ALERT_TELEGRAM_CHAT_ID:-}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: openclaw-auto-update.sh [--dry-run]

Checks for a newer OpenClaw package release inside the configured container.
If an update is available and the instance has been idle long enough, runs:

  openclaw update --yes

Environment:
  OPENCLAW_CONTAINER                Docker container name
  OPENCLAW_UPDATE_IDLE_MINUTES      Idle window before update is allowed
  OPENCLAW_UPDATE_TIMEOUT_SECONDS   Update timeout passed to OpenClaw
  OPENCLAW_UPDATE_STATE_DIR         State directory for decision logs
  OPENCLAW_UPDATE_MIRROR_STATE_PATH Container-visible mirror state path
  ALERT_TELEGRAM_CHAT_ID            Optional Telegram chat id for notifications
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

mkdir -p "$STATE_DIR"

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

write_state() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"
  if [[ -f "$STATE_FILE" ]]; then
    grep -v "^${key}=" "$STATE_FILE" >"$tmp" || true
  fi
  printf '%s=%s\n' "$key" "$value" >>"$tmp"
  mv "$tmp" "$STATE_FILE"
  sync_mirror_state
}

escape_note() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g'
}

docker_openclaw() {
  docker exec "$CONTAINER_NAME" sh -lc "$1"
}

sync_mirror_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    return 0
  fi
  docker exec "$CONTAINER_NAME" sh -lc "mkdir -p \"$(dirname "$MIRROR_STATE_PATH")\"" >/dev/null 2>&1 || return 0
  docker cp "$STATE_FILE" "${CONTAINER_NAME}:${MIRROR_STATE_PATH}" >/dev/null 2>&1 || true
}

notify() {
  local title="$1"
  local body="$2"
  log "$title :: $body"
  if [[ -z "$ALERT_TELEGRAM_CHAT_ID" ]]; then
    return 0
  fi
  local safe_title safe_body message
  safe_title="$(escape_note "$title")"
  safe_body="$(escape_note "$body")"
  message="OpenClaw auto-update: ${safe_title}
${safe_body}"
  printf '%s' "$message" | docker exec -i "$CONTAINER_NAME" sh -lc \
    "msg=\$(cat); openclaw message send --channel telegram --target '$ALERT_TELEGRAM_CHAT_ID' --message \"\$msg\"" \
    >/dev/null 2>&1 || log "notify failed"
}

json_eval() {
  local script="$1"
  python3 -c "$script"
}

current_version="$(docker_openclaw 'openclaw --version')"
update_json="$(docker_openclaw 'openclaw update status --json')"
status_json="$(docker_openclaw 'openclaw status --json')"

needs_container_restart="$(
  printf '%s\n' "$status_json" | json_eval 'import json,sys; gateway=json.load(sys.stdin).get("gatewayService", {}); print("1" if gateway.get("installed") is False else "0")'
)"

update_available="$(
  printf '%s\n' "$update_json" | json_eval 'import json,sys; print("1" if json.load(sys.stdin)["availability"]["available"] else "0")'
)"

latest_version="$(
  printf '%s\n' "$update_json" | json_eval 'import json,sys; data=json.load(sys.stdin); print(data["availability"].get("latestVersion") or data["update"].get("registry", {}).get("latestVersion") or "")'
)"

idle_report="$(
  printf '%s\n' "$status_json" | IDLE_MINUTES="$IDLE_MINUTES" json_eval '
import json, os, sys
idle_minutes = int(os.environ["IDLE_MINUTES"])
limit_ms = idle_minutes * 60 * 1000
recent = json.load(sys.stdin).get("sessions", {}).get("recent", [])
active = []
for row in recent:
    key = row.get("key") or ""
    age = row.get("age")
    if not isinstance(age, int) or age > limit_ms:
        continue
    if ":cron:" in key or key.startswith("cron:") or ":hook:" in key or key.startswith("hook:") or key.startswith("node-"):
        continue
    if row.get("systemSent") is True:
        continue
    active.append({
        "key": key,
        "ageMinutes": round(age / 60000, 1),
        "model": row.get("model"),
    })
print(json.dumps({
    "idle": len(active) == 0,
    "active": active,
}, separators=(",", ":")))
'
)"

is_idle="$(
  printf '%s\n' "$idle_report" | json_eval 'import json,sys; print("1" if json.load(sys.stdin)["idle"] else "0")'
)"

active_summary="$(
  printf '%s\n' "$idle_report" | json_eval '
import json,sys
active = json.load(sys.stdin)["active"]
if not active:
    print("")
else:
    print("; ".join(f"{row['key']} ({row['ageMinutes']}m)" for row in active))
'
)"

write_state last_checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
write_state last_seen_version "$current_version"
write_state last_seen_target "${latest_version:-none}"

if [[ "$update_available" != "1" ]]; then
  write_state last_decision "no_update"
  log "no update :: current=${current_version} target=${latest_version:-unknown}"
  exit 0
fi

if [[ "$is_idle" != "1" ]]; then
  write_state last_decision "busy"
  write_state last_skip_reason "active_sessions"
  notify "skipped" "update ${latest_version} available, active sessions within ${IDLE_MINUTES}m: ${active_summary}"
  exit 0
fi

if [[ "$DRY_RUN" == "1" ]]; then
  write_state last_decision "dry_run"
  log "dry run :: would update ${current_version} -> ${latest_version}"
  exit 0
fi

notify "starting" "updating ${current_version} -> ${latest_version}"

set +e
update_output="$(docker_openclaw "openclaw update --yes --timeout ${TIMEOUT_SECONDS}" 2>&1)"
update_code=$?
set -e

write_state last_update_attempt_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ "$update_code" -ne 0 ]]; then
  write_state last_decision "error"
  write_state last_error "$(escape_note "$update_output")"
  notify "failed" "$update_output"
  exit "$update_code"
fi

if [[ "$needs_container_restart" == "1" ]]; then
  log "restart :: restarting container ${CONTAINER_NAME} to pick up the updated package"
  docker restart "$CONTAINER_NAME" >/dev/null
  for _ in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" sh -lc 'openclaw --version' >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
fi

new_version="$(docker_openclaw 'openclaw --version' 2>/dev/null || true)"
post_update_json="$(docker_openclaw 'openclaw update status --json' 2>/dev/null || true)"
post_available="$(
  if [[ -n "$post_update_json" ]]; then
    printf '%s\n' "$post_update_json" | json_eval 'import json,sys; print("1" if json.load(sys.stdin)["availability"]["available"] else "0")'
  else
    printf 'unknown'
  fi
)"

write_state last_updated_version "${new_version:-unknown}"
write_state last_update_output "$(escape_note "$update_output")"

if [[ "${new_version:-}" == "$current_version" && "$post_available" == "1" ]]; then
  write_state last_decision "update_incomplete"
  notify \
    "incomplete" \
    "update command exited 0 but version stayed ${current_version} and update is still available"
  exit 1
fi

write_state last_decision "updated"
notify \
  "updated" \
  "before=${current_version} after=${new_version:-unknown} target=${latest_version:-unknown} remaining_update=${post_available}"
