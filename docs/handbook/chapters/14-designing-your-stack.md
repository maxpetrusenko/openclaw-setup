# Chapter 14: Designing Your Stack

## Why It Matters
This chapter is the operating philosophy. It says how to choose what to automate, what architecture to use, and how to avoid building an elaborate system around unstable work.

## Core Ideas
- Start small; automate only after the manual process is stable.
- Judge candidates by frequency, duration, consistency, and error cost.
- Match architecture to workload: simple pipeline, hub-and-spoke, gated pipeline, event-driven.
- Version-control protocols and scripts like real software.

## Patterns To Keep
- Automate routine pain first, not speculative complexity.
- Keep protocols, config, and scripts under version control.
- Use high-error-cost tasks for draft/approval workflows, not blind autonomy.

## What To Adopt In OpenClaw
- Use this chapter as the filter for every new automation request.
- Require an architecture choice before adding new flows.
- Keep `SOUL.md`, `AGENTS.md`, `MEMORY.md`, and runtime config under deliberate review.

## Risks / Limits
- The temptation is to automate prestige workflows before boring stable ones.
- A weak manual process turns into a fragile automated process.
- Architecture sprawl appears when one pattern is forced onto every workflow.

## Open Questions
- What is the first boring, stable OpenClaw loop worth automating end to end?
- Which repo artifacts should be treated as protocol files versus implementation files?
- Do we need an ADR when a new automation pattern is introduced?
