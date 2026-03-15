# OpenClaw Ops Hybrid Daily Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a safe daily self-update path for the VPS install and a daily OpenClaw ops review routine that can surface work summaries and skill opportunities.

**Architecture:** Use a host-level shell script for update detection, idle gating, and restarts via the native `openclaw update` command. Add a repo-local skill plus runbook so a new isolated OpenClaw cron job can execute a repeatable ops review routine without depending on hidden context.

**Tech Stack:** Bash, Docker CLI, OpenClaw CLI, Markdown docs, repo-local skills

---

### Task 1: Add the design and ops docs

**Files:**
- Create: `docs/plans/2026-03-14-openclaw-ops-hybrid-daily-update-design.md`
- Create: `clawdbot/vps/auto-update.md`

**Step 1: Record the live assumptions**

Document the current install mode, current version, latest available version, and why the design is hybrid.

**Step 2: Record the live operating steps**

Document:
- how to dry-run the updater
- how to install the host cron entry
- how to verify the OpenClaw cron review job

### Task 2: Add the host updater script

**Files:**
- Create: `ops/openclaw-auto-update.sh`

**Step 1: Write a safe checker**

The script should:
- inspect `openclaw update status --json`
- inspect `openclaw status --json`
- detect recent non-cron, non-system activity
- mirror updater state into the workspace
- skip when idle criteria are not met

**Step 2: Write the update path**

If an update is available and the instance is idle:
- run `openclaw update --yes`
- restart the Docker container when the runtime is not using an installed gateway service
- verify the running version changed or update availability cleared
- record state
- send a summary message when Telegram alert target is configured

**Step 3: Write the dry-run path**

Support `--dry-run` so the exact decision can be tested on the VPS without mutating the install.

### Task 3: Add the OpenClaw ops review skill

**Files:**
- Create: `clawdbot/skills/openclaw-ops-maintenance/SKILL.md`
- Create: `clawdbot/skills/openclaw-ops-maintenance/_meta.json`
- Modify: `clawdbot/memory/skills.md`

**Step 1: Define the trigger**

The skill should activate for daily ops sweeps, update checks, cron-health review, last-day work review, and skill-opportunity review.

**Step 2: Define the report shape**

The skill should require:
- updater
- cron
- last-day work
- skill opportunities
- next actions

**Step 3: Add shared-registry guidance**

Document how to use the Mac shared registry when available, and how to degrade gracefully when it is not.

### Task 4: Deploy to the live VPS

**Files:**
- Modify live host state only

**Step 1: Install the updater script**

Copy the script to the VPS host in a stable location and make it executable.

**Step 2: Install the host cron entry**

Schedule one daily run during a quiet window.

**Step 3: Install or update the OpenClaw cron job**

Add a new isolated job that invokes the daily ops review routine with the new skill.

### Task 5: Verification

**Files:**
- Verify changed docs and scripts

**Step 1: Local verification**

Run:
- `bash -n ops/openclaw-auto-update.sh`
- a dry-run invocation against the live VPS

**Step 2: Live verification**

Run:
- host script in dry-run mode
- `openclaw cron list`
- `openclaw cron run <jobId>` for the new review job if safe

**Step 3: Sync verification**

Push the updated `clawdbot/` workspace to the VPS and verify the new skill exists there.
