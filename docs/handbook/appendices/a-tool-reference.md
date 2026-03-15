# Appendix A: Tool Reference

## Why It Matters
This is the contract surface. It defines what tools exist, what parameters they take, and where the rough edges are.

## Core Ideas
- Core tools map directly to capabilities: files, exec, browser, search, messaging, nodes, subagents.
- Tool choice matters more than model cleverness.
- Parameter discipline prevents vague prompts from becoming vague actions.

## Patterns To Keep
- Pick the lightest tool that can do the job.
- Treat tool schemas as operational contracts.
- Keep a local quick reference for frequently used tools.

## What To Adopt In OpenClaw
- Build repo docs that map common workflows to the right tool first.
- Document tool-specific failure modes next to protocol docs.

## Risks / Limits
- Tool names and parameters may drift from the handbook over time.
- Overusing heavyweight tools increases fragility and cost.

## Open Questions
- Which current OpenClaw tools differ from the handbook now?
- Should we maintain a repo-local tool cheat sheet for the team?
