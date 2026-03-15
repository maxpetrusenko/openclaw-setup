# Skills (Main Work + Routing)

This file documents which skills are "main work" and when to use them.

## planning-with-files

Use when:
- any multi-step task needs a plan + scratch files + checkpoints

Don't use when:
- trivial one-liners

## Code

Use when:
- writing/editing code, debugging, adding tests, reviewing diffs

Don't use when:
- you only need facts or summaries (use web-search/summarize)

## web-search

Use when:
- you need up-to-date info or citations

Don't use when:
- the answer is in local files

## browser-use (browser-use-api)

Use when:
- cloud browser automation is needed (forms, multi-step browsing, screenshots)

Don't use when:
- a simple fetch/search is enough

## agent-relay-digest

Use when:
- generating a high-signal digest from noisy feeds/communities

Don't use when:
- you just need to summarize a single doc or conversation

## log-tail

Use when:
- you need to inspect recent logs quickly and safely

Don't use when:
- you need deep metrics; use dedicated tools/endpoints

## github

Use when:
- you need PR operations, CI triage, or GHSA updates using `gh`
- you are landing PRs end-to-end (`/landpr` workflow)
- you are finishing advisory triage (`/sectriage` workflow)

Don't use when:
- work does not touch GitHub objects (issues/PRs/runs/advisories)

## apple-watch

Use when:
- setting up or troubleshooting OpenClaw access from Apple Watch
- you need the iPhone Shortcuts + SSH bridge path

Don't use when:
- building a native watchOS app (not part of this workspace)

## openclaw-ops-maintenance

Use when:
- running the daily OpenClaw ops sweep
- checking updater state, cron health, VPS drift, or last-day work
- deciding whether a repeated ops problem should become a skill or a vendored skill

Don't use when:
- you only need a single status fact with no review loop
- you are doing a normal feature or bug task unrelated to OpenClaw operations

## social-posting

Use when:
- generating social creatives and captions for multi-platform campaigns
- posting/scheduling via GetLate with per-platform constraints
- handling IG Story vertical format + short overlay workflow

Don't use when:
- the task is only analytics/reporting without content publishing
