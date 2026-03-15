---
summary: "Install OpenClaw access on Apple Watch using Shortcuts + SSH."
read_when:
  - Enabling quick OpenClaw prompts from Apple Watch.
---

# Apple Watch Install (OpenClaw)

Status as of February 20, 2026:
- This workspace does not contain a native watchOS app target (`.xcodeproj`/`.xcworkspace` with Watch target).
- Fastest install path is Apple Shortcuts on iPhone, synced to Apple Watch.

## What This Gives You

- Tap on watch and dictate a prompt.
- Prompt runs on VPS inside `openclaw-ylld-openclaw-1`.
- Response returns back to the shortcut result.

## Prerequisites

- Apple Watch paired with iPhone.
- iPhone `Shortcuts` app installed.
- SSH key on iPhone that can access `root@187.77.7.226`.
- VPS container running (`openclaw-ylld-openclaw-1`).

Check from laptop:
```bash
./vps-openclaw.sh status
```

## Build the Shortcut (iPhone)

1. Open `Shortcuts` -> `+` -> create `OpenClaw Watch`.
2. Add `Dictate Text`.
3. Add `Run Script over SSH`:
   - Host: `187.77.7.226`
   - User: `root`
   - Auth: SSH key
   - Port: `22`
   - Input: `Provided Input` (from `Dictate Text`)
   - Script:
```bash
sudo docker exec -i openclaw-ylld-openclaw-1 sh -lc '
msg="$(cat)"
openclaw agent --agent main --message "$msg"
'
```
4. Add `Show Result`.
5. In shortcut settings, enable `Show on Apple Watch`.

## Optional: Deliver Back to Telegram

If you want the reply delivered to Telegram too:
```bash
sudo docker exec -i openclaw-ylld-openclaw-1 sh -lc '
msg="$(cat)"
openclaw agent --agent main --message "$msg" --deliver --reply-channel telegram --reply-to @YOUR_HANDLE
'
```

## Security Notes

- Do not store API keys or tokens inside shortcut text.
- Keep auth via SSH keys only.
- If phone is shared, protect Shortcuts access (Face ID / passcode).

## Troubleshooting

- `permission denied (publickey)`: re-import SSH key on iPhone.
- `Cannot connect to host`: check network path to `187.77.7.226`.
- `docker exec` failure: confirm container name with:
```bash
./vps-openclaw.sh status
```
