# OpenClaw VPS Quickstart

## First-Time Flow

```bash
# 1. Create env from template
cp .env.prod.example .env.prod
openssl rand -base64 24  # paste into OPENCLAW_GATEWAY_TOKEN

# 2. Repair legacy config in the live container
./scripts/config-cleanup.sh

# 3. Prepare host
./ops/vps-deploy.sh setup

# 4. Deploy loopback-only gateway
./ops/vps-deploy.sh deploy

# 5. Login with OpenAI Codex OAuth
./ops/vps-deploy.sh auth-openai

# 6. Open local tunnel to the remote gateway
./ops/vps-deploy.sh tunnel --open
```

## Access Methods

| Method | Command | URL |
|--------|---------|-----|
| SSH tunnel | `./ops/vps-deploy.sh tunnel` | `http://127.0.0.1:18789/?token=...` |
| SSH + browser | `./ops/vps-deploy.sh tunnel --open` | Auto-opens the same local URL |

## Essential Commands

```bash
./ops/vps-deploy.sh status     # Container + gateway status
./ops/vps-deploy.sh health     # Health check
./ops/vps-deploy.sh logs       # Follow logs
./ops/vps-deploy.sh doctor     # Run repairs
./ops/vps-deploy.sh models     # Model auth status
./ops/vps-deploy.sh tailscale-status  # Host tailnet status
./ops/vps-deploy.sh shell      # Container shell
```

## Auth Setup

```bash
./ops/vps-deploy.sh auth-openai      # OpenAI Codex OAuth (recommended)
./ops/vps-deploy.sh auth-anthropic   # Anthropic API key (fallback)
./ops/vps-deploy.sh auth-list        # JSON auth/model status
```

## Troubleshooting

| Problem | Command |
|---------|---------|
| Container not starting | `./ops/vps-deploy.sh logs` |
| Auth errors | `./ops/vps-deploy.sh models` |
| Config issues | `./ops/vps-deploy.sh doctor` |
| Old plugin errors | `./scripts/config-cleanup.sh` |

## Files Reference

| File | Purpose |
|------|---------|
| `docker-compose.prod.yml` | Production compose (host loopback bind only) |
| `.env.prod.example` | Env template |
| `ops/vps-deploy.sh` | Deploy/orchestration |
| `scripts/config-cleanup.sh` | Config repair |
| `docs/vps-migration.md` | Full migration guide |

## Environment Variables

```bash
export OPENCLAW_VPS_HOST=187.77.7.226
export OPENCLAW_VPS_USER=root
export OPENCLAW_VPS_KEY=~/.ssh/hostinger_agent
```

## Security Checklist

- [ ] Gateway binds to loopback (127.0.0.1)
- [ ] No public host port for the new stack
- [ ] OAuth enabled for OpenAI Codex
- [ ] API keys removed from `.env.prod`
- [ ] `OPENCLAW_DATA_DIR` points at the existing live data path
- [ ] Token stored in `OPENCLAW_GATEWAY_TOKEN`

## Rollback

```bash
./vps-openclaw.sh shell
```
