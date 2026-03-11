# stack - stacked branch workflow: manage chains of dependent branches/PRs.
# Parent-child relationships stored in git config (branch.<name>.stack-parent),
# shared across worktrees automatically.
#
# Usage:
#   stack create <name>     Branch off current and record parent
#   stack track [parent]    Record parent for current branch (default: auto-detect)
#   stack pr                Push and create/update PR with stack parent as base
#   stack restack [base]    Rebase all descendants of base (default: current branch)
#   stack absorb            Fast-forward parent to include current branch
#   stack sync              Restack all branches in the stack
#   stack sync --pull       Also fetch remote, reparent merged branches, clean up
#   stack list [branch]     Print the branch chain tree
#   stack delete [branch]   Remove branch and reparent its children
stack() {
  local cmd="${1:-}"
  case "$cmd" in
    create)    shift; _stack_create "$@" ;;
    track)     shift; _stack_track "$@" ;;
    pr)        shift; _stack_pr "$@" ;;
    restack)   shift; _stack_restack "$@" ;;
    absorb)    shift; _stack_absorb "$@" ;;
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
  echo "  absorb            Fast-forward parent to include current branch"
  echo "  sync              Restack all branches in the stack"
  echo "  sync --pull       Also fetch remote, reparent merged branches, clean up"
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
  git checkout -b "$name" &>/dev/null && git config "branch.$name.stack-parent" "$parent"
  echo "🌱 Created $name → $parent"
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
    echo "✅ Already tracking $branch → $parent"
    return 0
  fi
  git config "branch.$branch.stack-parent" "$parent"
  if [[ -n "$existing" ]]; then
    echo "🔀 Reparented $branch: $existing → $parent"
  else
    echo "🔗 Tracking $branch → $parent"
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

  echo "📤 Pushing $branch..."
  git push -u origin "$branch" --quiet

  if gh pr view "$branch" --json number &>/dev/null; then
    gh pr edit "$branch" --base "$parent" &>/dev/null
    echo "✏️  Updated PR base → $parent"
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

  local before after checked_out_in
  for child in "${children[@]}"; do
    before=$(git rev-parse "$child")

    checked_out_in=$(git worktree list --porcelain 2>/dev/null \
      | awk -v b="refs/heads/$child" '$1=="branch" && $2==b {found=1} $1=="worktree" {wt=$2} found {print wt; found=0}')
    if [[ -n "$checked_out_in" ]]; then
      git -C "$checked_out_in" rebase --autostash "$base" &>/dev/null
    else
      git checkout "$child" &>/dev/null && git rebase --autostash "$base" &>/dev/null
    fi

    after=$(git rev-parse "$child")
    if [[ "$before" != "$after" ]]; then
      echo "🔄 Rebased $child onto $base"
    fi
    _stack_restack "$child"
  done

  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$original_branch" ]]; then
    git checkout "$original_branch" &>/dev/null
  fi
}

_stack_sync() {
  if [[ "${1:-}" == "--pull" ]]; then
    shift
    _stack_sync_remote "$@"
    return
  fi

  local original_branch
  original_branch=$(git rev-parse --abbrev-ref HEAD)

  # Find root of current stack
  local root="$original_branch" p
  while true; do
    p=$(git config "branch.$root.stack-parent" 2>/dev/null || true)
    [[ -z "$p" ]] && break
    root="$p"
  done

  _stack_restack "$root"

  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$original_branch" ]]; then
    git checkout "$original_branch" &>/dev/null
  fi
  echo "✅ Stack synced"
}

# Fast-forward current branch's parent to include this branch's commits
_stack_absorb() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  local parent
  parent=$(git config "branch.$branch.stack-parent" 2>/dev/null || true)

  if [[ -z "$parent" ]]; then
    echo "No stack parent set for $branch" >&2
    return 1
  fi

  if git merge-base --is-ancestor "$branch" "$parent" 2>/dev/null; then
    echo "✅ $parent already contains $branch"
    return 0
  fi

  if git merge-base --is-ancestor "$parent" "$branch" 2>/dev/null; then
    echo "⏩ $parent ← $branch"
    git update-ref "refs/heads/$parent" "$(git rev-parse "$branch")"
  else
    echo "⚠️  $parent and $branch have diverged, cannot fast-forward" >&2
    return 1
  fi
}

# Fetch remote, reparent merged branches onto base, clean up
_stack_sync_remote() {
  local base="${1:-$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')}"
  base="${base:-main}"

  local original_branch
  original_branch=$(git rev-parse --abbrev-ref HEAD)

  echo "📡 Fetching $base..."
  git fetch origin "$base" &>/dev/null && git checkout "$base" &>/dev/null && git pull --ff-only &>/dev/null
  local synced=()

  local branch parent
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    parent=$(git config "branch.$branch.stack-parent" 2>/dev/null || true)
    [[ -z "$parent" ]] && continue
    [[ "$parent" == "$base" ]] && continue

    if git merge-base --is-ancestor "$parent" "$base" 2>/dev/null; then
      echo "🔀 Reparenting $branch: $parent → $base (merged)"
      git config "branch.$branch.stack-parent" "$base"
      git rebase --onto "$base" "$parent" "$branch" &>/dev/null
      synced+=("$parent")
    fi
  done

  for merged in "${synced[@]}"; do
    if git branch -d "$merged" &>/dev/null; then
      echo "🗑️  Deleted $merged"
    fi
  done

  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$original_branch" ]]; then
    git checkout "$original_branch" &>/dev/null
  fi
  echo "✅ Remote sync complete"
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
  local child=""
  for child in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    if [[ "$(git config "branch.$child.stack-parent" 2>/dev/null)" == "$b" ]]; then
      _stack_print_tree "$child" "  $indent"
    fi
  done
}

_stack_list() {
  local start="${1:-$(git rev-parse --abbrev-ref HEAD)}"

  local root="$start" p
  while true; do
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
        echo "🔀 Reparenting $child: $branch → $parent"
        git config "branch.$child.stack-parent" "$parent"
      else
        git config --unset "branch.$child.stack-parent"
      fi
    fi
  done

  git branch -D "$branch" &>/dev/null && echo "🗑️  Deleted $branch"
}
