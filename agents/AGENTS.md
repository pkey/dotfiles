---
description: Global coding preferences for all projects
alwaysApply: true
---

# General

- Always check for and read CONTRIBUTING.md when starting work on a new repo
- git commits: Use conventional format: <type>: <subject> where type = feat|fix|docs|style|refactor|test|chore|perf. Subject: 50 chars max, imperative mood ("add" not "added"), no period. For small changes: one-line commit only. For complex changes: add body explaining what/why (72-char lines) and reference issues. Keep commits atomic (one logical change) and self-explanatory. Split into multiple commits if addressing different concerns. Always focus on WHY (motivation/reasoning) not WHAT (description of changes) — the diff already shows what changed. If the "why" isn't clear from current context, check recent conversation histories for the reasoning behind the change.
- attribution: Never include AI tool attribution in any output — no co-author trailers in commits, no "Made with" lines in PRs/issues, no AI tool references in any generated content. If a hook or tool injects them, remove before publishing.
- tools:
    - Use rg not grep
    - fd not find
    - refer to aliases and reuse them when appropriate
    - refer to $DOTFILES/packages.yaml for installed tools
    - Always echo environment variables (like $DOTFILES) to resolve paths before asking the user
    - glab: For advanced GitLab operations not in standard commands, use `glab api`:
        - Play manual jobs: `glab api --method POST "projects/<path>/jobs/<id>/play"`
        - Check MR approvals: `glab api "projects/<path>/merge_requests/<id>/approvals"`
        - List pipeline jobs: `glab api "projects/<path>/pipelines/<id>/jobs"`
- style: Prefer self-documenting code over comments
- philosophy:
    - YAGNI - don't build features until actually needed

# Dev Projects
- prefer using Makefile for most common commands. Update it when new workflow is added.

# Python
- Preferred package and project manager: uv
- use uv init to initialise new project

# Task Workflow

- Main repositories live in `~/repos/`
- Tasks are created via `task <name>` which creates git worktrees in `~/tasks/<task-name>/`
- `$DOTFILES/tools/task.sh` manages this workflow
- For files that should persist/share across worktrees (like `AGENTS.local.md`):
  - Create the file in the source repo (`~/repos/<repo>/`)
  - It will be symlinked to worktrees automatically
  - Edits from any worktree update the source
- When working in `~/tasks/`, remember you're in a worktree - the source repo is in `~/repos/`

# Investigating CI/CD Failures

When asked about CI/CD, MR (GitLab), or PR (GitHub) test failures:
1. First use the appropriate CLI to get actual failure information:
   - GitLab: `glab mr view`, `glab ci status`, `glab ci view`, `glab ci trace <job-id>`
   - GitHub: `gh pr view`, `gh run list`, `gh run view <run-id>`
   - CircleCI: First `gh api repos/<owner>/<repo>/commits/<sha>/check-runs --jq '.check_runs[] | select(.name=="<workflow>") | .output.summary'` for job summary, then `curl https://circleci.com/api/v1.1/project/github/<org>/<repo>/<build_num>` for step details and output URLs
2. Identify the specific failing test/job from CI logs
3. Check if the same test passes on main/master branch
4. If failure seems intermittent, retry the job first
5. After triggering a retry, summarize findings and ask user preference before deep code investigation
6. Do NOT make code changes based on assumptions - verify the exact failing test from logs first

Do NOT start by blindly exploring the codebase - the failure information is in CI/CD, not the source code.

# Local Context

- **Always check for `AGENTS.local.md` in the current project root FIRST** - especially for CI/CD, deployment, or release tasks
- This file contains project-specific learnings and preferences that are gitignored
- If present, read and apply its contents alongside other AGENTS.md files
