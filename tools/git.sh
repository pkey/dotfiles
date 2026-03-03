gwta() {
  local branch="$1"
  local base="${2:-HEAD}"
  local dir_name="${branch//\//-}"
  local worktree_path="/tmp/$(basename "$(git rev-parse --show-toplevel)")-$dir_name"
  git worktree add -b "$branch" "$worktree_path" "$base" && cd "$worktree_path"
}

gwtc() {
  local branch="$1"
  local dir_name="${branch//\//-}"
  local worktree_path="/tmp/$(basename "$(git rev-parse --show-toplevel)")-$dir_name"
  git worktree add "$worktree_path" "$branch" && cd "$worktree_path"
}

gwtl() {
  local selected
  selected=$(git worktree list | fzf --header="Select worktree" | awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

gwtd() {
  local main_wt selected
  main_wt=$(git worktree list | head -1 | awk '{print $1}')
  selected=$(git worktree list | fzf --header="Select worktree to remove" --multi)
  [[ -z "$selected" ]] && return
  local lines=("${(@f)selected}")
  for line in "${lines[@]}"; do
    local wt_path="${line%% *}"
    local branch=""
    if [[ "$line" == *"["*"]"* ]]; then
      branch="${line##*\[}"
      branch="${branch%%\]*}"
    fi
    if git worktree remove "$wt_path"; then
      echo "Removed worktree: $wt_path"
      if [[ -n "$branch" && "$branch" != "detached HEAD" ]]; then
        if git -C "$main_wt" branch -D "$branch" 2>/dev/null; then
          echo "Deleted branch: $branch"
        else
          echo "Note: branch '$branch' not deleted (may not exist or is checked out elsewhere)"
        fi
      fi
    else
      echo "Failed to remove worktree: $wt_path" >&2
    fi
  done
  cd ..
}

gwtla() {
  local search_dir="${1:-$HOME/repos}"
  local selected
  selected=$(fd -H -t d '^\.git$' "$search_dir" -x git -C {//} worktree list 2>/dev/null | \
    grep -v "^$" | \
    fzf --header="All worktrees in $search_dir" | \
    awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}
