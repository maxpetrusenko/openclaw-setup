# Chapter 0: Getting Started

## Why It Matters

This chapter defines the minimum reliable install loop: install, onboard, start gateway, verify tools, then add channels. It treats workspace setup as product setup, not just local config.

## Core Ideas

- Onboarding wizard is the real setup entry point.
- Gateway is the always-on runtime and should survive terminal restarts.
- First interaction should be a simple file write to prove the full loop works.
- Messaging channels are optional at first; add them after the core path works.
- Workspace files like `SOUL.md`, `USER.md`, and `MEMORY.md` should exist early.
- A short install verification suite catches most beginner issues.

## Patterns To Keep

- Verify install with a real action, not just a version command.
- Enable channels only after local desktop or CLI flow is stable.
- Keep a lab notebook for experiments, failures, and working commands.
- Treat the workspace directory as the root of the system, not just a folder.

## What To Adopt In OpenClaw

- A local bootstrap checklist for new environments.
- A first-run smoke test that checks file write, command exec, and memory.
- A standard workspace skeleton for operator files and scripts.
- A “lab notebook” or equivalent repo note for learnings during setup.

## Risks / Limits

- Model names, ports, and exact onboarding prompts can change with releases.
- Messaging integrations add auth and QR-code fragility early in setup.
- Beginners can confuse “gateway installed” with “gateway healthy.”

## Open Questions

- What should our repo-local bootstrap checklist look like?
- Do we want a dedicated smoke-test script for local OpenClaw installs?
