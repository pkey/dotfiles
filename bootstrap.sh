#!/usr/bin/env bash
# 
# Bootstrap script for setting up a new machine

printf "Bootstrap started... \U1F680\n"

export DOTFILES="$HOME/.dotfiles"

# Setup submodules
git -C "$DOTFILES" submodule update --init --recursive

# Setup Git
git config --global core.excludesfile "$DOTFILES/git/.gitignore_global"
ln -sf "$DOTFILES/git/hooks/post-merge-bootstrap" "$DOTFILES/.git/hooks/post-merge"
chmod +x "$DOTFILES/.git/hooks/post-merge"

# Detect OS
OS="$(uname -s)"

# Ensure zsh is installed and set as default shell (Linux with apt only)
if [[ "$OS" == "Linux" ]]; then

  # 1. Setup ZSH
  if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh not found. Installing with apt..."
    sudo apt update && sudo apt install -y zsh
  else
    echo "zsh already installed ✅"
  fi

  ZSH_PATH="$(command -v zsh)"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    echo "Changing default shell to zsh..."
    if chsh -s "$ZSH_PATH"; then
      echo "Shell changed to zsh ✅ (log out and back in to apply)"
    else
      echo "❌ Failed to change shell. Try: sudo chsh -s $ZSH_PATH $USER"
    fi
  else
    echo "Default shell is already zsh ✅"
  fi
fi

if [[ "$OS" == "Darwin" ]]; then
  # Check for Homebrew, install if we don't have it
  if ! command -v brew >/dev/null 2>&1; then
    printf "Installing Homebrew... 🍺\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Install brews
  brew bundle

  # Update homebrew recipes
  brew update
fi

# Install additional packages
echo "Installing additional packages..."

if ! command -v fnm &>/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash
else
  echo "fnm already installed ✅"
fi

echo "Done installing packages"

# Sync Config
ln -sf ~/.dotfiles/vim/.vimrc ~/.vimrc
ln -sf ~/.dotfiles/.zshenv ~/.zsh

# TODO: for some reason doesn't pick up antigen
# source "$DOTFILES/zsh/.zshrc"

printf "Bootstrap completed \U1F389\n"
printf "Reload terminal!"
