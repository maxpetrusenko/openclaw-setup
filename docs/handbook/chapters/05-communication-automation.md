# Chapter 5: Communication Automation

## Why It Matters

Communication is where automation becomes visible to the operator. This chapter shows that routing and alert discipline matter more than raw send capability.

## Core Ideas

- Message tooling is simple; the real work is formatting, channel choice, and noise control.
- WhatsApp is both output surface and inbound command surface.
- Keyword routing in `SOUL.md` turns messaging into remote control.
- TTS is useful for accessibility and hands-free alerts.
- Alerting should be severity-based and quiet-hour aware.
- A communication hub should prefer proactive silence over spam.

## Patterns To Keep

- Severity levels with channel routing.
- Draft-only for outbound messages to third parties.
- Inbound command routing for a small set of high-value verbs.
- Quiet hours unless critical.
- Keep secrets and PII out of messages and logs.

## What To Adopt In OpenClaw

- Alert protocol doc with severity, quiet hours, and allowed channels.
- Outbound message audit logs.
- Small command grammar for inbound control messages.
- “Draft first” rule for anything reputation-bearing.

## Risks / Limits

- Messaging channels are third-party storage surfaces.
- Alert fatigue destroys the value of alerts quickly.
- Inbound command flows can become a security issue if sender policy is weak.

## Open Questions

- What are the three most useful inbound commands for Max?
- Which channels should exist in v1 beyond the desktop surface?
