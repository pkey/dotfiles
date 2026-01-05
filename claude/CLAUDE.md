# General

- language: English only - all code, comments, docs, examples, commits, configs, errors, tests
- git commits: Use conventional format: <type>(<scope>): <subject> where type = feat|fix|docs|style|refactor|test|chore|perf. Subject: 50 chars max, imperative mood ("add" not "added"), no period. For small changes: one-line commit only. For complex changes: add body explaining what/why (72-char lines) and reference issues. Keep commits atomic (one logical change) and self-explanatory. Split into multiple commits if addressing different concerns.
- tools:
    - Use rg not grep
    - fd not find
- style: Prefer self-documenting code over comments

# Dev Projects
- prefer using makefile for most common command. Update it when new workflow is added.

# Claude
- when initialising CLAUDE.md, write to AGENTS.md and reference CLAUDE.md to it.

# Python
- Preferred package and project manager: uv
- use uv init to initialise new project
