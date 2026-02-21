#!/usr/bin/env bash

# Bootstrap script for setting up a new machine

set -e

# === Agent Invocation on Failure ===
_on_bootstrap_error() {
  local exit_code=$?
  local failed_line=${BASH_LINENO[0]}
  local failed_cmd="${BASH_COMMAND}"

  # Disable error handling for cleanup
  set +e
  trap - ERR

  printf "\n\033[1;31mBootstrap failed!\033[0m\n"
  printf "  Command: %s\n" "$failed_cmd"
  printf "  Line: %s\n" "$failed_line"
  printf "  Exit code: %s\n" "$exit_code"

  local agent_enabled="${CC_AGENT_ON_FAILURE:-true}"
  local agent_cmd="${CC_AGENT:-}"

  [[ "$agent_enabled" != "true" ]] && exit $exit_code

  if [[ -z "$agent_cmd" ]]; then
    echo ""; echo "Tip: Set CC_AGENT in ~/.localrc to enable auto-diagnosis"
    exit $exit_code
  fi

  if ! command -v "${agent_cmd%% *}" >/dev/null 2>&1; then
    echo "Agent '${agent_cmd%% *}' not found."

    # Check if we can offer installation
    local install_cmd=""
    case "${agent_cmd%% *}" in
      claude)
        if command -v npm >/dev/null 2>&1; then
          install_cmd="npm install -g @anthropic-ai/claude-code"
        elif command -v brew >/dev/null 2>&1; then
          install_cmd="brew install claude-code"
        fi
        ;;
      cursor)
        install_cmd="curl -fsSL https://cursor.com/install | bash"
        ;;
    esac

    if [[ -n "$install_cmd" ]]; then
      printf "Install it now? [y/N] "
      read -r answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Installing ${agent_cmd%% *}..."
        if eval "$install_cmd"; then
          echo "Installed successfully."
        else
          echo "Installation failed."
          exit $exit_code
        fi
      else
        exit $exit_code
      fi
    else
      exit $exit_code
    fi
  fi

  local script_snippet=""
  local script_path="${BASH_SOURCE[0]}"
  local start=1
  if [[ -f "$script_path" ]]; then
    start=$((failed_line - 5)); [[ $start -lt 1 ]] && start=1
    script_snippet=$(sed -n "${start},$((failed_line + 5))p" "$script_path" 2>/dev/null || echo "")
  fi

  local prompt
  prompt="Bootstrap script failed. Fix the issue and re-run ./bootstrap.sh.

