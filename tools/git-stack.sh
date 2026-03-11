# Stacked branch workflow: manage chains of dependent branches/PRs.
# Parent-child relationships are stored in git config (branch.<name>.stack-parent),
# shared across worktrees automatically.

gsc() {                                                                      # Stack create: branch off and record parent
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: gsc <branch-name>" >&2
    return 1
  fi
  local parent
  parent=$(git rev-parse --abbrev-ref HEAD)
  git checkout -b "$name" && git config "branch.$name.stack-parent" "$parent"
}

gsr() {                                                                      # Stack restack: rebase all descendants of current branch
  local base="${1:-$(git rev-parse --abbrev-ref HEAD)}"
  local original_branch
  original_branch=$(git rev-parse --abbrev-ref HEAD)

  local children=()
  local branch
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    if [[ "$(git config "branch.$branch.stack-parent")" == "$base" ]]; then
      children+=("$branch")
    fi
  done

  for child in "${children[@]}"; do
    local checked_out_in
    checked_out_in=$(git worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/$child" '$1=="branch" && $2==b {found=1} $1=="worktree" {wt=$2} found {print wt; found=0}')
    if [[ -n "$checked_out_in" ]]; then
      echo "Rebasing $child onto $base (via --onto, checked out in $checked_out_in)"
      local old_base
      old_base=$(git merge-base "$base" "$child")
      git rebase --onto "$base" "$old_base" "$child"
    else
      echo "Rebasing $child onto $base"
      git checkout "$child" && git rebase "$base"
    fi
    gsr "$child"
  done

  if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$original_branch" ]]; then
    git checkout "$original_branch" 2>/dev/null
  fi
}

gss() {                                                                      # Stack sync: reparent merged branches after git pull
  local base="${1:-$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')}"
  base="${base:-main}"

  git fetch origin "$base" && git checkout "$base" && git pull --ff-only

  local original_branch
  original_branch=$(git rev-parse --abbrev-ref HEAD)
  local synced=()

  local branch
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    local parent
    parent=$(git config "branch.$branch.stack-parent")
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

gsl() {                                                                      # Stack list: print the branch chain
  local start="${1:-$(git rev-parse --abbrev-ref HEAD)}"

  # Walk up to find the root
  local root="$start"
  while true; do
    local p
    p=$(git config "branch.$root.stack-parent")
    [[ -z "$p" ]] && break
    root="$p"
  done

  _gsl_print() {
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
      if [[ "$(git config "branch.$child.stack-parent")" == "$b" ]]; then
        _gsl_print "$child" "  $indent"
      fi
    done
  }
  _gsl_print "$root" ""
}

gsd() {                                                                      # Stack delete: remove branch and reparent children
  local branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"
  local parent
  parent=$(git config "branch.$branch.stack-parent")

  if [[ "$branch" == "$(git rev-parse --abbrev-ref HEAD)" ]]; then
    echo "Cannot delete the currently checked out branch" >&2
    return 1
  fi

  # Reparent children to this branch's parent
  local child
  for child in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    if [[ "$(git config "branch.$child.stack-parent")" == "$branch" ]]; then
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
