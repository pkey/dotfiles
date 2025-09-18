#!/usr/bin/env bash

# Bootstrap script for setting up a new machine

set -e

# Clone your dotfiles repo if not present
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/pkey/dotfiles.git "$HOME/dotfiles"
fi

# Parse arguments
FULL_INSTALL=false
for arg in "$@"; do
  case $arg in
    --full)
      FULL_INSTALL=true
      shift
      ;;
    *)
      ;;
  esac
done

printf "Bootstrap started... \U1F680\n"
if [[ "$FULL_INSTALL" == true ]]; then
  printf "Running full installation...\n"
else
  printf "Running minimal installation...\n"
fi

export DOTFILES="$HOME/dotfiles"

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
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Always eval shellenv to ensure brew is in PATH
eval "$($BREW_PATH shellenv)"

# Install brews (use minimal or full Brewfile based on installation type)
if command -v brew >/dev/null 2>&1; then
  if [[ "$FULL_INSTALL" == true ]]; then
    cat "$DOTFILES/Brewfile.minimal" "$DOTFILES/Brewfile" > /tmp/Brewfile.all
    brew bundle --file=/tmp/Brewfile.all
    brew bundle cleanup --force --file=/tmp/Brewfile.all
  else
    brew bundle --file="$DOTFILES/Brewfile.minimal"
    brew bundle cleanup --force --file="$DOTFILES/Brewfile.minimal"
  fi

  brew update
fi

# setup GPG

PINENTRY_PATH="/opt/homebrew/bin/pinentry-mac"
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
echo "pinentry-program $PINENTRY_PATH" >> ~/.gnupg/gpg-agent.conf
chmod 600 ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent || true

SIGNING_KEY="EAB2D9EB6CD93324"
uid=$(gpg --list-keys --with-colons $SIGNING_KEY | awk -F: '/^uid:/ {print $10; exit}')
git_name=$(echo "$uid" | sed -E 's/^(.*) <.*>$/\1/')
git_email=$(echo "$uid" | sed -E 's/^.* <(.*)>$/\1/')

git config --file ~/.gitconfig-user user.name "$git_name"
git config --file ~/.gitconfig-user user.email "$git_email"
git config --file ~/.gitconfig-user user.signingkey $SIGNING_KEY



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
else
  echo "pipx already installed ✅"
fi

# Ensure pipx is in the path
pipx ensurepath -q

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

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# tmux
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf

if tmux info &> /dev/null; then
  tmux source-file ~/.tmux.conf
fi
# end tmux

# Essential symlinks for minimal installation
ln -sf ~/dotfiles/.zshenv ~/.zshenv
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/zsh/.zprofile ~/.zprofile
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig

# Setup pre-commit hooks if pre-commit is available
if command -v pre-commit >/dev/null 2>&1; then
  echo "Installing pre-commit hooks..."
  pre-commit install
fi

# Exit here if not doing full installation
if [[ "$FULL_INSTALL" != true ]]; then
  printf "Minimal bootstrap completed \U1F389\n"
  printf "Run with --full flag for complete installation\n"
  exec zsh
fi

printf "Continuing with full installation...\n"

install_pipx_package llm
install_pipx_package aider-install
# specificall install aider based on docs: https://aider.chat/docs/install.html#get-started-quickly-with-aider-install
aider-install --yes
install_pipx_package vastai
install_pipx_package poetry

# Install Cursor if not already installed
if ! command -v cursor >/dev/null 2>&1; then
  echo "Installing Cursor..."
  curl https://cursor.com/install -fsS | bash
else
  echo "Cursor already installed, skipping."
fi

# Install AWS CLI if not already installed
if ! command -v aws >/dev/null 2>&1; then
  echo "Installing AWS CLI..."
  curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
  sudo installer -pkg AWSCLIV2.pkg -target /
  rm AWSCLIV2.pkg
else
  echo "AWS CLI already installed, skipping."
fi

echo "Done installing packages"



# Run upgrade
pipx upgrade-all

printf "Bootstrap completed \U1F389\n"

# Source .zshrc if it exists
if [[ -f "$HOME/.zshrc" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.zshrc"
fi
