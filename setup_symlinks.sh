#!/usr/bin/env bash

set -e

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Git config & hooks
# Hooks
# Ensure .git/hooks directory exists (it should in a repo, but good to be safe if running oddly)
mkdir -p "$DOTFILES/.git/hooks"
ln -sf "$DOTFILES/git/hooks/post-merge-bootstrap" "$DOTFILES/.git/hooks/post-merge"
chmod +x "$DOTFILES/.git/hooks/post-merge"
# Config
ln -sf "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"

# Vim
ln -sf "$DOTFILES/vim/.vimrc" "$HOME/.vimrc"

# Neovim
mkdir -p "$HOME/.config"
ln -sfn "$DOTFILES/nvim" "$HOME/.config/nvim"

# Tmux
ln -sf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# Zsh
ln -sf "$DOTFILES/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"

# Agents (shared config for Claude, Cursor, etc.)
ln -sf "$DOTFILES/agents/AGENTS.md" "$HOME/.AGENTS.md"

# Claude
mkdir -p "$HOME/.claude"
ln -sf "$HOME/.AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
ln -sfn "$DOTFILES/agents/skills" "$HOME/.claude/skills"

# Local bin
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES/bin"/*; do
  [[ -f "$script" ]] && ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Cursor
mkdir -p "$HOME/.cursor"
ln -sfn "$DOTFILES/agents/skills" "$HOME/.cursor/skills"
# TODO: Remove commands symlinks once Cursor CLI supports skills
mkdir -p "$HOME/.cursor/commands"
for skill in "$DOTFILES/agents/skills"/*/SKILL.md; do
  name=$(basename "$(dirname "$skill")")
  ln -sf "$skill" "$HOME/.cursor/commands/$name.md"
done
ln -sfn "$DOTFILES/cursor/rules" "$HOME/.cursor/rules"
mkdir -p "$HOME/Library/Application Support/Cursor/User"
ln -sf "$DOTFILES/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
