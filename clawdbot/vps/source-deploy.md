# Local Source Deploy To Hostinger OpenClaw

Use this when `clawdbot/` workspace sync is not enough.

## What sync does not do

- `./vps-openclaw-workspace-sync.sh pull|push` only mirrors `/data/.openclaw/workspace`
- it does not update the OpenClaw core package inside the container
- the running core is a global install in the container, not the synced workspace

## Safe local deploy path

Source of truth:

- local code: `oss/openclaw/`
- deploy helper: `ops/openclaw-deploy-local.sh`

Dry run:

```bash
./ops/openclaw-deploy-local.sh --dry-run
```

Real deploy:

```bash
./ops/openclaw-deploy-local.sh
```

What it does:

1. builds local `oss/openclaw`
2. packs a local npm tarball
3. uploads tarball to Hostinger
4. copies tarball into `openclaw-ylld-openclaw-1`
5. runs `npm install -g <tarball>` inside the container
6. restarts the container
7. verifies `openclaw --version` and `openclaw status --json`

## Notes

- this path updates core code without touching workspace secrets
- if SSH is flaky, do not assume deploy happened
- if rollback is needed, reinstall a known good package version in the container:

```bash
./vps-openclaw.sh shell
npm install -g openclaw@<known-good-version>
```
