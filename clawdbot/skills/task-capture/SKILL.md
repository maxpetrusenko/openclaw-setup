# Task Capture Skill

Capture task-like messages and write them to workspace memory files.

## Trigger

Use this skill when you receive a message that starts with:
- `task:`
- `todo:`
- `inbox:`

## Process

1. **Extract the task text** - Everything after the prefix, trimmed
2. **Write to active-tasks.md** - Add a task block under `## Current`
3. **Write to daily log** - Add entry to `memory/YYYY-MM-DD.md`
4. **Confirm capture** - Brief acknowledgment

## Task Block Template

```text
Task: [task text]
Owner: [sender name or "OpenClaw"]
Status: not_started
Success criteria:
Notes:
- Captured from [channel] at [timestamp]
Next action:
```

## Daily Log Template

```markdown
- [HH:MM] Task captured from [channel]: [task text]
```

## Files

- Active tasks: `memory/active-tasks.md`
- Daily log: `memory/YYYY-MM-DD.md`

## Example

Input: `task: Review the PR from John`

Output to active-tasks.md:
```text
Task: Review the PR from John
Owner: Max
Status: not_started
Success criteria:
Notes:
- Captured from telegram at 2026-02-15T09:05:00Z
Next action:
```

Output to daily log (memory/2026-02-15.md):
```markdown
- [09:05] Task captured from telegram: Review the PR from John
```
