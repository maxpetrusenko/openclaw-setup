---
name: openclaw-ops-maintenance
description: Use when running a daily or manual ops sweep for Max's OpenClaw setup, especially for updater checks, cron review, last-day work review, VPS drift, or deciding whether a new skill should be added, improved, or vendored.
metadata: {"clawdbot":{"emoji":"🦞","os":["darwin","linux"]}}
---

# OpenClaw Ops Maintenance

Use this skill for the recurring Max OpenClaw maintenance loop.

## First Read

1. `HEARTBEAT.md`
2. `memory/active-tasks.md`
3. `vps/auto-update.md`
4. `vps/stats/auto-update.state` if present
5. `memory/YYYY-MM-DD.md` for today and yesterday

## Routine

1. Check updater state.
   - read `vps/stats/auto-update.state` first when it exists
   - Prefer `openclaw update status --json`
   - note current version, target version, last updater decision, and whether the host updater skipped because the system was busy
2. Check runtime health.
   - `openclaw status --json`
   - `openclaw cron list`
   - `openclaw cron runs --id <jobId> --limit 20` when a job looks suspicious
3. Review the last day of work.
   - summarize recent sessions, cron runs, and any durable notes in memory files
   - do not invent progress from placeholder daily files
4. Review skill opportunities.
   - if `/Users/maxpetrusenko/Desktop/Projects/skills` exists, use it as the shared registry
   - prefer `skill-runtime` for relevance, `skill-improver` for weak local skills, `vendor-skill.py` for vetted upstream imports
   - if the shared registry path is unavailable, emit suggestions only
5. Leave durable notes only when warranted.
   - update `memory/active-tasks.md` for real follow-up work
   - update the daily log only for high-signal facts or outcomes
6. Stay read-only by default.
   - do not change host config, OpenClaw config, cron jobs, or permissions during the review
   - report issues and next actions instead

## Shared Skill Registry

When running on Max's Mac and the shared registry exists:

- repo: `/Users/maxpetrusenko/Desktop/Projects/skills`
- use `skills/skill-runtime` to decide what belongs in a manifest
- use `skills/skill-improver` when a local skill is vague or too broad
- use `scripts/load-skills.sh` only after a dry-run or explicit request
- use `scripts/vendor-skill.py` to vendor pinned leaf skills from `openclaw/skills`

When running on the VPS:

- do not assume the shared registry exists
- produce a local follow-up recommendation instead of pretending the registry is available

## Review Targets

- host updater status
- cron health and missed runs
- memory freshness
- VPS workspace drift
- upstream OpenClaw changes that should be noticed
- skill gaps that would make repeated ops work easier

## Output Shape

Always report:

- Updater
- Cron
- Last-day work
- Skill opportunities
- Next actions

Keep it terse. High signal only.

## Anti-Patterns

- treating heartbeat noise as human activity
- claiming work happened when daily files are placeholders
- auto-loading shared skills from the VPS
- mutating config, permissions, or cron state during a review-only sweep
- vendoring whole upstream skill repos instead of pinned leaf paths
- editing memory files just to look busy
