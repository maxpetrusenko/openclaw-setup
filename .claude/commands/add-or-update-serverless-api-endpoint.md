---
name: add-or-update-serverless-api-endpoint
description: Workflow command scaffold for add-or-update-serverless-api-endpoint in openclaw-setup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-update-serverless-api-endpoint

Use this workflow when working on **add-or-update-serverless-api-endpoint** in `openclaw-setup`.

## Goal

Adds or updates a serverless API endpoint, often for integrations (e.g., Notion, Resend), and updates related documentation.

## Common Files

- `api/waitlist.ts`
- `api/CLAUDE.md`
- `.gitignore`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Edit or create the endpoint implementation file (e.g., api/waitlist.ts).
- Update or create related documentation (e.g., api/CLAUDE.md).
- Update configuration or ignore files if needed (e.g., .gitignore).

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.