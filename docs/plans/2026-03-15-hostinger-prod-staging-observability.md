# Hostinger Prod Staging Observability Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Hostinger the only live OpenClaw runtime, add a disposable staging clone on the same VPS, keep OpenClaw source-update work local, and add enough observability plus short daily reporting to inspect installs, health, recent activity, and safe rollback without modifying OpenClaw internals.

**Architecture:** Keep one prod container and one optional staging container on the same Hostinger VPS. Persist prod state on the VPS, create staging by copying prod state into a separate host path, and manage both through small shell scripts in `ops/`. Keep OpenClaw source updates and source-level tests local in the current repo root `.`. Observability comes from inspecting Docker metadata, mounted state, OpenClaw CLI status/health, extension directories, session files, logs, and one short daily CTO-style report written into a folder-as-workspace structure.

**Tech Stack:** Bash, Docker, Docker Compose, SSH, OpenClaw CLI, Markdown docs, folder-as-workspace reporting

---

## Constraints

- Do not modify OpenClaw internals.
- Do not rely on bidirectional sync of `.openclaw`.
- Do not require a local OpenClaw runtime.
- Do keep OpenClaw source-update work and source tests local in repo root `.` before any prod deploy.
- Keep rollback simple: previous image tag + untouched prod state.
- Staging must be safe to destroy and recreate from prod.
- Daily report must be short. If nothing meaningful happened, say so plainly in a few lines.

## Operating lanes

### Lane 1: Local source-update lane

- Repo root `.` is the place for OpenClaw update plans, source edits, and local tests.
- This lane exists only when you are changing OpenClaw itself.
- Nothing in this lane should mutate Hostinger automatically.

### Lane 2: Hostinger runtime lane

- Hostinger prod container is the only live OpenClaw runtime.
- Hostinger staging container is a disposable clone for plugin/config experiments.
- No bidirectional sync of `.openclaw` back to local.

### Lane 3: Daily report lane

- Generate one short CTO-style daily report from prod-visible activity.
- Use a folder-as-workspace structure inspired by the layered map/context/workspace approach.
- Keep reports readable as plain Markdown and easy to inspect from the filesystem.

## Deliverables

- `ops/oc-snapshot.sh`
- `ops/oc-stage-clone.sh`
- `ops/oc-stage-up.sh`
- `ops/oc-stage-smoke.sh`
- `ops/oc-stage-down.sh`
- `ops/oc-daily-report.sh`
- `tests/oc-snapshot.test.sh`
- `tests/oc-stage-clone.test.sh`
- `tests/oc-stage-up.test.sh`
- `tests/oc-daily-report.test.sh`
- `docs/vps-migration.md` updates for prod vs staging workflow
- `docs/quickstart.md` updates for observability and staging workflow
- `docs/handbook/openclaw-reporting-workspace.md`

## Reporting workspace shape

Use a BMAD-style folder workspace shape: top-level map, per-feature folders, short Markdown artifacts, no giant monolith.

```text
reports/openclaw-daily/
  YYYY-MM-DD/
    overview.md
    features/
      <feature-slug>/
        overview.md
        research/
          web.md
          reddit.md
        planning/
          notes.md
        writing/
          v1/
            article.md
            images.md
            overview-rating.md
```

Rules:
- `overview.md` is the CTO-style summary for the day. Keep it short.
- Create feature folders only when there was meaningful work.
- If there was no meaningful work, write only the top-level `overview.md`.
- Prefer plain facts: what happened, what broke, what is risky, what is next.

## Task 0: Write the operating model and report blueprint

**Files:**
- Create: `docs/handbook/openclaw-reporting-workspace.md`
- Modify: `docs/plans/2026-03-15-hostinger-prod-staging-observability.md`

**Step 1: Write the blueprint doc**

Document:
- local source-update lane
- Hostinger prod lane
- Hostinger staging lane
- daily report lane
- the folder layout for daily reports
- naming rules for feature slugs and report files

**Step 2: Verify the doc is specific**

