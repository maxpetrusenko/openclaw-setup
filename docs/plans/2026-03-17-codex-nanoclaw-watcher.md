# Codex NanoClaw Watcher Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install a NanoClaw-style Codex heartbeat watcher that keeps file-based memory under `~/.codex/nanoclaw/` and runs on a macOS `launchd` interval.

**Architecture:** Keep runtime state separate from code. Put reusable scripts in `agent-scripts/`, create the memory workspace in `~/.codex/nanoclaw/`, and install a `launchd` plist in `~/Library/LaunchAgents/`. The watcher itself is a thin shell wrapper around `codex exec` with lock, logs, prompt injection, and state updates.

**Tech Stack:** Bash, macOS `launchd`, local `codex` CLI, shell tests.

---

### Task 1: Add failing install test

**Files:**
- Create: `/Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-install.test.sh`
- Create: `/Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat-install.sh`

**Step 1: Write the failing test**

Test expectations:
- `install --no-load` creates `~/.codex/nanoclaw/`
- scaffold files exist: `AGENTS.md`, `MEMORY.md`, `HEARTBEAT.md`, `memory/active-tasks.md`
- plist exists in `~/Library/LaunchAgents/`
- plist points at the watcher script and runtime directory

**Step 2: Run test to verify it fails**

Run:
```bash
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-install.test.sh
```

Expected: fail because installer script does not exist yet.

**Step 3: Write minimal implementation**

Implement `nanoclaw-heartbeat-install.sh` with:
- `install`, `status`, `run-once`, `uninstall`
- `--runtime-dir`, `--interval`, `--no-load`
- file scaffold generation
- launchd plist generation

**Step 4: Run test to verify it passes**

Run:
```bash
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-install.test.sh
```

Expected: pass with created scaffold in a temp HOME.

**Step 5: Commit**

```bash
committer /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-install.test.sh /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat-install.sh -m "feat: add nanoclaw watcher installer"
```

### Task 2: Add failing watcher execution test

**Files:**
- Create: `/Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-heartbeat.test.sh`
- Create: `/Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat.sh`

**Step 1: Write the failing test**

Test expectations:
- watcher creates logs/state files
- watcher calls a configurable Codex binary once
- watcher writes the last Codex reply to `logs/last-heartbeat.txt`
- watcher records run metadata in `memory/heartbeat-state.json`

**Step 2: Run test to verify it fails**

Run:
```bash
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-heartbeat.test.sh
```

Expected: fail because watcher script does not exist yet.

**Step 3: Write minimal implementation**

Implement `nanoclaw-heartbeat.sh` with:
- single-run lock
- prompt file assembly
- `codex exec --skip-git-repo-check -C "$RUNTIME_DIR"`
- output capture
- JSON state update

**Step 4: Run test to verify it passes**

Run:
```bash
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-heartbeat.test.sh
```

Expected: pass with fake Codex binary.

**Step 5: Commit**

```bash
committer /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-heartbeat.test.sh /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat.sh -m "feat: add nanoclaw heartbeat watcher"
```

### Task 3: Document and install locally

**Files:**
- Modify: `/Users/maxpetrusenko/Desktop/Projects/agent-scripts/README.md`

**Step 1: Write the failing doc check**

Manual expectation:
- README mentions NanoClaw watcher scripts and paths
- install command is copy-pasteable

**Step 2: Run current checks**

Run:
```bash
sed -n '1,260p' /Users/maxpetrusenko/Desktop/Projects/agent-scripts/README.md
```

Expected: missing watcher docs.

**Step 3: Write minimal documentation**

Add a short section covering:
- runtime location
- install command
- launchd plist path
- status / run-once commands

**Step 4: Install and verify locally**

Run:
```bash
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat-install.sh install
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat-install.sh status
bash /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat-install.sh run-once
launchctl print "gui/$(id -u)/com.max.codex.nanoclaw-heartbeat"
```

Expected:
- files exist in `~/.codex/nanoclaw/`
- launch agent is loaded
- one heartbeat run completes and state/log files update

**Step 5: Commit**

```bash
committer /Users/maxpetrusenko/Desktop/Projects/agent-scripts/README.md /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat-install.sh /Users/maxpetrusenko/Desktop/Projects/agent-scripts/scripts/nanoclaw-heartbeat.sh /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-install.test.sh /Users/maxpetrusenko/Desktop/Projects/agent-scripts/tests/nanoclaw-heartbeat.test.sh -m "feat: install codex nanoclaw watcher"
```
