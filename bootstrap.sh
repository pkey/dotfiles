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

# Homebrew install and setup for both Linux and macOS
if [[ "$OS" == "Darwin" ]]; then
  BREW_PATH="/opt/homebrew/bin/brew"
elif [[ "$OS" == "Linux" ]]; then
  BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Check if Homebrew is installed at the expected path
if [[ ! -f "$BREW_PATH" ]]; then
  printf "Installing Homebrew... 🍺\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Always eval shellenv to ensure brew is in PATH
eval "$($BREW_PATH shellenv)"

# Install brews (Brewfile should be present in $DOTFILES or current dir)
if command -v brew >/dev/null 2>&1; then
  brew bundle
  brew update
fi

ZSH_PATH="$(command -v zsh)"

# Check if zsh is already the default shell
if [[ "$OS" == "Darwin" ]]; then
  # macOS: use dscl to get user shell
  CURRENT_SHELL=$(dscl . -read "/Users/$USER" UserShell | cut -d' ' -f2)
else
  # Linux: use getent to get user shell
  CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
fi

# Check if current shell is already zsh (regardless of path)
if [[ "$(basename "$CURRENT_SHELL")" == "zsh" ]]; then
  echo "Default shell is already zsh ✅"
else
  echo "Changing default shell to zsh..."
  if sudo chsh -s "$ZSH_PATH" "$USER"; then
    echo "Shell changed to zsh ✅ (log out and back in to apply)"
  else
    echo "❌ Failed to change shell. Try: sudo chsh -s $ZSH_PATH $USER"
  fi
fi

# Install additional packages
echo "Installing additional packages..."

# Ensure pipx is installed
if ! command -v pipx >/dev/null 2>&1; then
  echo "pipx not found. Installing..."
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
else
  echo "pipx already installed ✅"
fi

# Install pipx
install_pipx_package() {
  local package="$1"
  if pipx list | cat | grep -q "package $package"; then
    echo "✔ $package already installed. Skipping."
  else
    echo "➕ Installing $package via pipx..."
    pipx install "$package"
  fi
}

install_pipx_package uv
install_pipx_package llm
install_pipx_package aider-install
# specificall install aider based on docs: https://aider.chat/docs/install.html#get-started-quickly-with-aider-install
aider-install --yes
install_pipx_package vastai

# tmux
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

ln -sf ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf

if tmux info &> /dev/null; then
  tmux source-file ~/.tmux.conf
fi
# end tmux

echo "Done installing packages"

# Sync Config
ln -sf ~/.dotfiles/vim/.vimrc ~/.vimrc
ln -sf ~/.dotfiles/.zshenv ~/.zshenv
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.zprofile ~/.zprofile

# TODO: move to a separate file
# Run upgrade
pipx upgrade-all

# TODO: for some reason doesn't pick up antigen
# source "$DOTFILES/zsh/.zshrc"

printf "Bootstrap completed \U1F389\n"
exec zsh
