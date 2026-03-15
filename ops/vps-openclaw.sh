#!/usr/bin/env bash
set -euo pipefail

HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
USER_NAME="${OPENCLAW_VPS_USER:-root}"
KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
CONTAINER_NAME="${OPENCLAW_CONTAINER:-openclaw-lera-openclaw-1}"
PROXY_PORT="${OPENCLAW_PROXY_PORT:-57439}"

cmd="${1:-shell}"
if [[ $# -gt 0 ]]; then
  shift
fi

ssh_base=(
  ssh
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  "${USER_NAME}@${HOST}"
)

get_proxy_token() {
  "${ssh_base[@]}" "sudo docker exec ${CONTAINER_NAME} sh -lc 'node -e \"const fs=require(\\\"fs\\\"); const j=JSON.parse(fs.readFileSync(\\\"/data/.openclaw/openclaw.json\\\", \\\"utf8\\\")); process.stdout.write(j.gateway?.auth?.token || \\\"\\\");\"'"
}

case "$cmd" in
  shell)
    # Open interactive shell inside OpenClaw container.
    "${ssh_base[@]}" "sudo docker exec -it ${CONTAINER_NAME} sh"
    ;;
  status)
    "${ssh_base[@]}" "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'; echo '---'; sudo docker exec ${CONTAINER_NAME} sh -lc 'openclaw status --json | sed -n \"1,80p\"'"
    ;;
  logs)
    "${ssh_base[@]}" "sudo docker logs --tail 200 ${CONTAINER_NAME}"
    ;;
  tunnel)
    local_port="$PROXY_PORT"
    should_open=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --open)
          should_open=1
          ;;
        --no-open)
          should_open=0
          ;;
        *)
          if [[ "$1" =~ ^[0-9]+$ ]]; then
            local_port="$1"
          else
            echo "Unknown tunnel arg: $1" >&2
            exit 1
          fi
          ;;
      esac
      shift
    done

    proxy_token="$(get_proxy_token || true)"
    local_url="http://127.0.0.1:${local_port}"
    if [[ -n "$proxy_token" ]]; then
      local_url="${local_url}/?token=${proxy_token}"
    fi

    echo "Forwarding http://127.0.0.1:${local_port} -> ${HOST}:${PROXY_PORT}"
    ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -N -L "${local_port}:127.0.0.1:${PROXY_PORT}" "${USER_NAME}@${HOST}" &
    tunnel_pid=$!
    trap 'kill "$tunnel_pid" 2>/dev/null || true' INT TERM EXIT

    if [[ "$should_open" -eq 1 ]]; then
      sleep 5
      echo "Opening ${local_url}"
      if command -v open >/dev/null 2>&1; then
        open "$local_url" >/dev/null 2>&1 || true
      else
        echo "$local_url"
      fi
    else
      echo "Tunnel ready at ${local_url}"
    fi

    wait "$tunnel_pid"
    trap - INT TERM EXIT
    ;;
  *)
    cat <<EOF
Usage: ./vps-openclaw.sh [shell|status|logs|tunnel [local_port] [--open]]

Examples:
  ./vps-openclaw.sh shell
  ./vps-openclaw.sh status
  ./vps-openclaw.sh logs
  ./vps-openclaw.sh tunnel
  ./vps-openclaw.sh tunnel --open
EOF
    exit 1
    ;;
esac
