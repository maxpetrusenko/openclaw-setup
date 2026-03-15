# Daily Report: 2026-03-15

## Status

OpenClaw: Unknown or degraded
Extensions: 5

## Work Done

No meaningful activity.

## Risks

No critical risks identified.

## Next

Routine monitoring.

---

## Raw Data

```
│
◇  Config ───────────────────────────────────────────────────╮
│                                                            │
│  Config invalid; doctor will run with best-effort config.  │
│                                                            │
├────────────────────────────────────────────────────────────╯
│
◇  Doctor changes ────────────────────────╮
│                                         │
│  Telegram configured, not enabled yet.  │
│  WhatsApp configured, not enabled yet.  │
│                                         │
├─────────────────────────────────────────╯
│
◇  Unknown config keys ──────────────────────────────────────────╮
│                                                                │
│  - channels.telegram.streaming                                 │
│  - gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback  │
│                                                                │
├────────────────────────────────────────────────────────────────╯
│
◇  Doctor ──────────────────────────────────────────────╮
│                                                       │
│  Run "openclaw doctor --fix" to apply these changes.  │
│  Run "openclaw doctor --fix" to remove these keys.    │
│                                                       │
├───────────────────────────────────────────────────────╯
{
  "heartbeat": {
    "defaultAgentId": "main",
    "agents": [
      {
        "agentId": "main",
        "enabled": true,
        "every": "30m",
        "everyMs": 1800000
      },
      {
        "agentId": "xposter",
        "enabled": false,
        "every": "disabled",
        "everyMs": null
      }
    ]
  },
  "channelSummary": [],
  "queuedSystemEvents": [],
  "sessions": {
    "paths": [
      "/data/.openclaw/agents/main/sessions/sessions.json",
```
