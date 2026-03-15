# Chapter 15: Troubleshooting & Optimization

## Why It Matters
Automation trust is mostly a debugging problem. If failures are opaque, the system becomes superstition. This chapter makes observability, verification, cost, and security part of normal operation.

## Core Ideas
- Most failures are mundane: gateway, paths, permissions, bad prompts, stale state.
- Debugging starts with reproduction and direct inspection, not theory.
- Performance and cost are context-management problems as much as model problems.
- Security hardening means least privilege, validation, and careful treatment of side effects.

## Patterns To Keep
- Add logs, canaries, and explicit completion markers everywhere.
- Reproduce failing steps manually before “fixing” them abstractly.
- Keep context files tight to control cost and confusion.
- Verify external facts with tools instead of trusting model claims.

## What To Adopt In OpenClaw
- Build troubleshooting checklists into protocol docs, not tribal memory.
- Require instrumentation for cron jobs, browser flows, and escalations.
- Track common failure patterns in durable memory so the system gets sharper.

## Risks / Limits
- Without logs, every failure looks like “AI weirdness.”
- Optimization too early can erase clarity.
- Security shortcuts in operator tools have large blast radius.

## Open Questions
- Which top failure modes already show up in this repo?
- What minimum telemetry belongs in every automation?
- Which cost/security rules need to be enforced by policy rather than prompt?
