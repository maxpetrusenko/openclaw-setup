# OpenClaw Safe Compaction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Harden compaction on this OpenClaw fork first, then improve long-term recall using existing retention seams, with measured rollback-safe rollout.

**Architecture:** Build around the fork's current compaction flow instead of inventing a new platform slot first. Add instrumentation and replay evaluation, introduce a guarded opt-in safe compaction mode behind an environment flag, then improve post-compaction rehydration and durable memory capture before deciding whether to extract a generic `contextEngine` API.

**Tech Stack:** TypeScript, Vitest, OpenClaw embedded runner, plugin hooks, Markdown docs, local replay fixtures/scripts

---

### Task 1: Freeze the baseline and compaction seam coverage

**Files:**
- Modify: `oss/openclaw/src/plugins/wired-hooks-compaction.test.ts`
- Modify: `oss/openclaw/src/plugins/hooks.before-compaction.test.ts`
- Modify: `oss/openclaw/src/agents/pi-embedded-runner/extensions.test.ts`
- Create: `oss/openclaw/src/agents/pi-embedded-runner/compact.safe-baseline.test.ts`

**Step 1: Add a failing baseline test for the current compaction branch points**

Cover:
- default compaction path
- `before_compaction` replacement path
- `after_compaction` fire-and-forget path
- `instinct8` mode selection

Add assertions for:
- pre-hook token count passed into hooks
- `compactedCount` shape
- hook failure logging behavior

**Step 2: Run the new focused tests**

Run:

```bash
pnpm vitest run \
  oss/openclaw/src/plugins/wired-hooks-compaction.test.ts \
  oss/openclaw/src/plugins/hooks.before-compaction.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/extensions.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.safe-baseline.test.ts
```

Expected: at least one new assertion fails before implementation.

**Step 3: Commit**

```bash
committer "test: freeze compaction seam coverage" \
  oss/openclaw/src/plugins/wired-hooks-compaction.test.ts \
  oss/openclaw/src/plugins/hooks.before-compaction.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/extensions.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.safe-baseline.test.ts
```

### Task 2: Extract structured compaction diagnostics

**Files:**
- Create: `oss/openclaw/src/agents/pi-embedded-runner/compaction-diagnostics.ts`
- Create: `oss/openclaw/src/agents/pi-embedded-runner/compaction-diagnostics.test.ts`
- Modify: `oss/openclaw/src/agents/pi-embedded-runner/compact.ts`

**Step 1: Write a failing diagnostics helper test**

Test helpers for:
- `summarizeCompactionMessages`
- `estimateCompactionTokenCount`
- `buildCompactionStartDiag`
- `buildCompactionEndDiag`

Cover:
- tool-result-heavy transcripts
- missing token estimates
- plugin-owned compaction outcome
- retry vs non-retry paths

**Step 2: Move inline diagnostics out of `compact.ts`**

Extract the current message/token summary logic into `compaction-diagnostics.ts`.

Keep the output shape stable:

```ts
type CompactionDiag = {
  diagId: string;
  runId: string;
  sessionKey: string;
  outcome: "compacted" | "plugin_compacted" | "failed" | "skipped";
  trigger: "overflow" | "manual";
  durationMs?: number;
  retrying: boolean;
  pre: { messages: number; estTokens?: number };
  post?: { messages: number; estTokens?: number };
};
```

**Step 3: Re-run focused diagnostics tests**

Run:

```bash
pnpm vitest run \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-diagnostics.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.safe-baseline.test.ts
```

Expected: PASS.

**Step 4: Commit**

```bash
committer "refactor: extract compaction diagnostics" \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-diagnostics.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-diagnostics.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.ts
```

### Task 3: Add an opt-in safe compaction flag

