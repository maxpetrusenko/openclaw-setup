---
summary: "Heartbeat checklist (keep short to reduce token burn)"
read_when:
  - Heartbeat poll
---

# HEARTBEAT.md

- Read `memory/active-tasks.md`. If stale/incomplete, update it first.
- Read `docs/openclaw-handbook-protocol.md` if this heartbeat is tied to automation, routing, browser, cron, or messaging work.
- Quick health: `openclaw channels status --probe` (only if it won't spam).
- Check cron status quickly (should be quiet unless something is broken).
- Check whether any active task is blocked at a gate or missing an artifact.
- If nothing actionable: reply `HEARTBEAT_OK`.
