# OpenClaw VPS Migration Guide

## Operating Model

**Hostinger prod is the only live runtime.**

- Local OpenClaw runtime is optional
- Local source-update work in repo root `.`
- Staging created by copying prod state
- Plugin/config experiments in staging first
- Rollback: previous image tag + untouched prod state

From: **6/10 current setup** -> **8/10 safer deployment**

## Problem Summary

| Issue | Current State | Target State | Fix |
|-------|---------------|--------------|-----|
| Network exposure | Raw port 57439 public | Loopback + SSH tunnel | `127.0.0.1:18789:18789` |
| Config integrity | `plugins.deny: ["lossless-claw"]` | Clean config | `doctor --fix` |
| Secret storage | API keys in `.env` / config | OAuth auth profiles | `models auth login` |
| Deploy method | `npm install -g` in container | Pinned image + bind-mounted existing data | `docker compose` |
| Auth strategy | API keys only | OAuth primary | OpenAI Codex OAuth |

## Migration Checklist

### Phase 1: Config Cleanup

```bash
./scripts/config-cleanup.sh
```

What this does:
- backs up `openclaw.json`
- runs `openclaw doctor --non-interactive --fix`
- removes stale `lossless-claw` deny entries
- trims obviously corrupted WhatsApp allowlist entries that contain secret markers
- warns about remaining config risks

### Phase 2: Setup Environment

```bash
cp .env.prod.example .env.prod

# edit .env.prod
# required:
#   OPENCLAW_GATEWAY_TOKEN=<generated token>
#   OPENCLAW_DATA_DIR=/docker/openclaw-ylld/data
#   OPENCLAW_LEGACY_CONTAINER=openclaw-ylld-openclaw-1
```

### Phase 3: Deploy Clean Image

```bash
./ops/vps-deploy.sh setup
./ops/vps-deploy.sh deploy
./ops/vps-deploy.sh status
```

What this does:
- stops the legacy container if `OPENCLAW_LEGACY_CONTAINER` is set
- pulls `ghcr.io/openclaw/openclaw:v2026.3.13-1`
- reuses the existing `.openclaw` data directory through a bind mount
- exposes only `127.0.0.1:18789` on the VPS host

### Phase 4: Setup OAuth

```bash
./ops/vps-deploy.sh auth-openai
```

Optional fallback:

```bash
./ops/vps-deploy.sh auth-anthropic
```

After OAuth succeeds, remove unused API keys from `.env.prod`.

### Phase 5: Remote Access

Supported path:

```bash
./ops/vps-deploy.sh tunnel
./ops/vps-deploy.sh tunnel --open
```

Access URL:

```text
http://127.0.0.1:18789/?token=...
```

Optional:
- if the host is already on Tailscale, use Tailscale for the SSH transport itself
- inspect host tailnet state with `./ops/vps-deploy.sh tailscale-status`

### Phase 6: Deprecate Old Setup

```bash
docker stop openclaw-ylld-openclaw-1
docker rm openclaw-ylld-openclaw-1
# close VPS firewall access to 57439
```

## Verification Commands

```bash
./ops/vps-deploy.sh status
./ops/vps-deploy.sh health
./ops/vps-deploy.sh models
./ops/vps-deploy.sh auth-list
./ops/vps-deploy.sh config view
```

## Rollback

```bash
./vps-openclaw.sh shell
# inside container:
# cp /data/.openclaw/openclaw.json.backup.<timestamp> /data/.openclaw/openclaw.json
```

## Security Improvements

1. No raw public port on the new stack
2. Pinned image instead of mutating the live container
3. Gateway token stays explicit
4. OAuth preferred over API keys
5. Existing data path is reused deliberately, not silently replaced with fresh volumes

## Auth Profile Storage

Provider auth is stored by OpenClaw under `~/.openclaw/agents/...`, not in `.env.prod`.
Inspect live state with `./ops/vps-deploy.sh models` or `./ops/vps-deploy.sh auth-list`.

## Troubleshooting

Gateway unhealthy after deploy:

```bash
./ops/vps-deploy.sh logs
./ops/vps-deploy.sh doctor
```

Need host tailnet status:

```bash
./ops/vps-deploy.sh tailscale-status
```

Old plugin errors remain:

```bash
./scripts/config-cleanup.sh
./ops/vps-deploy.sh doctor
```

## Observability

Prod snapshot:

```bash
./ops/oc-snapshot.sh
```

Daily report:

```bash
./ops/oc-daily-report.sh
find reports/openclaw-daily -maxdepth 3 -type f | sort
```

## Staging Workflow

Staging is a disposable clone for plugin/config experiments:

```bash
# Clone prod state to staging
./ops/oc-stage-clone.sh

# Bring staging up (127.0.0.1:18790)
./ops/oc-stage-up.sh

# Verify staging health
./ops/oc-stage-smoke.sh

# Destroy staging when done
./ops/oc-stage-down.sh       # Keep state
./ops/oc-stage-down.sh --purge  # Delete state
```

Prod remains untouched during staging lifecycle.

## Rating Change

| Metric | Before | After |
|--------|--------|-------|
| Network Security | 3/10 | 8/10 |
| Config Hygiene | 4/10 | 9/10 |
| Auth Strategy | 5/10 | 8/10 |
| Deploy Safety | 6/10 | 8/10 |
| Observability | 7/10 | 8/10 |
| **Overall** | **6/10** | **8/10** |
