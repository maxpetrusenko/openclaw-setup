---
name: add-or-update-ops-script-with-tdd
description: Workflow command scaffold for add-or-update-ops-script-with-tdd in openclaw-setup.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-update-ops-script-with-tdd

Use this workflow when working on **add-or-update-ops-script-with-tdd** in `openclaw-setup`.

## Goal

Adds or updates an operational shell script (for staging, reporting, snapshot, etc.) with corresponding test script for TDD verification.

## Common Files

- `ops/*.sh`
- `tests/*.test.sh`
- `ops/lib/openclaw-host.sh`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create or update an ops script in ops/ (e.g., ops/oc-stage-up.sh, ops/oc-snapshot.sh).
- Create or update a corresponding test script in tests/ (e.g., tests/oc-stage-up.test.sh, tests/oc-snapshot.test.sh).
- Optionally update shared libraries (e.g., ops/lib/openclaw-host.sh) if needed.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.