**Files:**
- Create: `oss/openclaw/src/agents/pi-embedded-runner/compaction-safe-mode.ts`
- Create: `oss/openclaw/src/agents/pi-embedded-runner/compaction-safe-mode.test.ts`
- Modify: `oss/openclaw/src/agents/pi-embedded-runner/compact.ts`
- Modify: `oss/openclaw/src/agents/pi-embedded-runner/extensions.ts`

**Step 1: Write failing tests for flag parsing and routing**

Support:

```ts
OPENCLAW_SAFE_COMPACTION_V1=1
```

Expected behavior:
- flag off: current behavior unchanged
- flag on: safe validation branch enabled
- `instinct8` mode still wins when explicitly configured

**Step 2: Implement the flag helper**

Minimal helper:

```ts
export function isSafeCompactionEnabled(env = process.env): boolean {
  return ["1", "true", "yes"].includes(String(env.OPENCLAW_SAFE_COMPACTION_V1).toLowerCase());
}
```

**Step 3: Route `compact.ts` through a guarded validation branch**

When the flag is enabled and `before_compaction` returns replacement messages:
- validate array shape
- reject empty or obviously malformed replacement sets
- record explicit diagnostics on rejection
- fall back to normal compaction instead of trusting bad plugin output

**Step 4: Run focused tests**

Run:

```bash
pnpm vitest run \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-safe-mode.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.safe-baseline.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/extensions.test.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
committer "feat: add safe compaction feature flag" \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-safe-mode.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-safe-mode.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.ts \
  oss/openclaw/src/agents/pi-embedded-runner/extensions.ts
```

### Task 4: Tighten post-compaction rehydration and audit

**Files:**
- Modify: `oss/openclaw/src/auto-reply/reply/agent-runner.ts`
- Modify: `oss/openclaw/src/auto-reply/reply/post-compaction-context.ts`
- Modify: `oss/openclaw/src/auto-reply/reply/post-compaction-audit.ts`
- Create: `oss/openclaw/src/auto-reply/reply/post-compaction-hardened.test.ts`

**Step 1: Write failing tests for the current rehydration blind spots**

Cover:
- missing `AGENTS.md`
- session marked for audit but transcript file unavailable
- rehydration event duplicated more than once
- required reads missing after compaction

**Step 2: Implement one-shot, bounded rehydration**

Keep best-effort semantics, but make behavior deterministic:
- enqueue at most one rehydration event per compaction cycle
- include compaction count or session key in the internal marker
- keep truncation bound explicit

**Step 3: Expand audit rules carefully**

Default audit should still stay lightweight. Add only high-signal reads:
- `AGENTS.md` when present
- daily memory file pattern
- existing `WORKFLOW_AUTO.md` requirement

**Step 4: Run focused tests**

Run:

```bash
pnpm vitest run \
  oss/openclaw/src/auto-reply/reply/post-compaction-context.test.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-audit.test.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-hardened.test.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
committer "fix: harden post-compaction rehydration" \
  oss/openclaw/src/auto-reply/reply/agent-runner.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-context.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-audit.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-hardened.test.ts
```

### Task 5: Add replay evaluation harness

**Files:**
- Create: `oss/openclaw/scripts/evals/safe-compaction-replay.ts`
- Create: `oss/openclaw/scripts/evals/fixtures/compaction/README.md`
- Create: `oss/openclaw/scripts/evals/fixtures/compaction/*.json`
- Create: `oss/openclaw/src/agents/pi-embedded-runner/compaction-replay.test.ts`

**Step 1: Define fixture format**

Use a simple JSON shape:

```json
{
  "name": "tool-heavy-telegram-thread",
  "sessionKey": "telegram:dm:test",
  "messages": [],
  "expected": {
    "mustRetain": ["repo path", "active goal"],
    "mustNotBreak": ["tool ordering", "post-compaction audit"]
  }
}
```

**Step 2: Add the replay runner**

The runner should:
- load fixtures
- run baseline and safe mode
- capture metrics JSON
- print a diff summary

**Step 3: Add one assertion-backed replay test**

