---
description: The rule to rule them all
alwaysApply: true
---

Nothing, you are perfect!

## Code Comments

- Prefix TODO comments with the user's GitHub handle: `TODO(pkey):` (e.g., `// TODO(pkey): refactor this`)

## Shell Tools

### Git Worktree Management (`wt`)

Defined in `tools/worktree.sh`. Manages worktrees under `~/worktrees/<repo>/<branch>`.

- `wt checkout <branch>` - Check out an existing branch in a new worktree
- `wt checkout -b <base> <branch>` - Create a new branch from base in a new worktree
- `wt list` - Fuzzy-select a worktree from the current repo and cd into it
- `wt list --all` - Fuzzy-select a worktree across all repos under ~/worktrees
- `wt delete` - Fuzzy-select worktrees to remove (multi-select), deletes branches too
- `wt delete --all` - Fuzzy-select worktrees across all repos to remove (multi-select)