Error: \`$failed_cmd\` at line $failed_line (exit $exit_code)
OS: $(uname -s)

Script context (lines $start-$((failed_line + 5))):
\`\`\`bash
$script_snippet
\`\`\`

Fix the failing command or script, then re-run: ./bootstrap.sh
Keep fixing and re-running until bootstrap completes successfully."

  printf "\n\033[1;33mInvoking %s for diagnosis...\033[0m\n\n" "${agent_cmd%% *}"

  # Use exec to replace this process with the agent (clean slate)
  case "${agent_cmd%% *}" in
    claude)
      exec $agent_cmd --dangerously-skip-permissions "$prompt"
      ;;
    cursor)
      exec $agent_cmd --plan "$prompt"
      ;;
    *)
      exec $agent_cmd "$prompt"
      ;;
  esac
}

_setup_error_trap() {
  trap '_on_bootstrap_error' ERR
}
# === End Agent Invocation Setup ===

# Clone your dotfiles repo if not present
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/pkey/dotfiles.git "$HOME/dotfiles"
fi

# === Root User Setup (VPS) ===
# When running as root on a fresh VPS, create a non-root user with sudo access,
# copy SSH keys, and re-exec bootstrap as that user.
if [[ "$(id -u)" -eq 0 ]]; then
  TARGET_USER="pkey"

  # Allow override via --user <name>
  for i in $(seq 1 $#); do
    arg="${!i}"
    if [[ "$arg" == "--user" ]]; then
      next=$((i + 1))
      TARGET_USER="${!next}"
      break
    fi
  done

  echo "Running as root. Setting up user '$TARGET_USER'..."

  if ! id "$TARGET_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" "$TARGET_USER"
    echo "Created user '$TARGET_USER'"
  fi

  usermod -aG sudo "$TARGET_USER"

  # Enable passwordless sudo for the new user
  echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$TARGET_USER"
  chmod 0440 "/etc/sudoers.d/$TARGET_USER"

  # Copy SSH keys from root
  if [[ -d "$HOME/.ssh" ]]; then
    rsync --archive --chown="$TARGET_USER:$TARGET_USER" "$HOME/.ssh" "/home/$TARGET_USER/"
    echo "SSH keys copied"
  fi

  DOTFILES_PATH="$HOME/dotfiles"
  if [[ -d "$DOTFILES_PATH" ]]; then
    cp -r "$DOTFILES_PATH" "/home/$TARGET_USER/dotfiles"
    chown -R "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/dotfiles"
  fi

  echo "Re-executing bootstrap as '$TARGET_USER'..."
  exec su - "$TARGET_USER" -c "/home/$TARGET_USER/dotfiles/bootstrap.sh $*"
fi
# === End Root User Setup ===

# === Claude CLI — first-class dependency for self-healing ===
if ! command -v claude >/dev/null 2>&1; then
  printf "Installing Claude CLI... 🤖\n"
  curl -fsSL https://claude.ai/install.sh | bash
fi
CC_AGENT="${CC_AGENT:-claude}"

# Authenticate if not already
if ! claude auth status >/dev/null 2>&1; then
  printf "Authenticating Claude CLI...\n"
  claude login --no-open 2>/dev/null || claude login
fi
# === End Claude CLI Setup ===

# Load profile from localrc if exists, default to minimal
LOCALRC="$HOME/.localrc"
if [[ -f "$LOCALRC" ]]; then
  # shellcheck source=/dev/null
  source "$LOCALRC"
fi

# Setup error trap after loading localrc (to access CC_AGENT)
_setup_error_trap

DOTFILES_PROFILE="${DOTFILES_PROFILE:-minimal}"

# Set FULL_INSTALL based on profile
if [[ "$DOTFILES_PROFILE" == "full" ]]; then
  FULL_INSTALL=true
else
  FULL_INSTALL=false
fi

# Parse arguments (can override profile)
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --full)
      FULL_INSTALL=true
      shift
      ;;
    --minimal)
      FULL_INSTALL=false
      shift
      ;;
    --user)
      shift 2  # consumed by root setup block
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done
set -- "${ARGS[@]}"

printf "Bootstrap started... 🚀\n"
if [[ "$FULL_INSTALL" == true || "$OS" == "Darwin" ]]; then
  printf "Running full installation...\n"
else
  printf "Running minimal installation...\n"
fi

export DOTFILES="$HOME/dotfiles"

# Setup submodules
git -C "$DOTFILES" submodule update --init --recursive

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
# Brewfile.local is for machine-specific packages (gitignored)
if command -v brew >/dev/null 2>&1; then
  if [[ "$FULL_INSTALL" == true ]]; then
    cat "$DOTFILES/Brewfile.minimal" "$DOTFILES/Brewfile" > /tmp/Brewfile.all
    [[ -f "$DOTFILES/Brewfile.local" ]] && cat "$DOTFILES/Brewfile.local" >> /tmp/Brewfile.all
    brew bundle --file=/tmp/Brewfile.all
    brew bundle cleanup --force --file=/tmp/Brewfile.all
  else
    cat "$DOTFILES/Brewfile.minimal" > /tmp/Brewfile.all
    [[ -f "$DOTFILES/Brewfile.local" ]] && cat "$DOTFILES/Brewfile.local" >> /tmp/Brewfile.all
    brew bundle --file=/tmp/Brewfile.all
    brew bundle cleanup --force --file=/tmp/Brewfile.all
  fi

  brew update
fi

# setup GPG

if [[ "$OS" == "Darwin" ]]; then
  PINENTRY_PATH="/opt/homebrew/bin/pinentry-mac"
elif command -v pinentry >/dev/null 2>&1; then
  PINENTRY_PATH="$(command -v pinentry)"
else
  PINENTRY_PATH=""
fi

mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
if [[ -n "$PINENTRY_PATH" ]]; then
  echo "pinentry-program $PINENTRY_PATH" > ~/.gnupg/gpg-agent.conf
  chmod 600 ~/.gnupg/gpg-agent.conf
fi
gpgconf --kill all || true

# Enable GPG agent forwarding over SSH (for remote machines running sshd)
if [[ "$OS" == "Linux" ]]; then
  # Detect SSH service name: "ssh" (Debian/Ubuntu) or "sshd" (RHEL/Fedora)
  SSH_SERVICE=""
  for svc in ssh sshd; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      SSH_SERVICE="$svc"
      break
    fi
  done

  if [[ -n "$SSH_SERVICE" ]] && ! grep -q 'StreamLocalBindUnlink yes' /etc/ssh/sshd_config 2>/dev/null; then
    echo "Enabling StreamLocalBindUnlink for GPG forwarding..."
    echo 'StreamLocalBindUnlink yes' | sudo tee -a /etc/ssh/sshd_config >/dev/null
    sudo systemctl restart "$SSH_SERVICE"
    echo "GPG agent forwarding enabled ✅"
  fi
fi

SIGNING_KEY="EAB2D9EB6CD93324"
if gpg --list-keys "$SIGNING_KEY" > /dev/null 2>&1; then
  uid=$(gpg --list-keys --with-colons $SIGNING_KEY | awk -F: '/^uid:/ {print $10; exit}')
  git_name=$(echo "$uid" | sed -E 's/^(.*) <.*>$/\1/')
  git_email=$(echo "$uid" | sed -E 's/^.* <(.*)>$/\1/')

  git config --file ~/.gitconfig-user user.name "$git_name"
  git config --file ~/.gitconfig-user user.email "$git_email"
  git config --file ~/.gitconfig-user user.signingkey $SIGNING_KEY

  echo "Git configured: $git_name <$git_email>"

  # Switch dotfiles remote from HTTPS to SSH
  current_url=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)
  if [[ "$current_url" == https://github.com/* ]]; then
    ssh_url=$(echo "$current_url" | sed 's|https://github.com/|git@github.com:|')
    git -C "$DOTFILES" remote set-url origin "$ssh_url"
    echo "Switched dotfiles remote to SSH: $ssh_url"
  fi
else
  echo "GPG key $SIGNING_KEY not found. Skipping git signing configuration."
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
else
  echo "pipx already installed ✅"
fi

# Fix broken pipx packages if Python interpreter changed
if pipx list 2>&1 | grep -q "invalid interpreter"; then
  echo "Fixing pipx packages with invalid Python interpreter..."
  pipx reinstall-all
fi

# Pipx packages to install (add packages here)
PIPX_PACKAGES=(
  uv
)

install_pipx_package() {
  local package="$1"
  if pipx list | cat | grep -q "package $package"; then
    echo "✔ $package already installed. Skipping."
  else
    echo "➕ Installing $package via pipx..."
    pipx install "$package"
  fi
}

sync_pipx_packages() {
  echo "Syncing pipx packages..."

  # Install all defined packages
  for package in "${PIPX_PACKAGES[@]}"; do
    install_pipx_package "$package"
  done

  # Remove packages not in the list
  local installed
  installed=$(pipx list --short 2>/dev/null | cut -d' ' -f1)

  for pkg in $installed; do
    local keep=false
    for wanted in "${PIPX_PACKAGES[@]}"; do
      if [[ "$pkg" == "$wanted" ]]; then
        keep=true
        break
      fi
    done
    if [[ "$keep" == false ]]; then
      echo "➖ Removing $pkg (not in PIPX_PACKAGES list)..."
      pipx uninstall "$pkg"
    fi
  done
}

install_sudoers() {
  local SRC="$DOTFILES/sudoers"
  local DEST="/etc/sudoers.d/dotfiles"

  [[ ! -f "$SRC" ]] && return 0

  echo "Installing sudoers configuration..."
  local TEMP
  TEMP=$(mktemp)
  sed "s|__DOTFILES__|$DOTFILES|g" "$SRC" > "$TEMP"

  local GROUP="wheel"
  [[ "$OS" == "Linux" ]] && GROUP="root"

  if sudo visudo -c -f "$TEMP" >/dev/null 2>&1; then
    sudo install -m 0440 -o root -g "$GROUP" "$TEMP" "$DEST"
    echo "Sudoers installed"
  else
    echo "Warning: Invalid sudoers syntax, skipping"
  fi
  rm -f "$TEMP"
}

install_crontab() {
  local SRC="$DOTFILES/crontab"

  [[ ! -f "$SRC" ]] && return 0

  echo "Installing crontab entries..."
  local MARKER="# dotfiles-managed"
  local TEMP
  TEMP=$(mktemp)

  # Get existing non-managed entries
  crontab -l 2>/dev/null | grep -v "$MARKER" > "$TEMP" || true

  # Add managed entries from source file
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && ! "$line" =~ ^# ]] && echo "$line $MARKER" >> "$TEMP"
  done < <(sed "s|__DOTFILES__|$DOTFILES|g" "$SRC")

  crontab "$TEMP"
  rm -f "$TEMP"
  echo "Crontab installed"
}

sync_pipx_packages

# tmux
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Setup symlinks
"$DOTFILES/setup_symlinks.sh"

# Save profile choice to localrc
PROFILE_VAR="DOTFILES_PROFILE"
if [[ "$FULL_INSTALL" == true ]]; then
  PROFILE_VALUE="full"
else
  PROFILE_VALUE="minimal"
fi

# Update or add DOTFILES_PROFILE in localrc
if [[ -f "$LOCALRC" ]] && grep -q "^export $PROFILE_VAR=" "$LOCALRC"; then
  sed -i.bak "s/^export $PROFILE_VAR=.*/export $PROFILE_VAR=\"$PROFILE_VALUE\"/" "$LOCALRC" && rm -f "$LOCALRC.bak"
else
  echo "export $PROFILE_VAR=\"$PROFILE_VALUE\"" >> "$LOCALRC"
fi
echo "Profile saved: $PROFILE_VALUE"

# Setup sudoers and crontab
install_sudoers
install_crontab

if tmux info &> /dev/null; then
  tmux source-file ~/.tmux.conf
fi
# end tmux

# Setup pre-commit hooks if pre-commit is available
if command -v pre-commit >/dev/null 2>&1; then
  echo "Installing pre-commit hooks..."
  pre-commit install
fi

# Install Node.js LTS via fnm
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env)"
  if fnm list | grep -qv system; then
    echo "Node.js already installed via fnm ✅"
  else
    echo "Installing Node.js LTS via fnm..."
    fnm install --lts
    LTS_NODE=$(fnm list | grep -v system | head -1 | awk '{print $2}')
    if [[ -n "$LTS_NODE" ]]; then
      fnm default "$LTS_NODE"
      eval "$(fnm env)"
      echo "Node.js $LTS_NODE set as default ✅"
    fi
  fi
fi

# Exit here if not doing full installation
if [[ "$FULL_INSTALL" != true ]]; then
  printf "Minimal bootstrap completed 🎉\n"
  printf "Run with --full flag for complete installation\n"
  exec zsh
fi

printf "Continuing with full installation...\n"

# Update npm, corepack, and pnpm
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env)"

  # Update npm if not latest
  CURRENT_NPM=$(npm --version 2>/dev/null)
  LATEST_NPM=$(npm view npm version 2>/dev/null)
  if [[ "$CURRENT_NPM" != "$LATEST_NPM" ]]; then
    echo "Updating npm ($CURRENT_NPM -> $LATEST_NPM)..."
    npm install -g npm@latest
  else
    echo "npm $CURRENT_NPM ✅"
  fi

  # Install corepack if not available (removed from Node.js >= 22)
  if ! command -v corepack >/dev/null 2>&1; then
    echo "Installing corepack..."
    npm install -g corepack
  fi
  corepack enable

  # Update pnpm if not latest
  CURRENT_PNPM=$(pnpm --version 2>/dev/null)
  LATEST_PNPM=$(npm view pnpm version 2>/dev/null)
  if [[ "$CURRENT_PNPM" != "$LATEST_PNPM" ]]; then
    echo "Updating pnpm ($CURRENT_PNPM -> $LATEST_PNPM)..."
    corepack prepare pnpm@latest --activate
  else
    echo "pnpm $CURRENT_PNPM ✅"
  fi

  # Pre-cache Puppeteer browser for tools like mermaid-cli (npx mmdc)
  npx --yes puppeteer browsers install chrome-headless-shell

  echo "Claude Code already installed ✅"
fi

# macOS-only full install steps
if [[ "$OS" == "Darwin" ]]; then
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
fi

# Configure Docker Desktop Rosetta (macOS only)
if [[ "$OS" == "Darwin" ]]; then
  DOCKER_SETTINGS="$HOME/Library/Group Containers/group.com.docker/settings.json"
  if [[ -f "$DOCKER_SETTINGS" ]]; then
    jq '.useVirtualizationFrameworkRosetta = true' "$DOCKER_SETTINGS" > "$DOCKER_SETTINGS.tmp" && mv "$DOCKER_SETTINGS.tmp" "$DOCKER_SETTINGS"
    echo "Docker Rosetta enabled ✅"
  else
    echo "Docker settings not found. Start Docker Desktop first, then re-run bootstrap."
  fi
fi

echo "Done installing packages"



# Run upgrade
pipx upgrade-all

printf "Bootstrap completed 🎉\n"

# Source .zshrc if it exists
if [[ -f "$HOME/.zshrc" ]]; then
    exec zsh
fi
