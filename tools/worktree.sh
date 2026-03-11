# wt - minimal CLI for git worktree management
# Worktrees are created under ~/worktrees/<repo>/<branch>
#
# Usage:
#   wt checkout <branch>              Check out an existing branch in a new worktree
#   wt checkout -b <base> <branch>    Create a new branch from base in a new worktree
#   wt list                           Fuzzy-select a worktree from the current repo and cd into it
#   wt list --all                     Fuzzy-select a worktree across all repos under ~/worktrees
#   wt delete                         Fuzzy-select worktrees from current repo to remove (multi-select)
#   wt delete --all                   Fuzzy-select worktrees across all repos to remove (multi-select)
wt() {
  local cmd="${1:-}"
  case "$cmd" in
    checkout) shift; _wt_checkout "$@" ;;
    list)     shift; _wt_list "$@" ;;
    delete)   shift; _wt_delete "$@" ;;
    *)        _wt_usage; return 1 ;;
  esac
}

# Print usage information
_wt_usage() {
  echo "Usage: wt <command> [options]"
  echo ""
  echo "Commands:"
  echo "  checkout <branch>            Check out existing branch in a new worktree"
  echo "  checkout -b <base> <branch>  Create new branch from base in a new worktree"
  echo "  list                         Fuzzy-select worktree from current repo"
  echo "  list --all                   Fuzzy-select worktree across all repos"
  echo "  delete                       Fuzzy-select worktrees from current repo to remove"
  echo "  delete --all                 Fuzzy-select worktrees across all repos to remove"
}

# Resolve worktree path from branch name: ~/worktrees/<repo>/<branch-with-slashes-replaced>
_wt_path() {
  local branch="$1"
  local dir_name="${branch//\//-}"
  local repo_name="$(basename "$(git rev-parse --show-toplevel)")"
  echo "$HOME/worktrees/$repo_name/$dir_name"
}

# wt checkout — check out or create a branch in a new worktree
_wt_checkout() {
  if [[ "$1" == "-b" ]]; then
    shift
    local base="$1"
    local branch="$2"
    if [[ -z "$base" || -z "$branch" ]]; then
      echo "Usage: wt checkout -b <base> <branch>" >&2
      return 1
    fi
    local repo_name="$(basename "$(git rev-parse --show-toplevel)")"
    local worktree_path="$(_wt_path "$branch")"
    mkdir -p "$HOME/worktrees/$repo_name"
    git worktree add -b "$branch" "$worktree_path" "$base" && cd "$worktree_path"
  else
    local branch="$1"
    if [[ -z "$branch" ]]; then
      echo "Usage: wt checkout <branch>" >&2
      return 1
    fi
    local repo_name="$(basename "$(git rev-parse --show-toplevel)")"
    local worktree_path="$(_wt_path "$branch")"
    mkdir -p "$HOME/worktrees/$repo_name"
    git worktree add "$worktree_path" "$branch" && cd "$worktree_path"
  fi
}

# wt list — fuzzy-select and cd into a worktree
_wt_list() {
  if [[ "$1" == "--all" ]]; then
    _wt_list_all "${2:-$HOME/worktrees}"
    return
  fi

  local selected
  selected=$(git worktree list | fzf --header="Select worktree" | awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

# wt list --all — fuzzy-select a worktree across all repos under a search directory
_wt_list_all() {
  local search_dir="$1"
  local selected
  selected=$(fd -H -t d '^\.git$' "$search_dir" -x git -C {//} worktree list 2>/dev/null | \
    grep -v "^$" | \
    fzf --header="All worktrees in $search_dir" | \
    awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

# wt delete — interactively remove worktrees (and their branches)
_wt_delete() {
  if [[ "$1" == "--all" ]]; then
    _wt_delete_all
    return
  fi

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

# wt delete --all — fuzzy-select worktrees across all repos to remove
_wt_delete_all() {
  local search_dir="${1:-$HOME/worktrees}"
  local selected
  selected=$(fd -H -t d '^\.git$' "$search_dir" -x git -C {//} worktree list 2>/dev/null | \
    grep -v "^$" | \
    fzf --header="Select worktrees to remove (all repos)" --multi)
  [[ -z "$selected" ]] && return

  local lines=("${(@f)selected}")
  for line in "${lines[@]}"; do
    local wt_path="${line%% *}"
    local branch=""
    if [[ "$line" == *"["*"]"* ]]; then
      branch="${line##*\[}"
      branch="${branch%%\]*}"
    fi

    local repo_main_wt
    repo_main_wt=$(git -C "$wt_path" worktree list 2>/dev/null | head -1 | awk '{print $1}')

    if git -C "$wt_path" worktree remove "$wt_path" 2>/dev/null || git worktree remove "$wt_path" 2>/dev/null; then
      echo "Removed worktree: $wt_path"
      if [[ -n "$branch" && "$branch" != "detached HEAD" && -n "$repo_main_wt" ]]; then
        if git -C "$repo_main_wt" branch -D "$branch" 2>/dev/null; then
          echo "Deleted branch: $branch"
        fi
      fi
    else
      echo "Failed to remove worktree: $wt_path" >&2
    fi
  done
}