Run:

```bash
rg -n "Lane 1|Lane 2|Lane 3|reports/openclaw-daily|overview.md" docs/handbook/openclaw-reporting-workspace.md
```

Expected: the blueprint includes the separation model and report structure.

**Step 3: Commit**

```bash
git add docs/handbook/openclaw-reporting-workspace.md docs/plans/2026-03-15-hostinger-prod-staging-observability.md
git commit -m "docs: define hostinger operating lanes and reporting workspace"
```

## Task 1: Record the live Hostinger shape first

**Files:**
- Create: `docs/handbook/hostinger-openclaw-current-state.md`
- Use: `ops/vps-openclaw.sh`

**Step 1: Capture the live container inventory**

Run:

```bash
ssh -i "$HOME/.ssh/hostinger_agent" -o StrictHostKeyChecking=accept-new root@187.77.7.226 \
  "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
```

Expected: the currently serving OpenClaw container names and image references are visible.

**Step 2: Capture mounts, version, and state paths**

Run:

```bash
ssh -i "$HOME/.ssh/hostinger_agent" -o StrictHostKeyChecking=accept-new root@187.77.7.226 \
  "docker inspect openclaw-ylld-openclaw-1 --format '{{json .Mounts}}' && \
   docker exec openclaw-ylld-openclaw-1 openclaw --version && \
   docker exec openclaw-ylld-openclaw-1 sh -lc 'ls -la /data/.openclaw && find /data/.openclaw/extensions -maxdepth 2 -type d | sort'"
```

Expected: host mount path, runtime version, and extension directories are captured.

**Step 3: Write the current-state doc**

Write:
- active prod container name
- active image/tag
- host mount paths
- session/config/extension paths
- stale plugin records already known
- whether staging already exists
- where daily reports should live on the VPS

**Step 4: Commit the doc**

```bash
git add docs/handbook/hostinger-openclaw-current-state.md
git commit -m "docs: record hostinger openclaw current state"
```

## Task 2: Add one shared Hostinger ops helper

**Files:**
- Create: `ops/lib/openclaw-host.sh`
- Modify: `ops/oc-snapshot.sh`
- Modify: `ops/oc-stage-clone.sh`
- Modify: `ops/oc-stage-up.sh`
- Modify: `ops/oc-stage-smoke.sh`
- Modify: `ops/oc-stage-down.sh`

**Step 1: Write the failing shell contract**

Create a minimal helper contract in a test by asserting scripts inherit:
- `OPENCLAW_VPS_HOST`
- `OPENCLAW_VPS_USER`
- `OPENCLAW_VPS_KEY`
- `OPENCLAW_PROD_CONTAINER`
- `OPENCLAW_STAGE_CONTAINER`

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-snapshot.test.sh
```

Expected: FAIL because shared helper does not exist yet.

**Step 3: Write minimal helper**

Create `ops/lib/openclaw-host.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
USER_NAME="${OPENCLAW_VPS_USER:-root}"
KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
PROD_CONTAINER="${OPENCLAW_PROD_CONTAINER:-openclaw-ylld-openclaw-1}"
STAGE_CONTAINER="${OPENCLAW_STAGE_CONTAINER:-openclaw-stage-1}"

ssh_host() {
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "${USER_NAME}@${HOST}" "$@"
}
```

**Step 4: Re-run the test**

Run:

```bash
bash tests/oc-snapshot.test.sh
```

Expected: PASS or advance to the next missing behavior.

**Step 5: Commit**

```bash
git add ops/lib/openclaw-host.sh tests/oc-snapshot.test.sh
git commit -m "feat: add shared hostinger ops helper"
```

## Task 3: Build the prod observability snapshot

**Files:**
- Create: `ops/oc-snapshot.sh`
- Create: `tests/oc-snapshot.test.sh`

**Step 1: Write the failing test**

Test must assert the script prints these sections:
- `container`
- `version`
- `mounts`
- `extensions on disk`
- `configured plugin records`
- `openclaw status`
- `openclaw health`
- `recent sessions`
- `recent logs`

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-snapshot.test.sh
```

