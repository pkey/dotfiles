#!/usr/bin/env zsh

TASKS_DIR="$HOME/tasks"
REPOS_DIR="$HOME/repos"

_get_base_ref() {
  local repo_path="$1"

  if [[ -f "$repo_path/.taskrc" ]]; then
    local DEFAULT_BRANCH=""
    source "$repo_path/.taskrc"
    if [[ -n "$DEFAULT_BRANCH" ]] && git -C "$repo_path" rev-parse --verify "origin/$DEFAULT_BRANCH" &>/dev/null; then
      echo "origin/$DEFAULT_BRANCH"
      return 0
    fi
  fi

  if git -C "$repo_path" rev-parse --verify origin/main &>/dev/null; then
    echo "origin/main"
  elif git -C "$repo_path" rev-parse --verify origin/master &>/dev/null; then
    echo "origin/master"
  fi
}

_copy_taskrc_files() {
  local repo_path="$1"
  local worktree_path="$2"

  # Symlink AGENTS.local.md if it exists in source repo
  if [[ -f "$repo_path/AGENTS.local.md" ]] && [[ ! -e "$worktree_path/AGENTS.local.md" ]]; then
    ln -s "$repo_path/AGENTS.local.md" "$worktree_path/AGENTS.local.md"
    echo "Linked: AGENTS.local.md"
  fi

  # Continue with COPY_FILES from .taskrc
  if [[ ! -f "$repo_path/.taskrc" ]]; then
    return 0
  fi

  local COPY_FILES=()
  source "$repo_path/.taskrc"

  for item in "${COPY_FILES[@]}"; do
    local src="$repo_path/$item"
    local dst="$worktree_path/$item"

    if [[ ! -e "$src" ]]; then
      echo "Warning: '$item' not found in $repo_path" >&2
      continue
    fi

    if [[ -e "$dst" ]]; then
      echo "Skipping '$item': already exists" >&2
      continue
    fi

    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
    echo "Copied: $item"
  done
}

task() {
  local cmd="${1:-}"
  case "$cmd" in
    add) shift; _task_add "$@" ;;
    go)  _task_go ;;
    ls)  _task_ls ;;
    *)   _task_new "$@" ;;
  esac
}

_task_new() {
  local name="$1"
  local branch_name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: task <name>" >&2
    return 1
  fi

  name="${name//\//-}"
  local task_dir="$TASKS_DIR/$name"
  if [[ -d "$task_dir" ]]; then
    echo "Task '$name' already exists" >&2
    return 1
  fi

  if [[ ! -d "$REPOS_DIR" ]]; then
    echo "Repos directory not found: $REPOS_DIR" >&2
    return 1
  fi

  local repos
  repos=$(ls "$REPOS_DIR" | fzf --multi --prompt="Select repos for task '$name': ")

  mkdir -p "$task_dir"

  if [[ -n "$repos" ]]; then
    echo "$repos" | while read -r repo; do
      [[ -z "$repo" ]] && continue
      local repo_path="$REPOS_DIR/$repo"
      local worktree_path="$task_dir/$repo"

      if [[ ! -d "$repo_path/.git" ]] && [[ ! -f "$repo_path/.git" ]]; then
        echo "Skipping '$repo': not a git repository" >&2
        continue
      fi

      echo "Creating worktree for $repo..."
      local base_ref
      base_ref=$(_get_base_ref "$repo_path")

      if [[ -n "$base_ref" ]]; then
        git -C "$repo_path" worktree add "$worktree_path" -b "$branch_name" "$base_ref" || \
          git -C "$repo_path" worktree add "$worktree_path" "$branch_name" || \
          echo "Failed to create worktree for $repo" >&2
      else
        echo "Failed to create worktree for $repo: no default branch found (add .taskrc with DEFAULT_BRANCH)" >&2
      fi

      if [[ -d "$worktree_path" ]]; then
        _copy_taskrc_files "$repo_path" "$worktree_path"
      fi
    done
  fi

  local agents_file="$task_dir/AGENTS.md"
  cat > "$agents_file" << EOF
# Task: $branch_name

## Objective


## Context

EOF

  ${EDITOR:-vim} "$agents_file"
  cd "$task_dir"
}

_task_add() {
  local name="$1"

  if [[ -z "$name" ]]; then
    if [[ "$PWD" == "$TASKS_DIR"/* ]]; then
      local dir="$PWD" depth=0
      while [[ "$dir" != "$TASKS_DIR" ]] && [[ "$dir" != "/" ]] && (( depth < 3 )); do
        if [[ -f "$dir/AGENTS.md" ]]; then
          name="${dir#$TASKS_DIR/}"
          break
        fi
        dir="${dir:h}"
        (( depth++ ))
      done
      if [[ -z "$name" ]]; then
        echo "Could not detect task (no AGENTS.md found within 3 levels)" >&2
        return 1
      fi
    else
      echo "Usage: task add <name> (or run from inside a task folder)" >&2
      return 1
    fi
  fi

  local task_dir="$TASKS_DIR/$name"
  if [[ ! -d "$task_dir" ]]; then
    echo "Task '$name' does not exist" >&2
    return 1
  fi

  if [[ ! -d "$REPOS_DIR" ]]; then
    echo "Repos directory not found: $REPOS_DIR" >&2
    return 1
  fi

  local repos
  repos=$(ls "$REPOS_DIR" | fzf --multi --prompt="Add repos to task '$name': ")
  if [[ -z "$repos" ]]; then
    echo "No repos selected" >&2
    return 1
  fi

  echo "$repos" | while read -r repo; do
    [[ -z "$repo" ]] && continue
    local repo_path="$REPOS_DIR/$repo"
    local worktree_path="$task_dir/$repo"

    if [[ -d "$worktree_path" ]]; then
      echo "Skipping '$repo': already in task" >&2
      continue
    fi

    if [[ ! -d "$repo_path/.git" ]] && [[ ! -f "$repo_path/.git" ]]; then
      echo "Skipping '$repo': not a git repository" >&2
      continue
    fi

    echo "Creating worktree for $repo..."
    local base_ref
    base_ref=$(_get_base_ref "$repo_path")

    if [[ -n "$base_ref" ]]; then
      git -C "$repo_path" worktree add "$worktree_path" -b "$name" "$base_ref" || \
        git -C "$repo_path" worktree add "$worktree_path" "$name" || \
        echo "Failed to create worktree for $repo" >&2
    else
      echo "Failed to create worktree for $repo: no default branch found (add .taskrc with DEFAULT_BRANCH)" >&2
    fi

    if [[ -d "$worktree_path" ]]; then
      _copy_taskrc_files "$repo_path" "$worktree_path"
    fi
  done
}

_task_ls() {
  if [[ ! -d "$TASKS_DIR" ]]; then
    echo "Tasks directory not found: $TASKS_DIR" >&2
    return 1
  fi

  local task
  task=$(ls "$TASKS_DIR" | fzf \
    --prompt="Tasks: " \
    --preview="cat '$TASKS_DIR/{}/AGENTS.md' 2>/dev/null || echo 'No AGENTS.md found'" \
    --preview-window=right:60%:wrap)

  if [[ -n "$task" ]]; then
    cd "$TASKS_DIR/$task"
  fi
}

_task_go() {
  if [[ ! -d "$TASKS_DIR" ]]; then
    echo "Tasks directory not found: $TASKS_DIR" >&2
    return 1
  fi

  local task
  task=$(ls "$TASKS_DIR" | fzf --prompt="Go to task: ")
  if [[ -z "$task" ]]; then
    return 0
  fi

  cd "$TASKS_DIR/$task"
}
