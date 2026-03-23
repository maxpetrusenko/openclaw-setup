#!/usr/bin/env bash
set -euo pipefail

HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
USER_NAME="${OPENCLAW_VPS_USER:-root}"
KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
CONTAINER_NAME="${OPENCLAW_CONTAINER:-openclaw-ylld-openclaw-1}"

ssh_base=(
  ssh
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  "${USER_NAME}@${HOST}"
)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

resolve_container() {
  if "${ssh_base[@]}" "sudo docker ps --format '{{.Names}}' | grep -Fx '$CONTAINER_NAME' >/dev/null"; then
    printf '%s\n' "$CONTAINER_NAME"
    return 0
  fi

  local found count
  found="$("${ssh_base[@]}" "sudo docker ps --filter 'name=openclaw' --format '{{.Names}}'" 2>/dev/null || true)"
  count="$(printf '%s\n' "$found" | sed '/^$/d' | wc -l | tr -d ' ')"

  if [[ "$count" == "1" ]]; then
    printf '%s\n' "$found"
    return 0
  fi

  if [[ "$count" == "0" ]]; then
    echo "Error: No OpenClaw container found. Is the gateway running?" >&2
  else
    echo "Error: Multiple OpenClaw containers found. Set OPENCLAW_CONTAINER explicitly." >&2
    printf '%s\n' "$found" >&2
  fi
  return 1
}

echo "OpenClaw Config Cleanup v2026.3.13"
echo "=================================="
echo ""

echo "0. Resolving OpenClaw container..."
container="$(resolve_container)"
log_info "Using container: $container"
echo ""

echo "1. Backing up config..."
"${ssh_base[@]}" "
  sudo docker exec $container sh -c '
    backup_path=\"/data/.openclaw/openclaw.json.backup.\$(date +%s)\"
    cp /data/.openclaw/openclaw.json \$backup_path
    echo \"Backup created: \$backup_path\"
  '
"
echo ""

echo "2. Running OpenClaw doctor (non-interactive, fix mode)..."
"${ssh_base[@]}" "
  sudo docker exec $container openclaw doctor --non-interactive --fix 2>&1 || true
"
echo ""

echo "3. Removing stale plugin references..."
"${ssh_base[@]}" "sudo docker exec -i $container node -" <<'NODE'
const fs = require("fs");
const path = "/data/.openclaw/openclaw.json";
const secretMarkers = ["API_KEY=", "sk-", "tok_", "key_"];

function sanitizeAllowlist(list, label, fixes) {
  if (!Array.isArray(list)) return list;
  return list.map((entry) => {
    const raw = String(entry).trim();
    if (!secretMarkers.some((marker) => raw.includes(marker))) return entry;
    const match = raw.match(/^[+0-9][+0-9\s-]{4,19}/);
    if (!match) {
      fixes.push(`Suspicious ${label} entry left unchanged: ${raw.slice(0, 24)}`);
      return entry;
    }
    const cleaned = match[0].trim();
    if (cleaned !== raw) {
      fixes.push(`Trimmed corrupted ${label} entry to ${cleaned}`);
      return cleaned;
    }
    return entry;
  });
}

try {
  const cfg = JSON.parse(fs.readFileSync(path, "utf8"));
  const fixes = [];
  let changed = false;

  if (Array.isArray(cfg.plugins?.deny)) {
    const before = cfg.plugins.deny.length;
    cfg.plugins.deny = cfg.plugins.deny.filter((plugin) => {
      const stale = String(plugin).includes("lossless-claw");
      if (stale) fixes.push(`Removed stale plugin deny entry: ${plugin}`);
      return !stale;
    });
    if (cfg.plugins.deny.length !== before) changed = true;
    if (cfg.plugins.deny.length === 0) {
      delete cfg.plugins.deny;
      fixes.push("Removed empty plugins.deny");
    }
  }

  const whatsapp = cfg.channels?.whatsapp;
  if (whatsapp) {
    for (const key of ["allowFrom", "groupAllowFrom"]) {
      if (Array.isArray(whatsapp[key])) {
        const next = sanitizeAllowlist(whatsapp[key], `whatsapp.${key}`, fixes);
        if (JSON.stringify(next) !== JSON.stringify(whatsapp[key])) {
          whatsapp[key] = next;
          changed = true;
        }
      }
    }
    if (whatsapp.accounts && typeof whatsapp.accounts === "object") {
      for (const [accountId, accountCfg] of Object.entries(whatsapp.accounts)) {
        if (!accountCfg || typeof accountCfg !== "object") continue;
        for (const key of ["allowFrom", "groupAllowFrom"]) {
          if (Array.isArray(accountCfg[key])) {
            const next = sanitizeAllowlist(accountCfg[key], `whatsapp.accounts.${accountId}.${key}`, fixes);
            if (JSON.stringify(next) !== JSON.stringify(accountCfg[key])) {
              accountCfg[key] = next;
              changed = true;
            }
          }
        }
      }
    }
  }

  if (changed) {
    fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + "\n");
  }

  console.log(JSON.stringify({ fixed: changed, changes: fixes }, null, 2));
} catch (error) {
  console.error(JSON.stringify({ error: error.message }, null, 2));
  process.exitCode = 1;
}
NODE
echo ""

echo "4. Verifying gateway health..."
"${ssh_base[@]}" "
  sudo docker exec $container openclaw health --json 2>&1 || true
"
echo ""

echo "5. Checking for common issues..."
"${ssh_base[@]}" "sudo docker exec -i $container node -" <<'NODE'
const fs = require("fs");
const cfg = JSON.parse(fs.readFileSync("/data/.openclaw/openclaw.json", "utf8"));
const raw = JSON.stringify(cfg);

if (raw.includes("sk-ant-")) {
  console.log("WARN: Anthropic API key found in config. Move it to auth profiles.");
}
if (raw.includes("sk-proj-")) {
  console.log("WARN: OpenAI API key found in config. Move it to auth profiles.");
}
if (String(cfg.gateway?.bind ?? "auto") !== "loopback") {
  console.log(`WARN: Gateway binding is ${cfg.gateway?.bind ?? "auto"}. Consider loopback.`);
}
if (raw.includes("lossless-claw")) {
  console.log("WARN: Stale lossless-claw reference still present.");
}
NODE
echo ""

echo "6. Recommendations:"
echo "   - Rotate gateway token: openssl rand -base64 24"
echo "   - Use OAuth: ./ops/vps-deploy.sh auth-openai"
echo "   - Switch to loopback binding: ./ops/vps-deploy.sh deploy"
echo "   - Remove API keys from .env after OAuth is configured"
echo ""
log_info "Cleanup complete!"
echo ""
echo "Next steps:"
echo "  1. ./ops/vps-deploy.sh deploy      # Switch to clean config"
echo "  2. ./ops/vps-deploy.sh auth-openai # Setup OAuth"
echo "  3. ./ops/vps-deploy.sh models      # Verify auth"
