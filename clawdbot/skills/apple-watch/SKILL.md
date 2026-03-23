---
name: apple-watch
description: Install and run OpenClaw from Apple Watch via iPhone Shortcuts and SSH.
metadata: {"clawdbot":{"emoji":"⌚","os":["darwin","ios"]}}
---

# Apple Watch

Use this skill when asked to set up OpenClaw on Apple Watch.

## Current Capability

- No native watchOS app target in this workspace.
- Supported path: Apple Watch -> iPhone Shortcuts -> SSH -> OpenClaw VPS container.

## Setup

1. On iPhone Shortcuts, create a shortcut named `OpenClaw Watch`.
2. Add action `Dictate Text`.
3. Add `Run Script over SSH`:
   - Host: `187.77.7.226`
   - User: `root`
   - Auth: SSH key
   - Input: `Provided Input`
   - Script:

```bash
sudo docker exec -i openclaw-ylld-openclaw-1 sh -lc '
msg="$(cat)"
openclaw agent --agent main --message "$msg"
'
```

4. Add `Show Result`.
5. Enable `Show on Apple Watch` in shortcut settings.

## Validation

From laptop:
```bash
./vps-openclaw.sh status
```

Then run the shortcut from watch with: `status`.

## Optional Delivery

To push replies to Telegram as well:

```bash
sudo docker exec -i openclaw-ylld-openclaw-1 sh -lc '
msg="$(cat)"
openclaw agent --agent main --message "$msg" --deliver --reply-channel telegram --reply-to @YOUR_HANDLE
'
```