Expected: FAIL because `ops/oc-snapshot.sh` does not exist.

**Step 3: Write minimal implementation**

Use this shape:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/openclaw-host.sh"

C="${1:-$PROD_CONTAINER}"

ssh_host "
  docker ps --filter 'name=$C' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
  docker exec $C openclaw --version || true
  docker inspect $C --format '{{range .Mounts}}{{println .Source \"->\" .Destination}}{{end}}'
  docker exec $C sh -lc 'find /data/.openclaw/extensions -maxdepth 2 -mindepth 1 -type d | sort' || true
  docker exec $C sh -lc 'grep -n \"lossless-claw\\|instinct8\\|bmad\" /data/.openclaw/openclaw.json || true'
  docker exec $C openclaw status --json || true
  docker exec $C openclaw health --json || true
  docker exec $C sh -lc 'find /data/.openclaw/agents -name sessions.json -print -exec ls -l {} \\;' || true
  docker logs --tail 120 $C 2>&1 || true
"
```

**Step 4: Run the test**

Run:

```bash
bash tests/oc-snapshot.test.sh
```

Expected: PASS.

**Step 5: Smoke the real prod container**

Run:

```bash
./ops/oc-snapshot.sh
```

Expected: real Hostinger snapshot prints without mutating prod.

**Step 6: Commit**

```bash
git add ops/oc-snapshot.sh tests/oc-snapshot.test.sh
git commit -m "feat: add hostinger openclaw snapshot"
```

## Task 4: Build staging clone from prod state

**Files:**
- Create: `ops/oc-stage-clone.sh`
- Create: `tests/oc-stage-clone.test.sh`

**Step 1: Write the failing test**

Assert the script:
- stops if staging container already exists unless `--force`
- copies prod state to a separate host path
- never mutates prod path

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-stage-clone.test.sh
```

Expected: FAIL because clone script does not exist.

**Step 3: Write minimal implementation**

Use separate defaults:

```bash
PROD_STATE_DIR="${OPENCLAW_PROD_STATE_DIR:-/docker/openclaw-ylld/data}"
STAGE_STATE_DIR="${OPENCLAW_STAGE_STATE_DIR:-/docker/openclaw-stage/data}"
```

Core behavior:

```bash
ssh_host "
  test -d '$PROD_STATE_DIR/.openclaw'
  mkdir -p '$STAGE_STATE_DIR'
  rm -rf '$STAGE_STATE_DIR/.openclaw'
  cp -a '$PROD_STATE_DIR/.openclaw' '$STAGE_STATE_DIR/.openclaw'
  chmod -R go-rwx '$STAGE_STATE_DIR/.openclaw' || true
"
```

**Step 4: Run the test**

Run:

```bash
bash tests/oc-stage-clone.test.sh
```

Expected: PASS.

**Step 5: Real smoke on Hostinger**

Run:

```bash
./ops/oc-stage-clone.sh
```

Expected: staging state path exists on Hostinger and prod path remains unchanged.

**Step 6: Commit**

```bash
git add ops/oc-stage-clone.sh tests/oc-stage-clone.test.sh
git commit -m "feat: add staging clone workflow"
```

## Task 5: Bring staging up on an isolated loopback port

**Files:**
- Create: `ops/oc-stage-up.sh`
- Create: `tests/oc-stage-up.test.sh`
- Modify: `docker-compose.prod.yml` or create `docker-compose.stage.yml`

**Step 1: Write the failing test**

