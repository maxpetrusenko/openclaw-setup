---
name: github
description: "GitHub workflows with `gh`: PR landing, CI triage, and security advisories."
---

# GitHub Skill

Use `gh` for issues, PRs, CI, and advisory operations.

Always specify `--repo owner/repo` when not in a git directory, or use PR/issue URLs directly.

## Core Commands

Check CI status:
```bash
gh pr checks 55 --repo owner/repo
```

List workflow runs:
```bash
gh run list --repo owner/repo --limit 10
```

View run details:
```bash
gh run view <run-id> --repo owner/repo
```

Failed-step logs:
```bash
gh run view <run-id> --repo owner/repo --log-failed
```

Advanced API query:
```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

Structured output:
```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```

## Playbook: Land PR (`/landpr`)

Goal: PR ends in GitHub state `MERGED` (never `CLOSED`).

1. Guardrails:
```bash
git status -sb
```
- Working tree must be clean.
- If PR is draft, not mergeable, or you cannot push to head branch: stop and ask.

2. Capture PR context:
```bash
PR="<pr-number-or-url>"
gh pr view "$PR" --json number,title,state,isDraft,mergeable,author,baseRefName,headRefName,headRepository,maintainerCanModify --jq '{number,title,state,isDraft,mergeable,author:.author.login,base:.baseRefName,head:.headRefName,headRepo:.headRepository.nameWithOwner,maintainerCanModify}'
prnum=$(gh pr view "$PR" --json number --jq .number)
contrib=$(gh pr view "$PR" --json author --jq .author.login)
base=$(gh pr view "$PR" --json baseRefName --jq .baseRefName)
head=$(gh pr view "$PR" --json headRefName --jq .headRefName)
head_repo_url=$(gh pr view "$PR" --json headRepository --jq .headRepository.url)
```

3. Update base and create temp branch:
```bash
git checkout "$base"
git pull --ff-only
git checkout -b "temp/landpr-$prnum"
```

4. Checkout PR branch and rebase:
```bash
gh pr checkout "$PR"
git rebase "temp/landpr-$prnum"
```

5. Implement fixes, add tests, update `CHANGELOG.md` with `#$prnum` and thanks `@$contrib`.

6. Run full gate before commit (repo-specific lint/typecheck/tests/docs).

7. Commit and capture land SHA:
```bash
committer "fix: <summary> (#$prnum) (thanks @$contrib)" CHANGELOG.md <changed files>
land_sha=$(git rev-parse HEAD)
```

8. Push rebased head branch (fork-safe):
```bash
git remote add prhead "$head_repo_url.git" 2>/dev/null || git remote set-url prhead "$head_repo_url.git"
git push --force-with-lease prhead "HEAD:$head"
```

9. Merge PR:
```bash
gh pr merge "$PR" --rebase
# or
gh pr merge "$PR" --squash
```

10. Sync base:
```bash
git checkout "$base"
git pull --ff-only
```

11. Comment with SHAs and thanks:
```bash
merge_sha=$(gh pr view "$PR" --json mergeCommit --jq '.mergeCommit.oid')
gh pr comment "$PR" --body "Landed via temp rebase onto $base.

- Gate: <cmds>
- Land commit: $land_sha
- Merge commit: $merge_sha

Thanks @$contrib!"
```

12. Verify state and clean up:
```bash
gh pr view "$PR" --json state,mergedAt --jq '.state + " @ " + .mergedAt'
git branch -D "temp/landpr-$prnum"
```

## Playbook: Security Advisory Triage (`/sectriage`)

Use this when finishing GHSA triage and preparing an advisory for publish-later.

1. Preflight:
- Ensure clean local state (`git status --porcelain`).
- Fetch current advisory via `gh api`.
- Check for existing fix PRs before creating duplicate work.

2. Fix and verify locally:
- Land fix on `main` (or follow your repo policy).
- Run required gate commands for this repo.
- Update `CHANGELOG.md` under `Unreleased` with a non-GHSA-facing fix note and reporter thanks.

3. Patch advisory with `gh api`:
- Build `description` as markdown (include affected versions and fix commits).
- Patch summary/severity/description and structured `vulnerabilities[]`.
- Keep advisory ready for later publish once package release is live.

4. Verify:
- Re-fetch advisory and check: `html_url`, `state`, `vulnerabilities`, `updated_at`.

Safety:
- Do not publish/accept advisory state unless explicitly requested.
- Do not execute destructive or external-mutating commands without explicit approval.
