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
```bash
glab mr view <number>
```
The output includes approval status and unresolved discussions.

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

### Details

**[repo-name]**
- Branch: `feature-branch`
- PR/MR: #123 - Title
- CI: ✅ passing / ❌ failing
- Reviews: X approved, Y pending
- Diff: X files, +Y/-Z lines

### Recent Commits
- `abc1234` - Commit message (repo-name)

### Blockers
- List any blocking issues or pending reviews

### What's Next
- List immediate next steps or action items
```

## What's Next

After gathering status, identify and summarize the next steps:

- Check task definition files (e.g., `AGENTS.md`, `TODO.md`, `progress.md`) for remaining work items
- Review any PR/MR feedback that needs addressing
- Identify blocked tasks and their dependencies
- Note any failing CI checks that need fixing
- List uncommitted or unpushed changes that need attention

Include a prioritized list of actionable next steps in the output.