Assert the script:
- uses a distinct container name
- uses staging state dir
- binds a different host loopback port
- does not stop prod

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-stage-up.test.sh
```

Expected: FAIL because stage-up script or stage compose does not exist.

**Step 3: Write minimal implementation**

Recommended shape:
- keep prod compose as-is
- create `docker-compose.stage.yml`
- bind `127.0.0.1:18790:18789`
- use `container_name: openclaw-stage-1`
- mount `${OPENCLAW_STAGE_STATE_DIR}/.openclaw:/home/node/.openclaw`

**Step 4: Run the test**

Run:

```bash
bash tests/oc-stage-up.test.sh
```

Expected: PASS.

**Step 5: Smoke on Hostinger**

Run:

```bash
./ops/oc-stage-up.sh
ssh -i "$HOME/.ssh/hostinger_agent" -o StrictHostKeyChecking=accept-new root@187.77.7.226 \
  "docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}' | grep openclaw"
```

Expected: prod and staging both visible; staging bound only to `127.0.0.1:18790`.

**Step 6: Commit**

```bash
git add ops/oc-stage-up.sh tests/oc-stage-up.test.sh docker-compose.stage.yml
git commit -m "feat: add isolated staging container"
```

## Task 6: Add staging smoke test for plugin/config experiments

**Files:**
- Create: `ops/oc-stage-smoke.sh`
- Modify: `tests/oc-stage-up.test.sh`
- Update: `docs/quickstart.md`

**Step 1: Write the failing test**

Assert the smoke script checks:
- `openclaw health --json`
- `openclaw status --json`
- extension directory listing
- plugin config grep
- recent logs

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-stage-up.test.sh
```

Expected: FAIL on missing smoke behavior.

**Step 3: Write minimal implementation**

Use:

```bash
./ops/oc-snapshot.sh "${OPENCLAW_STAGE_CONTAINER:-openclaw-stage-1}"
```

and add one prompt-smoke hook point:

```bash
PROMPT_SMOKE="${OPENCLAW_STAGE_PROMPT_SMOKE:-}"
```

If the prompt smoke value is non-empty, print a reminder line instead of inventing internals.

**Step 4: Run the test**

Run:

```bash
bash tests/oc-stage-up.test.sh
```

Expected: PASS.

**Step 5: Real smoke**

Run:

```bash
./ops/oc-stage-smoke.sh
```

Expected: staging health/status/logs/install view prints cleanly.

**Step 6: Commit**

```bash
git add ops/oc-stage-smoke.sh tests/oc-stage-up.test.sh docs/quickstart.md
git commit -m "feat: add staging smoke verification"
```

## Task 7: Add short daily CTO-style reporting

**Files:**
- Create: `ops/oc-daily-report.sh`
- Create: `tests/oc-daily-report.test.sh`
- Modify: `docs/quickstart.md`
- Modify: `docs/vps-migration.md`

**Step 1: Write the failing test**

Assert the script:
- creates `reports/openclaw-daily/YYYY-MM-DD/overview.md`
- keeps overview short
- creates feature folders only when activity is detected
- writes plain "no meaningful activity" when nothing happened

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-daily-report.test.sh
```

Expected: FAIL because the report script does not exist.

**Step 3: Write minimal implementation**

Collect from:
- `openclaw status --json`
- recent session timestamps
- recent logs
- extension/config snapshot
- optional workspace changes if a mounted repo exists

Write:

```text
reports/openclaw-daily/YYYY-MM-DD/overview.md
```

with sections:
- Status
- Work Done
- Risks
- Next

If activity can be grouped by topic, create:

```text
reports/openclaw-daily/YYYY-MM-DD/features/<feature-slug>/
```

and write short files under `research/`, `planning/`, and `writing/` only when data exists.

**Step 4: Run the test**

Run:

```bash
bash tests/oc-daily-report.test.sh
```

Expected: PASS.

**Step 5: Real smoke**

Run:

```bash
./ops/oc-daily-report.sh
find reports/openclaw-daily -maxdepth 3 -type f | sort
```

Expected: the current day report exists and is readable without becoming a long dump.

**Step 6: Commit**

```bash
git add ops/oc-daily-report.sh tests/oc-daily-report.test.sh docs/quickstart.md docs/vps-migration.md
git commit -m "feat: add short daily openclaw report"
```

## Task 8: Add easy destroy/reset for staging

**Files:**
- Create: `ops/oc-stage-down.sh`
- Modify: `docs/vps-migration.md`

**Step 1: Write the failing test**

Assert the script:
- stops/removes only staging
- optionally deletes staging state with `--purge`
- never touches prod container/state

**Step 2: Run the failing test**

Run:

```bash
bash tests/oc-stage-up.test.sh
```

Expected: FAIL on missing teardown behavior.

**Step 3: Write minimal implementation**

Use:

```bash
ssh_host "
  docker rm -f '$STAGE_CONTAINER' 2>/dev/null || true