At least one fixture should run in Vitest and assert:
- no malformed replacement messages
- compaction completes
- continuation prompt still includes required retained facts

**Step 4: Run the replay test and script dry-run**

Run:

```bash
pnpm vitest run oss/openclaw/src/agents/pi-embedded-runner/compaction-replay.test.ts
pnpm exec tsx oss/openclaw/scripts/evals/safe-compaction-replay.ts
```

Expected:
- test PASS
- script prints baseline vs safe summary without mutating prod config

**Step 5: Commit**

```bash
committer "test: add safe compaction replay harness" \
  oss/openclaw/scripts/evals/safe-compaction-replay.ts \
  oss/openclaw/scripts/evals/fixtures/compaction/README.md \
  oss/openclaw/scripts/evals/fixtures/compaction \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-replay.test.ts
```

### Task 6: Improve long-term recall using existing memory seams

**Files:**
- Modify: `oss/openclaw/src/auto-reply/reply/agent-runner-memory.ts`
- Modify: `oss/openclaw/src/auto-reply/reply/agent-runner.ts`
- Modify: `oss/openclaw/docs/concepts/memory.md`
- Create: `oss/openclaw/src/auto-reply/reply/agent-runner-memory.safe-retention.test.ts`

**Step 1: Write failing tests for durable fact capture around compaction**

Cover:
- compaction completed and memory flush metadata updated
- safe mode emits retention metadata once
- no extra writes when session is read-only or heartbeat-driven

**Step 2: Add a low-risk retention handoff**

Use existing memory flush/session metadata instead of a new platform seam:
- persist minimal compaction retention hints
- reuse session entry metadata already updated after compaction
- avoid a new remote dependency

**Step 3: Document the new behavior**

Update memory docs to explain:
- safe compaction mode
- replay evaluation
- retention metadata behavior

**Step 4: Run tests**

Run:

```bash
pnpm vitest run \
  oss/openclaw/src/auto-reply/reply/agent-runner-memory.safe-retention.test.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-hardened.test.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
committer "feat: improve safe retention after compaction" \
  oss/openclaw/src/auto-reply/reply/agent-runner-memory.ts \
  oss/openclaw/src/auto-reply/reply/agent-runner.ts \
  oss/openclaw/src/auto-reply/reply/agent-runner-memory.safe-retention.test.ts \
  oss/openclaw/docs/concepts/memory.md
```

### Task 7: Verify the full safety-first slice

**Files:**
- Verify only

**Step 1: Run the focused gate**

Run:

```bash
pnpm vitest run \
  oss/openclaw/src/plugins/wired-hooks-compaction.test.ts \
  oss/openclaw/src/plugins/hooks.before-compaction.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/extensions.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compact.safe-baseline.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-diagnostics.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-safe-mode.test.ts \
  oss/openclaw/src/agents/pi-embedded-runner/compaction-replay.test.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-context.test.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-audit.test.ts \
  oss/openclaw/src/auto-reply/reply/post-compaction-hardened.test.ts \
  oss/openclaw/src/auto-reply/reply/agent-runner-memory.safe-retention.test.ts
```

Expected: PASS.

**Step 2: Run the replay summary**

Run:

```bash
pnpm exec tsx oss/openclaw/scripts/evals/safe-compaction-replay.ts
```

Record:
- failure count
- timeout count
- continuation score
- retention score
- median duration delta

**Step 3: Decide rollout**

Only enable `OPENCLAW_SAFE_COMPACTION_V1=1` outside tests if:
- replay shows no safety regressions
- continuation is equal or better
- retention is equal or better

### Task 8: Optional Phase 2 follow-up only after proof

**Files:**
- Future work only

If Tasks 1-7 succeed, then decide whether to start a separate design for:
- promoting the environment flag to formal config
- extracting a generic `contextEngine` plugin slot

Do not mix that broader platform work into this first implementation slice.
