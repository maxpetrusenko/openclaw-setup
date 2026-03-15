# OpenClaw Ops Hybrid Daily Update Design

**Date:** 2026-03-14

## Goal

Keep Max's live OpenClaw instance current without restarting during active use, and add a daily ops review loop that summarizes what happened, surfaces maintenance issues, and suggests skill improvements.

## Constraints

- Live VPS install is a package install, not a git checkout.
- Live `openclaw update status --json` reports:
  - current version: `2026.2.19`
  - latest stable available: `2026.3.13`
- Existing OpenClaw cron jobs already cover daily memory creation and morning digests.
- Shared skill registry lives on Max's Mac at `/Users/maxpetrusenko/Desktop/Projects/skills`; the VPS cannot assume that path exists.

## Decision

Use a hybrid model:

1. Host cron on the VPS handles self-update and restart.
2. OpenClaw cron handles the daily review routine.
3. A local OpenClaw skill documents the review workflow and shared-skill follow-ups.

## Why Hybrid

### Host cron for self-update

- Safest place to restart the container-managed service.
- Independent from OpenClaw session state.
- Can gate updates on recent activity before running `openclaw update --yes`.
- Can restart the Docker container after package updates when no in-container gateway service is installed.

### OpenClaw cron for review

- Better fit for agentic summarization.
- Can inspect session state, cron state, memory files, and workspace docs.
- Can write follow-up notes in the workspace and send a concise summary.

## Idle Gate

Treat OpenClaw as idle when there are no recent non-cron sessions that:

- were updated in the last 60 minutes, and
- are not marked `systemSent: true`

This avoids heartbeat or isolated cron noise blocking the updater forever.

## Daily Review Output

The daily review should emit:

- updater status
- cron health
- last-day work summary
- skill opportunities
- next actions

It should only update memory files when it finds durable facts or concrete follow-up items.
It should stay read-only for config and host state.

## Shared Skills Policy

When the review runs on Max's Mac or another environment that has the shared registry, it should reference:

- `skill-runtime`
- `skill-improver`
- `scripts/load-skills.sh`
- `scripts/vendor-skill.py`

When the shared registry is unavailable, it should produce suggestions only and explicitly note the missing path.

## Updater State Visibility

The host updater writes both:

- host-local state at `/var/lib/openclaw-auto-update/state.env`
- workspace-visible mirror state at `vps/stats/auto-update.state`

The daily review reads the mirrored state so it can report whether the last updater run skipped, updated, or failed.
