# OpenClaw Auth Setup Guide

## Goal

Move provider auth out of `.env` and into OpenClaw-managed auth storage.

## Recommended Setup: OpenAI Codex OAuth

```bash
./ops/vps-deploy.sh auth-openai
```

Manual equivalent:

```bash
docker exec -it openclaw-gateway openclaw models auth login --provider openai-codex
```

Run it from a shell where you can finish the browser login flow.

## Fallback: Anthropic API Key

```bash
./ops/vps-deploy.sh auth-anthropic
```

Manual equivalent:

```bash
docker exec -it openclaw-gateway openclaw models auth paste-token --provider anthropic
```

## Verify Auth Status

```bash
./ops/vps-deploy.sh models
```

## Model Strategy

| Provider | Auth Type | Priority | Notes |
|----------|-----------|----------|-------|
| OpenAI Codex | OAuth | 1 | Recommended |
| Anthropic | API key | 2 | Fallback |
| Gemini | API key | 3 | Optional |

If you need deterministic auth rotation, use OpenClaw’s built-in commands:

```bash
openclaw models auth order get --provider anthropic
openclaw models auth order set --provider anthropic anthropic:default
```

## Security Notes

1. Never commit `.env.prod`
2. Rotate tokens after any suspected exposure
3. Prefer OAuth where available
4. Keep auth inspection read-only; do not hand-edit auth profile files

## Troubleshooting

OAuth needs to be re-run:

```bash
./ops/vps-deploy.sh auth-openai
```

Token expired or auth missing:

```bash
./ops/vps-deploy.sh doctor
./ops/vps-deploy.sh models
```
