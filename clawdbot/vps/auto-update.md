# OpenClaw Auto Update

Host-level updater for the public OpenClaw VPS.

## Why host-level

- `openclaw update` can restart the gateway service
- host cron is safer than asking OpenClaw to restart itself from inside its own run
- this live Docker install does not have an in-container gateway service, so the host updater restarts the container after a successful package update
- daily review still stays inside OpenClaw cron

## Live assumptions

- container: `openclaw-ylld-openclaw-1`
- install kind: package
- package manager: `pnpm`
- updater command: `openclaw update --yes`

## Script

Source of truth in this repo:

- `ops/openclaw-auto-update.sh`

Suggested host install path:

- `/root/bin/openclaw-auto-update.sh`

Mirror state path written into the workspace:

- `vps/stats/auto-update.state`

## Dry run

From the VPS host:

```bash
/root/bin/openclaw-auto-update.sh --dry-run
```

Expected:

- reports `dry run` when an update is available and idle
- reports `skipped` when there was recent non-system activity
- reports `no update` when current version is current
- refreshes `vps/stats/auto-update.state`

## Cron

Suggested host crontab entry:

```cron
35 4 * * * ALERT_TELEGRAM_CHAT_ID=<chat_id> /root/bin/openclaw-auto-update.sh >> /var/log/openclaw-auto-update.log 2>&1
```

Why `04:35`:

- after the quiet overnight window starts
- before the 06:00 daily memory cron
- far from the 09:00 morning digests

## Idle gate

Updater allows install only when no recent non-cron session exists within the configured idle window and that session is not marked `systemSent: true`.

Default:

- `OPENCLAW_UPDATE_IDLE_MINUTES=60`

## Daily review job

Keep the review in OpenClaw cron. Prompt shape:

```text
Use the openclaw-ops-maintenance skill. Run the daily ops maintenance routine for Max. Check updater status, cron health, last-day work, and skill opportunities. Read vps/stats/auto-update.state if present. If the shared skill registry path /Users/maxpetrusenko/Desktop/Projects/skills is unavailable, say so and emit follow-up suggestions only. Update memory files only for durable facts or actionable follow-ups. End with a terse summary.
```

Suggested schedule:

```bash
openclaw cron add \
  --name "Daily OpenClaw Ops Maintenance" \
  --cron "30 9 * * *" \
  --tz "America/New_York" \
  --session isolated \
  --message "Use the openclaw-ops-maintenance skill. Run the daily ops maintenance routine for Max. Check updater status, cron health, last-day work, and skill opportunities. Read vps/stats/auto-update.state if present. If the shared skill registry path /Users/maxpetrusenko/Desktop/Projects/skills is unavailable, say so and emit follow-up suggestions only. Update memory files only for durable facts or actionable follow-ups. Do not change config, permissions, cron jobs, or host state during the review. End with a terse summary." \
  --no-deliver
```

## Verification

1. `bash -n ops/openclaw-auto-update.sh`
2. run host dry-run once
3. confirm cron entry exists on host
4. `openclaw cron list`
5. if needed: `openclaw cron run <jobId>`
