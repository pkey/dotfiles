---
name: git-worktree-workflow
description: Use when working with git worktrees in pkey's repos — creating a branch, switching between worktrees, removing one, or starting a stacked PR with Graphite. The user has shell helpers (gwt, gwtn, gwtc, gwtl, gwtm, gwtrm, gwtrmf, gwtp) sourced from ~/dotfiles/tools/git-worktree.sh that enforce a consistent layout under ~/worktrees/<repo>/<branch>. Prefer these over raw `git worktree` commands so layout and main-worktree protection stay consistent.
---

# Git worktree workflow

The user does not branch in-place. Every branch is a separate **git worktree**, laid out as:

```
~/worktrees/<repo>/<branch-slug>
```

The main checkout lives at `~/code/<repo>` and stays on `main`. Stack metadata and PR submission are handled by **Graphite (`gt`)** — the helpers below only manage physical worktrees.

## Helpers (use these, not raw `git worktree`)

| Helper | What it does |
|---|---|
| `gwt` | Print the helper cheatsheet (no side effects). |
| `gwtn <branch> [base]` | Create a worktree at `~/worktrees/<repo>/<slug>` from `[base]` (default `HEAD`) and `cd` into it. If `<branch>` already exists, attaches a worktree to it instead of creating a branch. Use this when you know the branch name you want and don't need to pick. |
| `gwtc [branch]` | Go to `<branch>`'s worktree, **materializing one if it doesn't exist yet**. Resolves `<branch>` against existing worktrees → local branches → `origin/<branch>` (in that order). With no arg, opens an fzf picker over **worktrees + all local branches + all remote branches**, marked `[*]` (worktree exists) or `[ ]` (branch only). Picking a `[ ]` row creates the worktree, then `cd`s in. |
| `gwtl` | List worktrees for the current repo. |
| `gwtm` | `cd` to the main worktree (branch = `$GWT_MAIN_BRANCH`, default `main`). |
| `gwtrm` | Remove the current worktree. Refuses on main. `cd`s to main first. |
| `gwtrmf` | Same as `gwtrm` but `--force`. |
| `gwtp` | `git worktree prune`. |

Source: `~/dotfiles/tools/git-worktree.sh` (auto-sourced by `~/.zshrc`).

## Rules of thumb

- **New branch from scratch** → `gwtn <branch>`. **Never** `git checkout -b` in the main checkout, and **never** `git worktree add` directly — both bypass the layout.
- **Stacked branch on the current one** (Graphite-style) → from the parent worktree, `gwtn <child-branch>`. Default base is `HEAD`, which is the parent tip.
- **Switch to / materialize an existing branch** → `gwtc`. The picker shows worktrees and bare branches together; pick the row to go there. Picking a `[ ]` row auto-creates the worktree (and tracks `origin/<branch>` if remote-only). Use `gwtc <branch>` for the same behavior with a known name.
- **Reviewing a colleague's PR branch** → `gwtc` and pick the `[ ]` `origin/<branch>` row, or `gwtc <branch>` directly (it falls back to `origin/<branch>` if no local branch exists). Run `git fetch` first if the remote ref isn't visible yet.
- **After a PR merges** → `gt sync` (Graphite handles branch deletion), then from inside the merged worktree run `gwtrm`, then `gwtp`.
- Don't suggest removing the main worktree. The helpers refuse; don't propose workarounds.
- If the user is mid-task with uncommitted changes and `gwtrm` fails, surface the error — don't reach for `gwtrmf` unless they ask.

## Stacked-PR example with Graphite

```sh
gwtm                     # ~/code/<repo> on main
gwtn feature-a           # ~/worktrees/<repo>/feature-a, branched off main
# ...edit, commit...
gt submit                # Graphite: PR for feature-a
gwtn feature-b           # from feature-a, creates feature-b stacked on it
# ...edit, commit...
gt submit                # Graphite: stacked PR for feature-b
# after feature-a merges:
gwtm && gt sync          # Graphite catches branches up and deletes merged ones
gwtc feature-a && gwtrm  # remove the merged worktree
gwtp                     # prune admin records
```

## What this workflow intentionally does NOT do

- **Does not replace Graphite.** `gt create`, `gt submit`, `gt sync`, `gt restack`, etc. stay as-is.
- **Does not manage stack metadata.** Parent/child relationships live in Graphite.
- **Does not auto-delete branches after merge.** That's `gt sync`'s job.
- **Does not run install hooks** (no `npm install`, no `mise`/`asdf` reshim, no env bootstrap). If a new worktree needs deps, the user runs them.
- **Does not copy gitignored files** between worktrees.

## Config knobs

- `GWT_ROOT` — root for all worktrees (default `~/worktrees`).
- `GWT_MAIN_BRANCH` — protected main branch name (default `main`). Set to `master` for repos that use it.
