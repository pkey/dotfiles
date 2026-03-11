# stack - stacked branch workflow: manage chains of dependent branches/PRs.
# Parent-child relationships stored in git config (branch.<name>.stack-parent),
# shared across worktrees automatically.
#
# Usage:
#   stack create <name>     Branch off current and record parent
#   stack track [parent]    Record parent for current branch (default: auto-detect)
#   stack pr                Push and create/update PR with stack parent as base
#   stack restack [base]    Rebase all descendants of base (default: current branch)
#   stack sync [base]       Pull base, reparent merged branches, clean up
#   stack list [branch]     Print the branch chain tree
#   stack delete [branch]   Remove branch and reparent its children
stack() {
  local cmd="${1:-}"
  case "$cmd" in
    create)    shift; _stack_create "$@" ;;
    track)     shift; _stack_track "$@" ;;
    pr)        shift; _stack_pr "$@" ;;
    restack)   shift; _stack_restack "$@" ;;
    sync)      shift; _stack_sync "$@" ;;
    list|ls)   shift; _stack_list "$@" ;;
    delete|rm) shift; _stack_delete "$@" ;;
    -h|--help|help) _stack_usage ;;
    *)         _stack_usage; return 1 ;;
  esac
}

_stack_usage() {
  echo "Usage: stack <command> [args]"
  echo ""
  echo "Commands:"
  echo "  create <name>     Branch off current and record parent"
  echo "  track [parent]    Record parent for current branch (default: auto-detect)"
  echo "  pr                Push and create/update PR with stack parent as base"
  echo "  restack [base]    Rebase all descendants of base (default: current branch)"
  echo "  sync [base]       Pull base, reparent merged branches, clean up"
  echo "  list [branch]     Print the branch chain tree"
  echo "  delete [branch]   Remove branch and reparent its children"
}

_stack_create() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    echo "Usage: stack create <branch-name>" >&2
    return 1
  fi
  local parent
  parent=$(git rev-parse --abbrev-ref HEAD)
  git checkout -b "$name" && git config "branch.$name.stack-parent" "$parent"
}

_stack_track() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  local parent="${1:-}"

  if [[ -z "$parent" ]]; then
    # Auto-detect: find the closest ancestor branch
    local candidate
    for candidate in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
      [[ "$candidate" == "$branch" ]] && continue
      if git merge-base --is-ancestor "$candidate" "$branch" 2>/dev/null; then
        # Pick the candidate closest to HEAD (most commits in common)
        if [[ -z "$parent" ]] || git merge-base --is-ancestor "$parent" "$candidate" 2>/dev/null; then
          parent="$candidate"
        fi
      fi
    done
  fi

  if [[ -z "$parent" ]]; then
    echo "Could not detect parent branch. Usage: stack track <parent>" >&2
    return 1
  fi

  local existing
  existing=$(git config "branch.$branch.stack-parent" 2>/dev/null || true)
  if [[ "$existing" == "$parent" ]]; then
    echo "Already tracking $branch → $parent"
    return 0
  fi
  git config "branch.$branch.stack-parent" "$parent"
  if [[ -n "$existing" ]]; then
    echo "Reparented $branch: $existing → $parent"
  else
    echo "Tracking $branch → $parent"
  fi
}

_stack_pr() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  local parent
  parent=$(git config "branch.$branch.stack-parent" 2>/dev/null || true)

  if [[ -z "$parent" ]]; then
    echo "No stack parent set for $branch. Run: stack track [parent]" >&2
    return 1
  fi

  git push -u origin "$branch"

  if gh pr view "$branch" --json number &>/dev/null; then
    gh pr edit "$branch" --base "$parent"
    echo "Updated PR base to $parent"
  else
    gh pr create --base "$parent" "$@"
  fi
}

_stack_restack() {
  local base="${1:-$(git rev-parse --abbrev-ref HEAD)}"
  local original_branch
  original_branch=$(git rev-parse --abbrev-ref HEAD)

  local children=()
  local branch
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    if [[ "$(git config "branch.$branch.stack-parent" 2>/dev/null)" == "$base" ]]; then
      children+=("$branch")
    fi
  done

  for child in "${children[@]}"; do
    local checked_out_in
    checked_out_in=$(git worktree list --porcelain 2>/dev/null \
      | awk -v b="refs/heads/$child" '$1=="branch" && $2==b {found=1} $1=="worktree" {wt=$2} found {print wt; found=0}')
    if [[ -n "$checked_out_in" ]]; then
      echo "Rebasing $child onto $base (via --onto, checked out in $checked_out_in)"
      local old_base
      old_base=$(git merge-base "$base" "$child")
      git rebase --onto "$base" "$old_base" "$child"
    else
      echo "Rebasing $child onto $base"
      git checkout "$child" && git rebase "$base"
    fi
    _stack_restack "$child"
  done

  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$original_branch" ]]; then
    git checkout "$original_branch" 2>/dev/null
  fi
}

_stack_sync() {
  local base="${1:-$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')}"
  base="${base:-main}"

  git fetch origin "$base" && git checkout "$base" && git pull --ff-only

  local original_branch
  original_branch=$(git rev-parse --abbrev-ref HEAD)
  local synced=()

  local branch
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    local parent
    parent=$(git config "branch.$branch.stack-parent" 2>/dev/null || true)
    [[ -z "$parent" ]] && continue
    [[ "$parent" == "$base" ]] && continue

    if git merge-base --is-ancestor "$parent" "$base" 2>/dev/null; then
      echo "Reparenting $branch: $parent → $base (merged)"
      git config "branch.$branch.stack-parent" "$base"
      git rebase --onto "$base" "$parent" "$branch"
      synced+=("$parent")
    fi
  done

  for merged in "${synced[@]}"; do
    if git branch -d "$merged" 2>/dev/null; then
      echo "Deleted merged branch: $merged"
    fi
  done

  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$original_branch" ]]; then
    git checkout "$original_branch" 2>/dev/null
  fi
}

_stack_print_tree() {
  local b="$1" indent="$2"
  local current
  current=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$b" == "$current" ]]; then
    printf "%s\033[1;32m%s\033[0m (current)\n" "$indent" "$b"
  else
    printf "%s%s\n" "$indent" "$b"
  fi
  local child
  for child in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    if [[ "$(git config "branch.$child.stack-parent" 2>/dev/null)" == "$b" ]]; then
      _stack_print_tree "$child" "  $indent"
    fi
  done
}

_stack_list() {
  local start="${1:-$(git rev-parse --abbrev-ref HEAD)}"

  local root="$start"
  while true; do
    local p
    p=$(git config "branch.$root.stack-parent" 2>/dev/null || true)
    [[ -z "$p" ]] && break
    root="$p"
  done

  _stack_print_tree "$root" ""
}

_stack_delete() {
  local branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"
  local parent
  parent=$(git config "branch.$branch.stack-parent" 2>/dev/null || true)

  if [[ "$branch" == "$(git rev-parse --abbrev-ref HEAD)" ]]; then
    echo "Cannot delete the currently checked out branch" >&2
    return 1
  fi

  local child
  for child in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    if [[ "$(git config "branch.$child.stack-parent" 2>/dev/null)" == "$branch" ]]; then
      if [[ -n "$parent" ]]; then
        echo "Reparenting $child: $branch → $parent"
        git config "branch.$child.stack-parent" "$parent"
      else
        git config --unset "branch.$child.stack-parent"
      fi
    fi
  done

  git branch -D "$branch" && echo "Deleted branch: $branch"
}
