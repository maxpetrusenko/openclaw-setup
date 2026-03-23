# Hostinger OpenClaw Current State

> **Last updated:** 2026-03-15
> **Captured via:** SSH to 187.77.7.226

## Prod Container

**Container name:** `openclaw-ylld-openclaw-1`

**Image:** `ghcr.io/hostinger/hvps-openclaw:latest`

**Status:** Up and running

**OpenClaw version:** `2026.2.12`

## Host Mount Paths

**Prod state directory:** `/docker/openclaw-ylld/data`

**Mounted into container as:** `/data`

**Additional mount:** `/docker/openclaw-ylld/data/linuxbrew` -> `/home/linuxbrew`

## Container State Paths (Inside Container)

**OpenClaw config:** `/data/.openclaw/openclaw.json`

**Extensions:** `/data/.openclaw/extensions/`

**Sessions:** `/data/.openclaw/agents/*/sessions.json`

**Logs:** `/data/.openclaw/logs/`

## Installed Extensions

1. **lossless-claw**
   - Path: `/data/.openclaw/extensions/lossless-claw`
   - Has docs, node_modules, src

2. **instinct8-compaction**
   - Path: `/data/.openclaw/extensions/instinct8-compaction`
   - Has src

## Plugin Records in openclaw.json

Active plugins configured:
- `lossless-claw` (line 29, 46)
  - Spec: `@martian-engineering/lossless-claw`
  - Install path: `/data/.openclaw/extensions/lossless-claw`

- `instinct8-compaction` (line 32)
  - Sidecar URL: `http://instinct8-sidecar:8765`

**Note:** No `bmad` plugin records found in config.

## Other Containers on VPS

- `openclaw-lera-openclaw-1` - Another OpenClaw instance
- `instinct8-sidecar` - Sidecar for instinct8-compaction
- `ship-*` - Unrelated services (web, api, caddy, postgres)

## Staging Status

**Staging container:** Does not exist

**Staging state directory:** `/docker/openclaw-stage/data` (not created yet)

## Daily Reports Location

**Recommended path on VPS:** `/docker/openclaw-reports/` (to be created)

**Local path in repo:** `reports/openclaw-daily/`

## Known Issues

OpenClaw shows config warnings:
- `channels.telegram: Unrecognized key: "streaming"`
- `gateway.controlUi: Unrecognized key: "dangerouslyAllowHostHeaderOriginFallback"`

These are non-critical (unrecognized keys, not invalid values).

## Stale Plugin Records

None detected. All plugin records reference installed extensions.

## Next Steps

1. Create staging state dir: `/docker/openclaw-stage/data`
2. Set up daily reports directory on VPS
3. Create staging container on isolated loopback port (127.0.0.1:18790)
