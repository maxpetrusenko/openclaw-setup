---
name: openclaw-setup-conventions
description: Development conventions and patterns for openclaw-setup. TypeScript project with conventional commits.
---

# Openclaw Setup Conventions

> Generated from [maxpetrusenko/openclaw-setup](https://github.com/maxpetrusenko/openclaw-setup) on 2026-03-22

## Overview

This skill teaches Claude the development patterns and conventions used in openclaw-setup.

## Tech Stack

- **Primary Language**: TypeScript
- **Architecture**: hybrid module organization
- **Test Location**: separate

## When to Use This Skill

Activate this skill when:
- Making changes to this repository
- Adding new features following established patterns
- Writing tests that match project conventions
- Creating commits with proper message format

## Commit Conventions

Follow these commit message conventions based on 22 analyzed commits.

### Commit Style: Conventional Commits

### Prefixes Used

- `feat`
- `fix`
- `docs`
- `chore`

### Message Guidelines

- Average message length: ~40 characters
- Keep first line concise and descriptive
- Use imperative mood ("Add feature" not "Added feature")


*Commit message example*

```text
fix: update test for rsync-based stage clone
```

*Commit message example*

```text
feat: add staging teardown workflow
```

*Commit message example*

```text
docs: record hostinger openclaw current state
```

*Commit message example*

```text
chore: add .vercel to gitignore
```

*Commit message example*

```text
fix: staging clone rsync exclusions + hostinger image default
```

*Commit message example*

```text
fix: correct vps-openclaw.sh path in tunnel test
```

*Commit message example*

```text
feat: add shared hostinger ops helper
```

*Commit message example*

```text
feat: add staging clone workflow
```

## Architecture

### Project Structure: Single Package

This project uses **hybrid** module organization.

### Guidelines

- This project uses a hybrid organization
- Follow existing patterns when adding new code

## Code Style

### Language: TypeScript

### Naming Conventions

| Element | Convention |
|---------|------------|
| Files | PascalCase |
| Functions | camelCase |
| Classes | PascalCase |
| Constants | SCREAMING_SNAKE_CASE |

### Import Style: Relative Imports

### Export Style: Named Exports


*Preferred import style*

```typescript
// Use relative imports
import { Button } from '../components/Button'
import { useAuth } from './hooks/useAuth'
```

*Preferred export style*

```typescript
// Use named exports
export function calculateTotal() { ... }
export const TAX_RATE = 0.1
export interface Order { ... }
```

## Common Workflows

These workflows were detected from analyzing commit patterns.

### Feature Development

Standard feature implementation workflow

**Frequency**: ~19 times per month

**Steps**:
1. Add feature implementation
2. Add tests for feature
3. Update documentation

**Files typically involved**:
- `api/*`
- `**/*.test.*`
- `**/api/**`

**Example commit sequence**:
```
feat: landing page for product validation
chore: add .vercel to gitignore
feat: add Notion integration for email capture
```

### Add Or Update Serverless Api Endpoint

Adds or updates a serverless API endpoint, often for integrations (e.g., Notion, Resend), and updates related documentation.

**Frequency**: ~3 times per month

**Steps**:
1. Edit or create the endpoint implementation file (e.g., api/waitlist.ts).
2. Update or create related documentation (e.g., api/CLAUDE.md).
3. Update configuration or ignore files if needed (e.g., .gitignore).

**Files typically involved**:
- `api/waitlist.ts`
- `api/CLAUDE.md`
- `.gitignore`

**Example commit sequence**:
```
Edit or create the endpoint implementation file (e.g., api/waitlist.ts).
Update or create related documentation (e.g., api/CLAUDE.md).
Update configuration or ignore files if needed (e.g., .gitignore).
```

### Add Or Update Ops Script With Tdd

Adds or updates an operational shell script (for staging, reporting, snapshot, etc.) with corresponding test script for TDD verification.

**Frequency**: ~5 times per month

**Steps**:
1. Create or update an ops script in ops/ (e.g., ops/oc-stage-up.sh, ops/oc-snapshot.sh).
2. Create or update a corresponding test script in tests/ (e.g., tests/oc-stage-up.test.sh, tests/oc-snapshot.test.sh).
3. Optionally update shared libraries (e.g., ops/lib/openclaw-host.sh) if needed.

**Files typically involved**:
- `ops/*.sh`
- `tests/*.test.sh`
- `ops/lib/openclaw-host.sh`

**Example commit sequence**:
```
Create or update an ops script in ops/ (e.g., ops/oc-stage-up.sh, ops/oc-snapshot.sh).
Create or update a corresponding test script in tests/ (e.g., tests/oc-stage-up.test.sh, tests/oc-snapshot.test.sh).
Optionally update shared libraries (e.g., ops/lib/openclaw-host.sh) if needed.
```

### Update Documentation And Tests Together

Updates documentation files and related test scripts in tandem, often to reflect new workflows or changes in operational procedures.

**Frequency**: ~2 times per month

**Steps**:
1. Edit or create documentation files in docs/ (e.g., docs/quickstart.md, docs/vps-migration.md).
2. Edit or create related test scripts in tests/ (e.g., tests/oc-reporting-workspace.test.sh).

**Files typically involved**:
- `docs/*.md`
- `tests/*.test.sh`

**Example commit sequence**:
```
Edit or create documentation files in docs/ (e.g., docs/quickstart.md, docs/vps-migration.md).
Edit or create related test scripts in tests/ (e.g., tests/oc-reporting-workspace.test.sh).
```

### Fix Or Improve Api Integration

Makes iterative fixes or improvements to an API integration, often updating both the implementation and its documentation.

**Frequency**: ~3 times per month

**Steps**:
1. Edit the API implementation file (e.g., api/waitlist.ts).
2. Edit the related documentation (e.g., api/CLAUDE.md).

**Files typically involved**:
- `api/waitlist.ts`
- `api/CLAUDE.md`

**Example commit sequence**:
```
Edit the API implementation file (e.g., api/waitlist.ts).
Edit the related documentation (e.g., api/CLAUDE.md).
```


## Best Practices

Based on analysis of the codebase, follow these practices:

### Do

- Use conventional commit format (feat:, fix:, etc.)
- Use PascalCase for file names
- Prefer named exports

### Don't

- Don't write vague commit messages
- Don't deviate from established patterns without discussion

---

*This skill was auto-generated by [ECC Tools](https://ecc.tools). Review and customize as needed for your team.*
