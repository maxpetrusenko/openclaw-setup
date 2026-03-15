---
summary: "Deeper handbook notes for the live clawdbot workspace"
read_when:
  - You need more detail than the installed protocol
  - Designing multi-agent, memory, browser, cron, or troubleshooting workflows
---

# Handbook Key Points

This file keeps the highest-value handbook lessons inside the live clawdbot workspace.

## Multi-Agent

- router should route, validate, and escalate
- workers should have narrow scope
- handoffs should name artifacts, output paths, and done criteria
- repeated failure twice means escalate, not loop

## Memory

- `SOUL.md` = stable identity
- `MEMORY.md` = durable facts and preferences
- `memory/YYYY-MM-DD.md` = raw operational log
- `memory/active-tasks.md` = save game
- larger projects should keep their own context note

## Browser

- API first
- fetch/search second
- browser only when needed
- isolated browser profile by default
- snapshot, wait, re-snapshot, then act
- use shadow mode before risky submissions when practical

## Cron / Heartbeat

- recurring work must be observable
- every serious scheduled task needs a canary or completion line
- idempotent jobs only
- exact time assumptions should be explicit
- heartbeat should surface blocked work, not fake activity

## Troubleshooting

- inspect logs and file state first
- reproduce directly when possible
- trust artifacts over confidence
- keep context files small so they stay useful

## Stack Design

- start with boring stable loops
- avoid automating processes that are still changing
- use draft-first workflows for high-error-cost actions
