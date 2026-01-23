#!/usr/bin/env zsh

#--Scaffolding

scaffold() {
  local type="$1"
  local name="$2"
  local scaffold_dir="$DOTFILES/scaffolding"

  # Use fzf to select type if not provided
  if [[ -z "$type" ]]; then
    type=$(for d in "$scaffold_dir"/*/; do
      [[ -f "$d/init.sh" ]] && basename "$d"
    done | fzf --prompt="Select scaffold: ")
    [[ -z "$type" ]] && return 1
  fi

  # Validate type exists
  if [[ ! -f "$scaffold_dir/$type/init.sh" ]]; then
    echo "Error: Unknown scaffold type '$type'" >&2
    return 1
  fi

  # Prompt for name if not provided
  if [[ -z "$name" ]]; then
    printf "Project name: "
    read name
    [[ -z "$name" ]] && return 1
  fi

  # Fail if directory exists
  if [[ -d "$name" ]]; then
    echo "Error: Directory '$name' already exists" >&2
    return 1
  fi

  # Create and enter directory
  mkdir -p "$name" && cd "$name" || return 1

  # Copy all files except init.sh
  for item in "$scaffold_dir/$type"/*; do
    [[ "$(basename "$item")" = "init.sh" ]] && continue
    cp -r "$item" .
  done

  # Run init script
  . "$scaffold_dir/$type/init.sh"
  echo "Created $type project: $name"
}
