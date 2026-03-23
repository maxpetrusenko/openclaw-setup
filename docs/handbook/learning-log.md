# Handbook Learning Log

Use this file for durable deltas only.

Template:
- Date:
- Source note:
- Learning:
- Why it matters here:
- Follow-up:

## 2026-03-14

- Date: 2026-03-14
- Source note: `docs/handbook/chapters/14-designing-your-stack.md`
- Learning: Stable, frequent, low-to-medium risk loops should be automated first. Unstable or high-error-cost flows should stay draft-first.
- Why it matters here: This reinforces `internal single-tenant operator first` and argues against premature multi-tenant SaaS scope.
- Follow-up: Create an automation intake rubric before adding new control-plane workflows.

- Date: 2026-03-14
- Source note: `docs/handbook/chapters/11-business-automation.md`
- Learning: Project artifacts and stage gates are the backbone of trustworthy multi-agent work.
- Why it matters here: OpenClaw already has many primitives; the missing layer is standardized artifact flow and gate enforcement.
- Follow-up: Define the canonical project artifact tree for this repo.

- Date: 2026-03-14
- Source note: `docs/handbook/chapters/10-browser-agent-deep-dive.md`
- Learning: Browser automation must be policy-driven: default isolated profile, Chrome relay only when justified, API fallback when resistance is high.
- Why it matters here: Browser workers need stronger trust boundaries than read-only or API-only workers.
- Follow-up: Draft a browser worker trust policy and shadow-mode submission rules.

- Date: 2026-03-14
- Source note: `docs/handbook/chapters/15-troubleshooting-and-optimization.md`
- Learning: Most failures are operational and should be diagnosed with logs, manual reproduction, and monthly audits rather than prompt tweaking.
- Why it matters here: A control plane without observability will feel intelligent but remain unreliable.
- Follow-up: Add monthly audit and debug checklist docs.
