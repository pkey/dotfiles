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

# Tmux
ln -sf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# Zsh
ln -sf "$DOTFILES/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"

# Claude
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"

# Cursor
mkdir -p "$HOME/.cursor"
rm -rf "$HOME/.cursor/commands"
ln -sf "$DOTFILES/cursor/commands" "$HOME/.cursor/commands"
mkdir -p "$HOME/Library/Application Support/Cursor/User"
ln -sf "$DOTFILES/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
