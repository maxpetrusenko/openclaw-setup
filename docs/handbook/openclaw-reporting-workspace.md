# OpenClaw Reporting Workspace

> **Read when:** Setting up Hostinger prod/staging, writing daily reports, or understanding OpenClaw operating lanes.

## Operating Lanes

OpenClaw work happens in three distinct lanes. Keep them separate.

### Lane 1: Local Source-Update Lane

**Location:** Repo root `.` (this repository)

**Purpose:** local source-update work - OpenClaw source edits, update plans, local tests

**Rules:**
- This lane exists only when changing OpenClaw itself
- Nothing in this lane mutates Hostinger automatically
- All source-level tests run here before any prod deploy
- Keep edit-test-commit cycles local

**When to use:**
- Changing OpenClaw configuration
- Testing new plugin versions locally
- Developing OpenClaw updates

### Lane 2: Hostinger Runtime Lane

**Location:** Hostinger VPS at `187.77.7.226`

**Containers:**
- **Prod:** `openclaw-ylld-openclaw-1` (live runtime)
- **Staging:** `openclaw-stage-1` (disposable clone for Hostinger staging experiments)

**State Paths:**
- **Prod state:** `/docker/openclaw-ylld/data/.openclaw`
- **Staging state:** `/docker/openclaw-stage/data/.openclaw`

**Rules:**
- Hostinger prod is the only live OpenClaw runtime
- Staging is created by copying prod state
- No bidirectional sync of `.openclaw` back to local
- Rollback = previous image tag + untouched prod state

**When to use:**
- Running prod OpenClaw
- Testing plugin/config changes in staging
- Inspecting live state via `ops/oc-snapshot.sh`

### Lane 3: Daily Report Lane

**Location:** `reports/openclaw-daily/` (local repo)

**Purpose:** Short CTO-style daily summaries from prod activity

**Rules:**
- Generate one short report per day
- Use folder-as-workspace structure
- Keep reports readable as plain Markdown
- If nothing happened, say so plainly

## Reporting Workspace Structure

BMAD-style folder workspace: top-level map, per-feature folders, short Markdown artifacts.

```
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

## Naming Rules

### Daily Reports
- Folder: `YYYY-MM-DD` (e.g., `2026-03-15`)
- Top-level overview: `overview.md` (required)

### Feature Slugs
- Use kebab-case
- Lowercase only
- Max 3 words
- Examples:
  - `ssh-host-helper`
  - `staging-clone`
  - `daily-report`

### Feature Artifacts
- `overview.md` - feature summary
- `research/` - external research sources
- `planning/` - notes and drafts
- `writing/` - content by version

## Report Content Rules

### overview.md (Required)
Keep it short. CTO-style summary:
- Status
- Work Done
- Risks
- Next

### Feature Folders (Optional)
Create only when there was meaningful work. Prefer:
- Plain facts
- What broke
- What is risky
- What is next

### When Nothing Happened
Write only the top-level `overview.md`:
```markdown
# 2026-03-15

Status: Stable

No meaningful activity today. Prod running normally.
```

## Tools

- `ops/oc-snapshot.sh` - inspect prod state
- `ops/oc-daily-report.sh` - generate daily report
- `ops/oc-stage-clone.sh` - create staging from prod
- `ops/oc-stage-up.sh` - bring staging up
- `ops/oc-stage-smoke.sh` - verify staging
- `ops/oc-stage-down.sh` - destroy staging
