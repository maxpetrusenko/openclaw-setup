# Chapter 3: File & Code Automation

## Why It Matters

Files are the durable substrate of the whole system. This chapter makes clear that reliable automation is mostly careful file IO, code generation, and controlled shell execution.

## Core Ideas

- `read`, `write`, and `edit` each have distinct safety and scaling characteristics.
- `edit` is safe because matching is exact, but that also makes it brittle to stale context.
- `exec` is the real power tool and should be policy-restricted.
- Background processes need explicit process management.
- Batch operations and file pipelines are where automation starts compounding value.
- Always test a file pipeline manually before cron.

## Patterns To Keep

- Read fresh before editing.
- Use scripts for heavy CSV or JSON transforms rather than forcing huge inline prompts.
- Treat generated scripts as versioned assets, not disposable output.
- Build pipelines with explicit input, output, and failure handling.

## What To Adopt In OpenClaw

- Strong guidance for when to use files vs. scripts vs. direct shell.
- Exec allowlists for trusted workers.
- Pipeline templates that require manual test before schedule.
- Standard troubleshooting for path, permissions, binary files, and large file handling.

## Risks / Limits

- Exact-match edits fail often if agents rely on stale file content.
- Overpowered exec policies are a major blast-radius multiplier.
- Large file reads and long shell jobs need explicit chunking or backgrounding.

## Open Questions

- Which shell commands should be allowlisted by default here?
- What pipeline template should every scheduled file transform follow?
