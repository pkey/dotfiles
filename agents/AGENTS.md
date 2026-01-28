---
description: Global coding preferences for all projects
alwaysApply: true
---

# General

- language: English only - all code, comments, docs, examples, commits, configs, errors, tests
- git commits: Use conventional format: <type>(<scope>): <subject> where type = feat|fix|docs|style|refactor|test|chore|perf. Subject: 50 chars max, imperative mood ("add" not "added"), no period. For small changes: one-line commit only. For complex changes: add body explaining what/why (72-char lines) and reference issues. Keep commits atomic (one logical change) and self-explanatory. Split into multiple commits if addressing different concerns.
- tools:
    - Use rg not grep
    - fd not find
    - refer to aliases and reuse them when appropriate
    - refer to $DOTFILES/Brewfile for installed tools
    - Always echo environment variables (like $DOTFILES) to resolve paths before asking the user
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

# Local Context

- Always check for `AGENTS.local.md` in the current project root
- This file contains project-specific learnings and preferences that are gitignored
- If present, read and apply its contents alongside other AGENTS.md files
