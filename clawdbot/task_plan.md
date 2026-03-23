# Task Plan: Daily OpenClaw Digest for Max

## Goal
Create a concise daily digest for Max including channel probe summary, gateway errors (last 24h), cron status, and 1-3 suggested next actions. Output as short bullets.

## Status
**in_progress**

## Phases
1. **Gather Status Data** - Collect gateway status, cron status, channel probe results, error logs
2. **Analyze & Compile** - Process data into digest format
3. **Generate Output** - Produce concise bullet-point digest

## Decisions
- Use message tool dryRun=true for channel probes (safe, no actual send)
- Check multiple log sources if systemd journal unavailable
- Follow MEMORY.md timezone guidance (currently Portugal until 2026-03-01)

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| `openclaw gateway --json status` unknown option | 1 | Use plain `openclaw gateway status` |
| `openclaw cron list --includeDisabled=true` unknown option | 1 | Use plain `openclaw cron list` |
| `journalctl --since "24 hours ago"` no journal files | 1 | Check alternative log sources (direct files, gateway logs) |

## Files Created/Modified
- task_plan.md (this file)
- findings.md (to be created)
- progress.md (to be created)
