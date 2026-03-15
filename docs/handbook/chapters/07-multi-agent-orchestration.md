# Chapter 7: Multi-Agent Orchestration

## Why It Matters

This chapter is the control-plane core. It explains how router, worker roles, handoffs, gates, and escalation turn many agents from chaos into a factory.

## Core Ideas

- Single agents fail on context, parallelism, specialization, and reliability.
- Main router should route, validate, and communicate; leads and workers do the work.
- `AGENTS.md` defines roles, routing, gates, escalation, and memory protocol.
- Handoffs must name artifacts and success criteria explicitly.
- RALPH prevents endless retries and silent garbage propagation.
- Sub-agents need strict scope, explicit outputs, and stopping conditions.

## Patterns To Keep

- Main agent does routing, not labor.
- Parallel workers only for cleanly separable tasks.
- Gate files before phase transitions.
- Retry once, then escalate on repeated same failure.
- Validate artifacts, not subagent claims.

## What To Adopt In OpenClaw

- Router-centered control plane.
- Named leads for research, planning or implementation, testing, and ops.
- Canonical handoff message format.
- RALPH section in root `AGENTS.md`.
- Explicit “only do X” constraints in worker tasks.

## Risks / Limits

- Multi-agent systems amplify coordination mistakes.
- Parallelism without artifact discipline creates ghost work and stale outputs.
- Leads can become bottlenecks if routing rules are vague.

## Open Questions

- Which lead roles should exist in v1?
- What is the exact retry threshold and escalation message format for this repo?
