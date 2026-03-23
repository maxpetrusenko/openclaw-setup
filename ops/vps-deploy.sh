#!/usr/bin/env bash
set -euo pipefail

HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
USER_NAME="${OPENCLAW_VPS_USER:-root}"
KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
COMPOSE_FILE="${OPENCLAW_COMPOSE_FILE:-docker-compose.prod.yml}"
ENV_FILE="${OPENCLAW_ENV_FILE:-.env.prod}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-v2026.3.13-1}"

ssh_base=(
  ssh
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  "${USER_NAME}@${HOST}"
)

scp_base=(
  scp
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cmd="${1:-help}"
shift || true

compose_profile=""
if [[ "$cmd" == "deploy" || "$cmd" == "redeploy" || "$cmd" == "update" ]]; then
  while (($# > 0)); do
    case "$1" in
      --profile)
        compose_profile="${2:-}"
        if [[ -z "$compose_profile" ]]; then
          log_error "--profile requires a value"
          exit 1
        fi
        shift 2
        ;;
      *)
        log_error "Unknown argument for $cmd: $1"
        exit 1
        ;;
    esac
  done
fi

compose_cmd="docker compose"
if [[ -n "$compose_profile" ]]; then
  compose_cmd="$compose_cmd --profile $compose_profile"
fi

case "$cmd" in
  setup)
    log_info "Setting up OpenClaw host on $HOST..."
    "${ssh_base[@]}" "
      set -euo pipefail
      if ! command -v docker >/dev/null 2>&1; then
        curl -fsSL https://get.docker.com | sh
        usermod -aG docker root || true
      fi
      if ! docker compose version >/dev/null 2>&1; then
        apt-get update
        apt-get install -y docker-compose-plugin
      fi
      if ! command -v tailscale >/dev/null 2>&1; then
        curl -fsSL https://tailscale.com/install.sh | sh
      fi
      mkdir -p /opt/openclaw
      echo 'VPS ready for deployment'
    "
    ;;

  deploy)
    if [[ ! -f "$ENV_FILE" ]]; then
      log_error "$ENV_FILE not found. Copy .env.prod.example and configure it first."
      exit 1
    fi
    if grep -q "your-random-token-here" "$ENV_FILE"; then
      log_error "OPENCLAW_GATEWAY_TOKEN still has the placeholder value in $ENV_FILE"
      exit 1
    fi

    log_info "Deploying OpenClaw $OPENCLAW_VERSION to $HOST..."
    "${scp_base[@]}" "$COMPOSE_FILE" "${USER_NAME}@${HOST}:/opt/openclaw/docker-compose.yml"
    "${scp_base[@]}" "$ENV_FILE" "${USER_NAME}@${HOST}:/opt/openclaw/.env"

    "${ssh_base[@]}" "
      set -euo pipefail
      cd /opt/openclaw
      set -a
      . ./.env
      set +a

      echo 'Pulling image...'
      $compose_cmd pull

      if [[ -n \"\${OPENCLAW_LEGACY_CONTAINER:-}\" ]] && docker ps --format '{{.Names}}' | grep -Fx \"\${OPENCLAW_LEGACY_CONTAINER}\" >/dev/null 2>&1; then
        echo \"Stopping legacy container: \${OPENCLAW_LEGACY_CONTAINER}\"
        docker stop \"\${OPENCLAW_LEGACY_CONTAINER}\" >/dev/null
      fi

      $compose_cmd down 2>/dev/null || true
      $compose_cmd up -d

      echo 'Waiting for gateway health...'
      for i in {1..30}; do
        if $compose_cmd exec -T openclaw-gateway openclaw health --json >/dev/null 2>&1; then
          echo 'Gateway is healthy!'
          break
        fi
        if [[ \$i -eq 30 ]]; then
          echo 'Gateway not healthy after 60s'
          exit 1
        fi
        sleep 2
      done

      echo ''
      echo 'Deployment complete!'
      $compose_cmd ps
    "

    log_info "Access methods:"
    log_info "  SSH tunnel: $0 tunnel"
    log_info "  Host Tailscale status: $0 tailscale-status"
    ;;

  redeploy)
    if [[ ! -f "$ENV_FILE" ]]; then
      log_error "$ENV_FILE not found."
      exit 1
    fi
    log_info "Redeploying to $HOST..."
    "${scp_base[@]}" "$ENV_FILE" "${USER_NAME}@${HOST}:/opt/openclaw/.env"
    "${ssh_base[@]}" "cd /opt/openclaw && $compose_cmd up -d"
    ;;

  update)
    log_info "Updating OpenClaw on $HOST..."
    "${ssh_base[@]}" "
      set -euo pipefail
      cd /opt/openclaw
      $compose_cmd pull
      $compose_cmd up -d
      echo 'Running post-update doctor...'
      $compose_cmd exec -T openclaw-gateway openclaw doctor --non-interactive --fix || true
    "
    ;;

  logs)
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose logs -f --tail 100 openclaw-gateway"
    ;;

  status)
    echo "=== Container Status ==="
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose ps"
    echo ""
    echo "=== Gateway Status ==="
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw status --json 2>/dev/null || echo 'Gateway not responding'"
    ;;

  health)
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw health --json"
    ;;

  doctor)
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw doctor --non-interactive --fix"
    ;;

  models)
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw models status"
    ;;

  auth-list)
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw models status --json"
    ;;

  auth-openai)
    log_info "Starting OpenAI Codex OAuth flow..."
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -it openclaw-gateway openclaw models auth login --provider openai-codex"
    ;;

  auth-anthropic)
    echo "Paste Anthropic API key (press Enter when done):"
    read -s api_key
    echo ""
    if [[ -n "$api_key" ]]; then
      printf '%s' "$api_key" | "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw models auth paste-token --provider anthropic"
    fi
    ;;

  auth-gemini)
    echo "Paste Gemini API key (press Enter when done):"
    read -s api_key
    echo ""
    if [[ -n "$api_key" ]]; then
      printf '%s' "$api_key" | "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway openclaw models auth paste-token --provider google-gemini-cli"
    fi
    ;;

  config)
    action="${1:-view}"
    case "$action" in
      view)
        "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway cat ~/.openclaw/openclaw.json"
        ;;
      edit)
        log_warn "Editing config directly is not recommended. Use CLI or doctor."
        "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -it openclaw-gateway vi ~/.openclaw/openclaw.json"
        ;;
      backup)
        "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -T openclaw-gateway sh -c 'cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup.\$(date +%s)'"
        ;;
      *)
        log_error "Unknown config action: $action"
        exit 1
        ;;
    esac
    ;;

  shell)
    "${ssh_base[@]}" "cd /opt/openclaw && docker compose exec -it openclaw-gateway sh"
    ;;

  tunnel)
    local_port="${1:-18789}"
    should_open=0
    if [[ "${1:-}" == "--open" ]]; then
      should_open=1
      local_port=18789
    fi

    token="$(grep '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)"
    local_url="http://127.0.0.1:${local_port}"
    if [[ -n "$token" ]] && [[ "$token" != *"your-random"* ]]; then
      local_url="${local_url}/?token=${token}"
    fi

    log_info "Forwarding 127.0.0.1:${local_port} -> ${HOST}:18789"
    log_info "Access at: $local_url"

    ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -N -L "${local_port}:127.0.0.1:18789" "${USER_NAME}@${HOST}" &
    tunnel_pid=$!
    trap 'kill "$tunnel_pid" 2>/dev/null || true' INT TERM EXIT

    if [[ "$should_open" -eq 1 ]]; then
      sleep 2
      if command -v open >/dev/null 2>&1; then
        open "$local_url" >/dev/null 2>&1 || true
      fi
    fi

    wait "$tunnel_pid"
    trap - INT TERM EXIT
    ;;

  tailscale-status)
    "${ssh_base[@]}" "tailscale status 2>/dev/null || echo 'Tailscale not running on host'"
    ;;

  *)
    cat <<EOF
OpenClaw VPS Deploy Script v2026.3.13

Lifecycle Commands:
  setup        Install Docker/compose/Tailscale on the host
  deploy       Deploy the compose stack
  redeploy     Re-run compose with the current env
  update       Pull latest image and run doctor
  logs         Follow gateway logs
  status       Show compose and gateway status
  health       Run gateway health
  doctor       Run doctor with repairs

Auth Commands:
  models       Show model auth status
  auth-list    JSON model/auth status
  auth-openai  Run OpenAI Codex OAuth
  auth-anthropic  Paste Anthropic API key
  auth-gemini  Paste Gemini API key

Config Commands:
  config view
  config edit
  config backup

Access Commands:
  shell
  tunnel [port]
  tunnel --open
  tailscale-status

Before first deploy:
  1. cp .env.prod.example .env.prod
  2. Fill in OPENCLAW_GATEWAY_TOKEN, OPENCLAW_DATA_DIR, OPENCLAW_LEGACY_CONTAINER
  3. ./scripts/config-cleanup.sh
  4. ./ops/vps-deploy.sh setup
  5. ./ops/vps-deploy.sh deploy
EOF
    exit 1
    ;;
esac
