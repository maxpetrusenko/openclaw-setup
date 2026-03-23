# Chapter 8: Memory & Context Management

## Why It Matters

This chapter explains how to survive session turnover and context overflow. The key move is externalizing state into layered files instead of trusting conversation history.

## Core Ideas

- Context windows are finite; compaction is normal.
- `SOUL.md` is stable identity and principles.
- `MEMORY.md` holds durable learned facts and decisions.
- Daily memory logs record operations and outcomes.
- Project context files preserve long-running state and decisions.
- Weekly memory maintenance keeps the system cheap and accurate.

## Patterns To Keep

- Write important state to files immediately.
- Keep `SOUL.md`, `MEMORY.md`, and project context small and purposeful.
- Update `MEMORY.md` when a learning changes future behavior.
- Fresh session recovery should begin from `context.md`, not chat recap.

## What To Adopt In OpenClaw

- Clear rules for what belongs in each context layer.
- Mandatory `context.md` for non-trivial projects.
- Memory maintenance cron for pruning and promoting learnings.
- Operator preference capture in durable files, not just chat.

## Risks / Limits

- Overgrown memory files become both costly and misleading.
- Daily logs can turn into noise if everything is recorded equally.
- Weak context discipline makes subagent work unrecoverable.

## Open Questions

- How should OpenClaw split repo memory vs. personal operator memory?
- What pruning threshold keeps context files useful here?
