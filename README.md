
This is file to tell hot to proceed further

Look at .claude/CLAUDE.md and AGENTS.md in current folder and in ../agent-scripts

Linux Hostinger -> ssh -i ~/.ssh/hostinger_agent ubuntu@187.77.7.226 "sudo docker exec -it openclaw-ylld-openclaw-1 sh"
Easy login (laptop + AI) -> ./vps-openclaw.sh shell
Open local dashboard tunnel -> ./vps-openclaw.sh tunnel
Open local dashboard tunnel + browser -> ./vps-openclaw.sh tunnel --open
Clawdbot workspace (skills/tools/memory) is synced locally in `clawdbot/` via `./vps-openclaw-workspace-sync.sh pull|push`

## VPS Instances (Hostinger)

- Max (public): container `openclaw-ylld-openclaw-1`, Hostinger proxy `57439` on `0.0.0.0`
- Lera (Tailscale-only): container `openclaw-lera-openclaw-1`, URL `http://100.117.205.8:57440`

Select instance with:
- `OPENCLAW_CONTAINER=openclaw-lera-openclaw-1 ./vps-openclaw.sh shell|status|logs`
- `OPENCLAW_CONTAINER=openclaw-lera-openclaw-1 ./vps-openclaw-workspace-sync.sh pull|push`

## Linear (ONLY supported flow)

- No Linear CLI is installed (`lin` / `linear` binaries are expected to be missing).
- Use the Clawdbot Linear skill script:
  - `clawdbot/skills/linear/scripts/linear.sh teams`
  - `clawdbot/skills/linear/scripts/linear.sh create MAX "Title" "Description"`
- Auth is via `LINEAR_API_KEY` in `.env` (do not hardcode tokens into repo files).

## Project Context Packs

- SouthFloridaQigong context pack (docs + image manifest) lives at:
  - `clawdbot/business/southfloridaqigong/`

## Bot creds:

### Github
    email:  openclaw@maxpetrusenko.com
 (store in password manager)
    git_un: openclawb0t
    gh_ssh_key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvMqtBwd3kkpKbVola3ILSQtgXDhhGCbiPOB7M+pqRx openclawb0t
