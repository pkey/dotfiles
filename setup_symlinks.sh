#!/usr/bin/env bash

set -e

# Remove broken symlinks before mkdir to handle target changes
ensure_dir() {
  local path="$1"
  [[ -L "$path" && ! -e "$path" ]] && rm "$path"
  mkdir -p "$path"
}

# One-way sync: populate target dir with symlinks from source dirs,
# then remove anything not managed by us (direct additions are discarded).
sync_skills() {
  local target_dir="$1"
  shift
  local source_dirs=("$@")

  [[ -L "$target_dir" ]] && rm "$target_dir"
  ensure_dir "$target_dir"

  local -a managed_names=()
  for src in "${source_dirs[@]}"; do
    for skill_dir in "$src"/*/; do
      [[ -d "$skill_dir" ]] || continue
      local name
      name=$(basename "$skill_dir")
      [[ -d "$target_dir/$name" && ! -L "$target_dir/$name" ]] && rm -rf "${target_dir:?}/${name:?}"
      ln -sfn "$skill_dir" "$target_dir/$name"
      managed_names+=("$name")
    done
  done

  for entry in "$target_dir"/*/; do
    [[ -e "$entry" ]] || continue
    local entry_name
    entry_name=$(basename "$entry")
    local found=false
    for m in "${managed_names[@]}"; do
      [[ "$m" == "$entry_name" ]] && { found=true; break; }
    done
    $found || rm -rf "$entry"
  done
}

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Git config & hooks
# Hooks
# Ensure .git/hooks directory exists (it should in a repo, but good to be safe if running oddly)
ensure_dir "$DOTFILES/.git/hooks"
ln -sf "$DOTFILES/git/hooks/post-merge-bootstrap" "$DOTFILES/.git/hooks/post-merge"
chmod +x "$DOTFILES/.git/hooks/post-merge"
# Config — real file (not a symlink) so `git config --global` writes stay local.
if [[ -L "$HOME/.gitconfig" ]] || [[ ! -f "$HOME/.gitconfig" ]]; then
  rm -f "$HOME/.gitconfig"
  cat > "$HOME/.gitconfig" <<STUB
[include]
	path = $DOTFILES/git/.gitconfig
	path = ~/.gitconfig-user
STUB
fi

# GitHub CLI
ensure_dir "$HOME/.config/gh"
ln -sf "$DOTFILES/gh/config.yml" "$HOME/.config/gh/config.yml"

# Worktrunk
ensure_dir "$HOME/.config/worktrunk"
ln -sf "$DOTFILES/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"

# Ghostty
ensure_dir "$HOME/.config/ghostty"
ln -sf "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"

# Helix
ensure_dir "$HOME/.config/helix"
ln -sf "$DOTFILES/helix/config.toml" "$HOME/.config/helix/config.toml"
ln -sf "$DOTFILES/helix/languages.toml" "$HOME/.config/helix/languages.toml"

# Tmux
ln -sf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# Zsh
ln -sf "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
# .zshrc is a generated stub (not a symlink) so installers that append to it
# don't pollute the tracked dotfiles repo.
if [[ -L "$HOME/.zshrc" ]] || [[ ! -f "$HOME/.zshrc" ]]; then
  rm -f "$HOME/.zshrc"
  cat > "$HOME/.zshrc" <<'STUB'
# Dotfiles-managed zsh config — do not edit above this line
source "$HOME/dotfiles/zsh/.zshrc"

# Lines below are auto-added by installers and not tracked in dotfiles
STUB
elif ! grep -q 'source.*dotfiles/zsh/.zshrc' "$HOME/.zshrc"; then
  tmpfile=$(mktemp)
  cat > "$tmpfile" <<'STUB'
# Dotfiles-managed zsh config — do not edit above this line
source "$HOME/dotfiles/zsh/.zshrc"

# Lines below are auto-added by installers and not tracked in dotfiles
STUB
  cat "$HOME/.zshrc" >> "$tmpfile"
  mv "$tmpfile" "$HOME/.zshrc"
fi
ln -sf "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"

# uv
ensure_dir "$HOME/.config/uv"
ln -sf "$DOTFILES/uv/uv.toml" "$HOME/.config/uv/uv.toml"

# AWS CLI
ensure_dir "$HOME/.aws/cli"
ln -sf "$DOTFILES/aws/cli/alias" "$HOME/.aws/cli/alias"

# Agents (shared config for Claude, Cursor, etc.)
ln -sf "$DOTFILES/agents/AGENTS.md" "$HOME/.AGENTS.md"

# Claude
ensure_dir "$HOME/.claude"
ln -sf "$HOME/.AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
sync_skills "$HOME/.claude/skills" "$DOTFILES/agents/skills"

# Local bin
ensure_dir "$HOME/.local/bin"
for script in "$DOTFILES/bin"/*; do
  [[ -f "$script" ]] && ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Cursor
ensure_dir "$HOME/.cursor"
sync_skills "$HOME/.cursor/skills" "$DOTFILES/agents/skills" "$DOTFILES/cursor/skills"
ln -sfn "$DOTFILES/cursor/rules" "$HOME/.cursor/rules"
ensure_dir "$HOME/Library/Application Support/Cursor/User"
ln -sf "$DOTFILES/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"

# Sync agent permissions (from agents/permissions.json to Claude and Cursor)
"$DOTFILES/bin/sync-agent-permissions"
