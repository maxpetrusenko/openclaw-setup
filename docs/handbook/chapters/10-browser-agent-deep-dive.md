# Chapter 10: Browser Agent Deep Dive

## Why It Matters

Browser control is the escape hatch when APIs or static fetches stop working. It is also the highest-friction, highest-failure surface in the handbook, so it needs stricter operating rules than normal file or API work.

## Core Ideas

- Two browser modes:
  - `profile: "openclaw"` for clean, isolated, predictable automation.
  - `profile: "chrome"` for real logged-in sessions through the extension relay.
- Snapshot first. The accessibility snapshot is the page contract for clicks, fills, selects, and checks.
- Refs are session-local. Reloading the page invalidates old refs.
- `fill` is safer than simulated typing for forms.
- For dynamic pages, the loop is: navigate, wait, re-snapshot, extract.
- Browser sessions need lifecycle handling: auth checks, tab IDs, console errors, session expiration.
- Some sites will resist automation. If Chrome relay plus pacing still fails, prefer a real API or stop.

## Patterns To Keep

- Decision rule:
  - start with `openclaw`
  - switch to `chrome` only for auth or anti-bot pressure
- Use snapshots before every meaningful act step.
- For dynamic extraction, use page-side `evaluate` only after visible loading has settled.
- Treat console logs as first-class debugging input.
- Rate-limit scrapes and add realistic waits.
- Re-auth detection should be explicit: if snapshot shows login/session-expired UI, restart auth flow.

## What To Adopt In OpenClaw

- Browser policy doc:
  - default browser profile selection
  - when Chrome relay is allowed
  - required wait/re-snapshot rules
- Browser task template:
  - target URL
  - auth source path
  - success signal
  - extraction target path
  - fallback if blocked
- Session checklist for long browser flows:
  - auth check
  - target tab ID
  - console review on failure
  - anti-bot fallback path
- Shadow mode for side-effectful browser flows like form submission.

## Risks / Limits

- Real browser automation is brittle against UI changes.
- Chrome relay depends on a human-attached tab and extension state.
- Saved cookies are useful but not sufficient for all auth flows.
- Headless-style behavior will lose against stronger bot defenses.
- Browser jobs are expensive in time, tokens, and failure handling compared with direct APIs.

## Open Questions

- Which OpenClaw workflows truly require Chrome relay vs. API-first rewrites?
- Do we want a separate trusted worker class for browser actions with side effects?
- Where should browser session health and anti-bot failures be logged in this repo?