"
```

For purge:

```bash
ssh_host "rm -rf '$STAGE_STATE_DIR/.openclaw'"
```

**Step 4: Run the test**

Run:

```bash
bash tests/oc-stage-up.test.sh
```

Expected: PASS.

**Step 5: Real smoke**

Run:

```bash
./ops/oc-stage-down.sh
```

Expected: staging gone, prod still up.

**Step 6: Commit**

```bash
git add ops/oc-stage-down.sh docs/vps-migration.md
git commit -m "feat: add staging teardown workflow"
```

## Task 9: Document the new operating model

**Files:**
- Modify: `docs/quickstart.md`
- Modify: `docs/vps-migration.md`
- Modify: `docs/auth-setup.md`

**Step 1: Update the docs**

Add:
- Hostinger prod is the only live runtime
- local OpenClaw runtime is optional and not required
- local source-update work happens in repo root `.`
- staging is created by copying prod state
- plugin/config experiments happen only in staging first
- `ops/oc-snapshot.sh` is the default observability command
- `ops/oc-daily-report.sh` is the default daily reporting command
- daily reports live under `reports/openclaw-daily/`

**Step 2: Verify docs references**

Run:

```bash
rg -n "staging|snapshot|prod is the only live runtime|local OpenClaw runtime is optional|reports/openclaw-daily|oc-daily-report" docs
```

Expected: all new flows are documented.

**Step 3: Commit**

```bash
git add docs/quickstart.md docs/vps-migration.md docs/auth-setup.md
git commit -m "docs: add prod and staging operating model"
```

## Task 10: End-to-end verification before rollout

**Files:**
- Use: `ops/oc-snapshot.sh`
- Use: `ops/oc-stage-clone.sh`
- Use: `ops/oc-stage-up.sh`
- Use: `ops/oc-stage-smoke.sh`
- Use: `ops/oc-stage-down.sh`

**Step 1: Verify local shell tests**

Run:

```bash
bash tests/oc-snapshot.test.sh
bash tests/oc-stage-clone.test.sh
bash tests/oc-stage-up.test.sh
bash tests/oc-daily-report.test.sh
bash -n ops/oc-snapshot.sh
bash -n ops/oc-stage-clone.sh
bash -n ops/oc-stage-up.sh
bash -n ops/oc-stage-smoke.sh
bash -n ops/oc-stage-down.sh
bash -n ops/oc-daily-report.sh
```

Expected: all pass.

**Step 2: Verify live Hostinger flow**

Run:

```bash
./ops/oc-snapshot.sh
./ops/oc-stage-clone.sh
./ops/oc-stage-up.sh
./ops/oc-stage-smoke.sh
./ops/oc-daily-report.sh
./ops/oc-stage-down.sh --purge
./ops/oc-snapshot.sh
```

Expected:
- prod visible before and after
- staging can be created and destroyed cleanly
- no prod interruption

**Step 3: Commit final verification-linked changes**

```bash
git add ops tests docs
git commit -m "test: verify hostinger prod staging workflow"
```

## Rollout notes

- Do not cut prod over to a new image in this plan.
- First deliver visibility and staging safety.
- Keep OpenClaw source-update planning and source tests local in repo root `.`
- Only after staging is proven should prod deploy normalization continue.
- Keep `ops/vps-openclaw-workspace-sync.sh` out of the primary flow.

Plan complete and saved to `docs/plans/2026-03-15-hostinger-prod-staging-observability.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
