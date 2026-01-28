---
name: status
description: Summarize the status of the current task. Always use when starting a new session or on demand.
disable-model-invocation: true
---

# Status

Retrieve the status of the project. It should be a summary of progress on a given task.

## Usage

- read the overall tasks
- get the results of progress.md if exists
- look into recent or all the commits in the checked out branches of the child projects
- use gh or glab CLI to retrieve relevant pull requests

## Repo Type Detection

Determine whether each repo uses GitHub or GitLab before running PR/MR commands:

```bash
git remote -v
```

- If remote URL contains `github.com` → use `gh` CLI
- If remote URL contains `gitlab` → use `glab` CLI

## PR/MR Discovery

Find PRs/MRs for the current branch, checking all states (open, merged, closed).

**Important:** Do NOT suppress stderr with `2>/dev/null` - if a command fails, the error should be visible so issues (like incorrect flags) are surfaced rather than silently hidden.

**GitHub:**
```bash
gh pr list --head=<branch> --state=all --json number,title,state,mergedAt
```

**GitLab** (note: `glab` uses different flags than `gh` - there is no `--state` flag):
```bash
# Open MRs (default)
glab mr list --source-branch=<branch>

# Merged MRs
glab mr list --source-branch=<branch> --merged

# Closed MRs
glab mr list --source-branch=<branch> --closed
```

Run all three to get the complete picture. Alternatively, use the API directly:
```bash
glab api "projects/:id/merge_requests?source_branch=<branch>&state=all"
```

If a PR/MR is merged, skip CI and review checks for that repo (no longer applicable).

## CI/CD Status Checks

Check pipeline/workflow status for open PRs/MRs:

**GitHub:**
```bash
gh pr checks <number>
```

**GitLab:**
```bash
glab ci status
glab mr view <number>
```

## Review Status Details

Check for blocking reviews or unresolved threads:

**GitHub:**
```bash
gh pr view <number> --json reviews,reviewRequests
```

**GitLab:**

The standard `glab mr view <number>` does NOT show approval status. Use the API instead:

```bash
glab api "projects/<project-path-url-encoded>/merge_requests/<number>/approvals"
```

Example (for `probely/backend` MR 4310):
```bash
glab api "projects/probely%2Fbackend/merge_requests/4310/approvals"
```

Key fields in the response:
- `approved`: boolean - whether MR is approved
- `approvals_required`: number of required approvals
- `approvals_left`: remaining approvals needed (0 = fully approved)
- `approved_by`: array of users who approved
- `merge_status`: "can_be_merged" when ready

For unresolved discussions, use:
```bash
glab mr view <number>
```

## Diff Stats

Show the scope of changes per repo:

```bash
git diff main --stat | tail -1
```

This provides a quick summary of files changed and lines added/removed.

## Output Structure

Present status using this template:

```
## Task Status Summary

| Repo | Branch | PR/MR | CI Status | Reviews | Changes |
|------|--------|-------|-----------|---------|---------|
| repo-name | feature-branch | #123 | passing/failing | approved/pending | +100/-50 |
| repo-name | feature-branch | #456 (merged) | - | - | +200/-30 |

### Details

**[repo-name]** (open)
- Branch: `feature-branch`
- PR/MR: #123 - Title
- CI: ✅ passing / ❌ failing
- Reviews: X approved, Y pending
- Diff: X files, +Y/-Z lines

**[repo-name]** (merged)
- Branch: `feature-branch`
- PR/MR: #456 - Title (merged on YYYY-MM-DD)

### Recent Commits
- `abc1234` - Commit message (repo-name)

### Blockers
- List any blocking issues or pending reviews

### What's Next
- List immediate next steps or action items
```

## What's Next

After gathering status, identify and summarize the next steps:

- If all PRs/MRs are merged, confirm the task is complete or identify any remaining work
- Check task definition files (e.g., `AGENTS.md`, `TODO.md`, `progress.md`) for remaining work items
- Review any PR/MR feedback that needs addressing
- Identify blocked tasks and their dependencies
- Note any failing CI checks that need fixing
- List uncommitted or unpushed changes that need attention

Include a prioritized list of actionable next steps in the output.
