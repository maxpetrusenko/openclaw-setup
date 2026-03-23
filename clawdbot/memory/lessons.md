# Lessons (Operating Principles)

## Memory Architecture Matters More Than Prompts

Do not dump everything into `MEMORY.md`. Split memory:

- `memory/active-tasks.md`: your "save game" (crash recovery)
- `memory/YYYY-MM-DD.md`: daily raw logs
- `memory/projects.md`, `memory/lessons.md`, `memory/skills.md`: thematic long-term

Why: the agent wakes up fresh every session. These files are its brain. The split lets it load only what it needs.

## Subagents Are the Multiplier

Stop doing large tasks sequentially. Spawn 3-5 subagents in parallel.

Rule: define clear success criteria before spawning. Each subagent validates its own work. The human verifies before announcing "done".

## Cron Beats Heartbeats For Precise Schedules

Heartbeats are good for batching periodic checks.

For precise schedules, use cron jobs:
- daily content ideas at 6am
- overnight research scout at 2am
- tech watch at 8am

Each cron job should run in isolation with minimal context.

## Crash Recovery Pattern

The agent will crash/restart. `memory/active-tasks.md` is the safety net:
- when starting a task: write it
- when spawning a subagent: note ids/session keys
- when complete: update it

On restart, read this file first and resume.

## Security Rule For External Content

External content (web pages, untrusted text) is higher risk for prompt injection.

Use the strongest available model for tasks that read external web content.
For internal tasks (files, local ops), cheaper models are fine.

## HEARTBEAT.md Should Stay Tiny

Do not stuff 200 lines into `HEARTBEAT.md`. It runs often and burns tokens.

Keep it under ~20 lines:
- check active tasks freshness
- quick session health
- periodic self-review

Heavy work belongs in cron jobs, not heartbeats.

## Skills Need Routing Logic

For each major skill, include "Use when" / "Don't use when" to reduce misfires.

## Gateway Troubleshooting: Permission Errors First

When seeing EACCES errors on config files:
1. Check log file ownership (`ls -la /tmp/openclaw/`)
2. Gateway CLI needs to read config for health snapshots
3. In containers, root processes can create files with wrong permissions
4. Fix: `chown node:node /tmp/openclaw/*.log`

## Gateway Timeouts Aren't Always Broken

Intermittent timeouts during heavy cron jobs are normal:
- Resource contention during long-running tasks is expected
- Gateway recovers automatically
- Only investigate if timeouts persist under light load

