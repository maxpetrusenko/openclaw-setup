# Alerts (Weird/Unsafe Detection)

Goal: if something looks broken, unsafe, or drifting, notify the human.

## Notify Channels

Preferred:
- Telegram DM to the human (fastest)

Optional:
- Email (only if sender/domain is configured and tested)

## What Counts As "Weird/Unsafe"

- Disk usage over a threshold (e.g. >80%)
- Log files growing abnormally (e.g. any `/tmp/openclaw/*.log` > 1GB)
- Gateway not reachable
- Repeated auth/provider failures (missing keys, provider down)
- Security audit reports CRITICAL items
- Unexpected config changes (models/providers/channels) since last check

## Policy

- Read-only checks can run automatically.
- For any automated remediation, require explicit human approval (see `vps/security/change-control.md`).

