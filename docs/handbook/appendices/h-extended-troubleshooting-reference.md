# Appendix H: Extended Troubleshooting Reference

## Why It Matters
This is the failure atlas. It turns vague breakage into named categories with checks and fixes.

## Core Ideas
- Group failures by layer: gateway, tools, cron, agents, filesystem, channels.
- Diagnosis starts with direct checks, logs, and reproductions.
- Many failures come from environment mismatch, permissions, or stale assumptions.

## Patterns To Keep
- Use layer-based troubleshooting instead of random guessing.
- Keep “check, likely cause, fix” structure.
- Add new failure modes to docs after each real incident.

## What To Adopt In OpenClaw
- Build repo troubleshooting docs in the same layered style.
- Capture exact commands for recurring checks.
- Feed resolved incidents back into durable memory.

## Risks / Limits
- Reference docs rot if not updated with real incidents.
- Teams stop reading long troubleshooting docs unless they are searchable and structured.

## Open Questions
- Which current failure classes need first-class runbooks here?
- Should we mirror this appendix into operational runbooks?
