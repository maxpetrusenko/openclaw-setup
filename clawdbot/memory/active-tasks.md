# Active Tasks (Crash Recovery)

Read this first at the start of a session. This is "save game".

## Current

```text
Task: MAX-15 Capture tasks from Telegram into memory/active-tasks.md + daily log
Owner: OpenClaw (main)
Status: done
Success criteria:
- Task-like Telegram messages reliably update `memory/active-tasks.md`
- Also append a short entry to today's `memory/YYYY-MM-DD.md`
Notes:
- Linear: MAX-15
- Implemented via skill + script at tools/memory/capture-task.sh
- Skill at skills/task-capture/SKILL.md
- Trigger prefixes: task:, todo:, inbox:
Next action:
- Done - task capture working
```

```text
Task: MAX-16 Create missing daily memory files automatically (today + yesterday)
Owner: OpenClaw (main)
Status: done
Success criteria:
- If today's `memory/YYYY-MM-DD.md` is missing, create it automatically
- Ensure digests always have a place to write
Notes:
- Linear: MAX-16
- Script at tools/memory/ensure-daily.sh
- Cron job "Ensure Daily Memory Files" runs at 6 AM ET
Next action:
- Done - daily files auto-created via cron
```

```text
Task: MAX-12 [southfloridaqigong] Add service landing pages + FAQs and expand sitemap.xml
Owner: Max + OpenClaw
Status: review
Success criteria:
- Add service pages + FAQ content
- Update `public/sitemap.xml`
- Keep hreflang + internal linking correct
Notes:
- Repo: maxpetrusenko/southfloridaqigong
- Linear: MAX-12
- PR: https://github.com/maxpetrusenko/southfloridaqigong/pull/1
Next action:
- Awaiting review/merge
```

## Template

Copy/paste for new tasks:

```text
Task:
Owner:
Status: not_started | in_progress | blocked | done
Success criteria:
Notes:
Related sessions/ids:
Next action:
```
