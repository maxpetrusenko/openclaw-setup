# Chapter 2: OpenClaw Architecture

## Why It Matters

This chapter gives the mental model for the whole system: channel to gateway to agent to tool to world. Without this, later patterns look like magic instead of controllable infrastructure.

## Core Ideas

- Gateway is the operating center: sessions, cron, nodes, workspace, channels.
- Sessions are isolated context containers with labels and context limits.
- Tools are the action layer; policy around them matters as much as the tools themselves.
- Workspace structure is part of the product design.
- `openclaw.json`, `SOUL.md`, `AGENTS.md`, `MEMORY.md`, and `USER.md` each play different roles.
- Real requests are: ingest, load context, plan, execute tools, write memory, respond.

## Patterns To Keep

- Think in explicit pipelines, not invisible magic.
- Separate identity, memory, routing, and user preferences into different files.
- Keep workspace layout stable enough that agents can rely on it.
- Restart gateway after config changes.

## What To Adopt In OpenClaw

- Canonical docs for each control file and what belongs in it.
- Clear session labeling and worker role boundaries.
- A stable workspace map for projects, logs, data, protocols, and memory.
- Tool policy guidance near architecture docs, not buried in config trivia.

## Risks / Limits

- Too many context files can become expensive and noisy.
- Tool power without policy becomes a security and safety problem.

## Open Questions

- What exact workspace map should be standardized for this repo?
- Which files must load in every session vs. only in specialized workflows?
