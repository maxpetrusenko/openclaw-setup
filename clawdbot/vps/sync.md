# Workspace Sync (Laptop <-> VPS)

OpenClaw can change files on the VPS by itself. To keep laptop and VPS aligned:

## Canonical Truth

- VPS workspace: `/data/.openclaw/workspace` (inside container)
- Laptop workspace: `clawdbot/` (this repo)

## Manual Sync Commands

From the repo root:

```bash
./vps-openclaw-workspace-sync.sh pull
./vps-openclaw-workspace-sync.sh push
```

## Safe Workflow (Recommended)

- Before editing locally: `pull`
- After editing locally: `push`
- If you suspect the VPS changed files while you were editing locally:
  - `pull` into a temp directory first and compare
  - do not overwrite blindly

## Change Control

Syncing is file mutation on the VPS. If the human asked for "verify before pushing":

- show what changed locally (list of files)
- ask for explicit approval
- then `push`

