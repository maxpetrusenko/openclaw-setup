# Chapter 6: Time-Based Automation (Cron)

## Why It Matters

Cron is how OpenClaw becomes proactive. The chapter’s strongest lesson is not scheduling syntax but operational discipline: precise task descriptions, heartbeat checks, timezone awareness, and job observability.

## Core Ideas

- OpenClaw cron combines classic schedules with natural-language task bodies.
- Specific task descriptions produce stable runs; vague tasks do not.
- Heartbeats are system self-awareness, not just routine jobs.
- Timezone mistakes are common and dangerous.
- Every scheduled task should log completion.
- Manual execution is the fastest way to validate a cron task.

## Patterns To Keep

- Write schedules clearly and note local-time intent.
- Heartbeat protocol files for recurring health checks.
- `cron-history.log` or equivalent for success and failure tracking.
- Missing-job detection as part of heartbeat.
- Test manually before trusting schedule.

## What To Adopt In OpenClaw

- Standard cron task footer:
  - output path
  - completion log line
  - failure alert behavior
- Shared heartbeat checklist and missing-run detection.
- Timezone rules in docs and config review.
- Cron recipes for briefings, backups, cleanup, EOD, and audits.

## Risks / Limits

- Timezone drift and DST can silently misfire routines.
- Frequent schedules multiply both cost and error surface.
- Natural-language cron tasks still need careful output contracts.

## Open Questions

- What heartbeat cadence is right for this repo?
- Where should cron history and canary logs live here?
