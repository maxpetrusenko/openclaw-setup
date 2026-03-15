# OpenClaw Safe Compaction Design

**Date:** 2026-03-14

## Goal

Make compaction safer on Max's OpenClaw fork first, then improve long-term recall without introducing a new generic `contextEngine` slot until the fork proves the value.

## Current Fork Reality

- Compaction already has two plugin phases: `before_compaction` and `after_compaction`.
- The fork already added non-trivial compaction behavior:
  - `instinct8` sidecar mode in `src/agents/pi-embedded-runner/extensions.ts`
  - custom compaction hook types in `src/plugins/types.ts`
  - custom compaction hook wiring in `src/agents/pi-embedded-runner/compact.ts`
  - post-compaction context injection and read-audit in `src/auto-reply/reply/agent-runner.ts`
- Because these seams already exist, introducing a second new abstraction first would increase risk.

## Constraints

- Safer compaction is the primary objective.
- Long-term memory still matters, but must not destabilize compaction.
- The repo has local fork drift; stock OpenClaw assumptions are not enough.
- The first iteration should be easy to disable.

## Decision

Use a layered hybrid:

1. Add safety instrumentation and replay evaluation around the current compaction flow.
2. Harden the current flow with a guarded, opt-in safe compaction mode.
3. Improve retention through existing post-compaction and memory seams.
4. Generalize into a first-class `contextEngine` slot only if the measured gains justify more core surgery.

## Why This Order

### Why not port `lossless-claw` directly first

- The upstream plugin expects a `contextEngine` slot that this fork does not have.
- The fork already has its own compaction extensions and hook wiring.
- A direct port would blur whether failures come from the plugin logic or from our existing custom seams.

### Why not build the generic slot first

- Broad config and plugin-surface changes before proof would raise blast radius.
- We already have enough seam surface to run an honest experiment without committing to a new platform API.

## Phase Shape

### Phase 1. Baseline + observability

- Keep current behavior.
- Measure compaction start/end, retries, failures, duration, token deltas, and post-compaction continuation.
- Build a replay set from real OpenClaw transcripts.

### Phase 2. Safe compaction mode

- Add an opt-in mode behind an environment flag first.
- Guard the existing `before_compaction` rewrite path with extra validation and diagnostics.
- Tighten post-compaction rehydration and audit behavior.

### Phase 3. Retention improvements on existing seams

- Improve what survives compaction through:
  - better post-compaction workspace rehydration
  - durable fact/task extraction through existing memory paths
  - better use of compaction metadata already available in hooks and transcripts

### Phase 4. Generalize only if earned

- If replay and live usage show meaningful wins with no safety regressions, extract a reusable `contextEngine` seam.

## Measurement

The experiment should compare `baseline` vs `safe_compaction_v1` on the same replay set.

### Required metrics

- compaction failure rate
- compaction timeout rate
- compaction retry count
- compaction wall-clock time
- token delta before/after compaction
- post-compaction task continuation success
- fact retention score
- session corruption / ordering regressions

### Success bar

- no new corruption or role-ordering regressions
- lower or equal compaction failure rate
- lower or equal timeout rate
- improved continuation after compaction
- measurable fact-retention gain
- rollback possible with one flag

## Initial Config / Rollout Decision

Use an environment flag for the first spike:

- `OPENCLAW_SAFE_COMPACTION_V1=1`

Reason:

- no schema churn during the first proof
- easy A/B comparison
- easy rollback

Promote to config only after the replay harness shows a win.

## Main Files To Touch

- `oss/openclaw/src/agents/pi-embedded-runner/compact.ts`
- `oss/openclaw/src/agents/pi-embedded-runner/extensions.ts`
- `oss/openclaw/src/plugins/types.ts`
- `oss/openclaw/src/plugins/hooks.ts`
- `oss/openclaw/src/auto-reply/reply/agent-runner.ts`
- `oss/openclaw/src/auto-reply/reply/post-compaction-context.ts`
- `oss/openclaw/src/auto-reply/reply/post-compaction-audit.ts`
- `oss/openclaw/src/auto-reply/reply/agent-runner-memory.ts`

## Main Risks

- duplicate compaction logic between baseline, hook path, and `instinct8`
- hook-based rewrite returns invalid message shapes
- post-compaction context injection fights with memory flush behavior
- replay harness underfits real sessions if fixtures are synthetic

## Non-Goals For The First Spike

- no generic `contextEngine` slot
- no new remote service requirement beyond existing `instinct8` sidecar support
- no production rollout before replay and local verification
