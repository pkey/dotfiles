#!/usr/bin/env bash

# OS-aware package installer
# Reads packages.yaml and dispatches to brew (macOS) or apt (Linux/Ubuntu)

set -e

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PACKAGES_FILE="$DOTFILES/packages.yaml"
PACKAGES_LOCAL="$DOTFILES/packages.local.yaml"
FULL_INSTALL="${FULL_INSTALL:-false}"
OS="$(uname -s)"

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    return
  fi
  echo "Downloading yq..."
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
  esac
  local os_name
  case "$OS" in
    Darwin) os_name="darwin" ;;
    Linux) os_name="linux" ;;
  esac
  curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_${os_name}_${arch}" -o /tmp/yq
  chmod +x /tmp/yq
  export PATH="/tmp:$PATH"
}

read_packages() {
  local file="$1"
  local section="$2"
  local count
  count=$(yq -r ".${section} | length // 0" "$file")
  for ((i = 0; i < count; i++)); do
    local entry
    entry=$(yq -r ".${section}[$i]" "$file")
    if [[ "$entry" != "null" ]]; then
      echo "$entry"
    fi
  done
}

get_field() {
  echo "$1" | yq -r ".$2 // \"\""
}

install_macos() {
  local sections=("common")
  [[ "$FULL_INSTALL" == true ]] && sections+=("full")

  for section in "${sections[@]}"; do
    local count
    count=$(yq -r ".${section} | length // 0" "$PACKAGES_FILE")
    for ((i = 0; i < count; i++)); do
      local is_string
      is_string=$(yq -r ".${section}[$i] | type" "$PACKAGES_FILE")
      if [[ "$is_string" == "!!str" ]]; then
        local pkg
        pkg=$(yq -r ".${section}[$i]" "$PACKAGES_FILE")
        brew install "$pkg" 2>/dev/null || true
      else
        local name brew_name
        name=$(yq -r ".${section}[$i].name" "$PACKAGES_FILE")
        brew_name=$(yq -r ".${section}[$i].brew // \"\"" "$PACKAGES_FILE")
        brew install "${brew_name:-$name}" 2>/dev/null || true
      fi
    done
  done

  # macOS-only packages
  local macos_count
  macos_count=$(yq -r '.macos_only | length // 0' "$PACKAGES_FILE")
  for ((i = 0; i < macos_count; i++)); do
    local pkg
    pkg=$(yq -r ".macos_only[$i]" "$PACKAGES_FILE")
    brew install "$pkg" 2>/dev/null || true
  done

  # Casks (full install only)
  if [[ "$FULL_INSTALL" == true ]]; then
    local cask_count
    cask_count=$(yq -r '.macos_casks | length // 0' "$PACKAGES_FILE")
    for ((i = 0; i < cask_count; i++)); do
      local cask
      cask=$(yq -r ".macos_casks[$i]" "$PACKAGES_FILE")
      brew install --cask "$cask" 2>/dev/null || true
    done
  fi

  # Local packages
  if [[ -f "$PACKAGES_LOCAL" ]]; then
    install_macos_local
  fi
}

install_macos_local() {
  for section in common full macos_only; do
    local count
    count=$(yq -r ".${section} | length // 0" "$PACKAGES_LOCAL")
    [[ "$section" == "full" && "$FULL_INSTALL" != true ]] && continue
    for ((i = 0; i < count; i++)); do
      local is_string
      is_string=$(yq -r ".${section}[$i] | type" "$PACKAGES_LOCAL")
      if [[ "$is_string" == "!!str" ]]; then
        brew install "$(yq -r ".${section}[$i]" "$PACKAGES_LOCAL")" 2>/dev/null || true
      else
        local name brew_name
        name=$(yq -r ".${section}[$i].name" "$PACKAGES_LOCAL")
        brew_name=$(yq -r ".${section}[$i].brew // \"\"" "$PACKAGES_LOCAL")
        brew install "${brew_name:-$name}" 2>/dev/null || true
      fi
    done
  done
  local cask_count
  cask_count=$(yq -r '.macos_casks | length // 0' "$PACKAGES_LOCAL")
  if [[ "$FULL_INSTALL" == true ]]; then
    for ((i = 0; i < cask_count; i++)); do
      brew install --cask "$(yq -r ".macos_casks[$i]" "$PACKAGES_LOCAL")" 2>/dev/null || true
    done
  fi
}

collect_expected_formulas() {
  local file="$1"
  [[ -f "$file" ]] || return

  local sections=("common" "macos_only")
  [[ "$FULL_INSTALL" == true ]] && sections+=("full")

  for section in "${sections[@]}"; do
    local count
    count=$(yq -r ".${section} | length // 0" "$file")
    for ((i = 0; i < count; i++)); do
      local is_string
      is_string=$(yq -r ".${section}[$i] | type" "$file")
      if [[ "$is_string" == "!!str" ]]; then
        yq -r ".${section}[$i]" "$file"
      else
        local name brew_name
        name=$(yq -r ".${section}[$i].name" "$file")
        brew_name=$(yq -r ".${section}[$i].brew // \"\"" "$file")
        echo "${brew_name:-$name}"
      fi
    done
  done
}

collect_expected_casks() {
  local file="$1"
  [[ -f "$file" ]] || return
  [[ "$FULL_INSTALL" == true ]] || return

  local count
  count=$(yq -r '.macos_casks | length // 0' "$file")
  for ((i = 0; i < count; i++)); do
    yq -r ".macos_casks[$i]" "$file"
  done
}

cleanup_macos() {
  echo "Cleaning up unlisted brew packages..."

  local expected_formulas=()
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && expected_formulas+=("$pkg")
  done < <(collect_expected_formulas "$PACKAGES_FILE"; collect_expected_formulas "$PACKAGES_LOCAL")

  local expected_casks=()
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && expected_casks+=("$pkg")
  done < <(collect_expected_casks "$PACKAGES_FILE"; collect_expected_casks "$PACKAGES_LOCAL")

  # Remove unexpected formulas
  while IFS= read -r installed; do
    local found=false
    for expected in "${expected_formulas[@]}"; do
      if [[ "$installed" == "$expected" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      echo "Removing formula: $installed"
      brew uninstall "$installed" 2>/dev/null || true
    fi
  done < <(brew list --formula -1)

  # Remove unexpected casks (only when FULL_INSTALL)
  if [[ "$FULL_INSTALL" == true ]]; then
    while IFS= read -r installed; do
      local found=false
      for expected in "${expected_casks[@]}"; do
        if [[ "$installed" == "$expected" ]]; then
          found=true
          break
        fi
      done
      if [[ "$found" == false ]]; then
        echo "Removing cask: $installed"
        brew uninstall --cask "$installed" 2>/dev/null || true
      fi
    done < <(brew list --cask -1)
  fi

  brew autoremove 2>/dev/null || true
  echo "Cleanup complete"
}

install_linux() {
  mkdir -p "$HOME/.local/bin"

  local sections=("common")
  [[ "$FULL_INSTALL" == true ]] && sections+=("full")

  local apt_packages=()
  local setup_commands=()
  local post_commands=()
  local script_commands=()

  for section in "${sections[@]}"; do
    local count
    count=$(yq -r ".${section} | length // 0" "$PACKAGES_FILE")
    for ((i = 0; i < count; i++)); do
      local is_string
      is_string=$(yq -r ".${section}[$i] | type" "$PACKAGES_FILE")
      if [[ "$is_string" == "!!str" ]]; then
        apt_packages+=("$(yq -r ".${section}[$i]" "$PACKAGES_FILE")")
      else
        local name apt_name apt_setup post_apt script
        name=$(yq -r ".${section}[$i].name" "$PACKAGES_FILE")
        apt_name=$(yq -r ".${section}[$i].apt" "$PACKAGES_FILE")
        [[ "$apt_name" == "null" ]] && apt_name=""
        apt_setup=$(yq -r ".${section}[$i].apt_setup // \"\"" "$PACKAGES_FILE")
        post_apt=$(yq -r ".${section}[$i].post_apt // \"\"" "$PACKAGES_FILE")
        script=$(yq -r ".${section}[$i].script // \"\"" "$PACKAGES_FILE")

        [[ -n "$apt_setup" ]] && setup_commands+=("$apt_setup")

        if [[ "$apt_name" == "false" ]]; then
          [[ -n "$script" ]] && script_commands+=("echo \"Installing $name via script...\" && $script")
        elif [[ -n "$apt_name" ]]; then
          # apt_name may contain multiple packages (space-separated)
          # shellcheck disable=SC2206
          apt_packages+=($apt_name)
          [[ -n "$post_apt" ]] && post_commands+=("$post_apt")
        else
          apt_packages+=("$name")
          [[ -n "$post_apt" ]] && post_commands+=("$post_apt")
        fi
      fi
    done
  done

  # Local packages
  if [[ -f "$PACKAGES_LOCAL" ]]; then
    for section in common full; do
      [[ "$section" == "full" && "$FULL_INSTALL" != true ]] && continue
      local count
      count=$(yq -r ".${section} | length // 0" "$PACKAGES_LOCAL")
      for ((i = 0; i < count; i++)); do
        local is_string
        is_string=$(yq -r ".${section}[$i] | type" "$PACKAGES_LOCAL")
        if [[ "$is_string" == "!!str" ]]; then
          apt_packages+=("$(yq -r ".${section}[$i]" "$PACKAGES_LOCAL")")
        else
          local name apt_name
          name=$(yq -r ".${section}[$i].name" "$PACKAGES_LOCAL")
          apt_name=$(yq -r ".${section}[$i].apt" "$PACKAGES_LOCAL")
          [[ "$apt_name" == "null" ]] && apt_name=""
          if [[ "$apt_name" != "false" ]]; then
            apt_packages+=("${apt_name:-$name}")
          fi
        fi
      done
    done
  fi

  # Run apt_setup commands (add repos, keys, etc.)
  for cmd in "${setup_commands[@]}"; do
    echo "Running apt setup..."
    eval "$cmd"
  done

  # Install all apt packages in one batch
  if [[ ${#apt_packages[@]} -gt 0 ]]; then
    echo "Installing apt packages: ${apt_packages[*]}"
    sudo apt-get update
    sudo apt-get install -y "${apt_packages[@]}"
  fi

  # Run post-install commands (symlinks, etc.)
  for cmd in "${post_commands[@]}"; do
    eval "$cmd"
  done

  # Run script-based installs
  for cmd in "${script_commands[@]}"; do
    eval "$cmd"
  done
}

ensure_yq

echo "Installing packages from $PACKAGES_FILE..."
if [[ "$OS" == "Darwin" ]]; then
  install_macos
  [[ "$SKIP_CLEANUP" != true ]] && cleanup_macos
elif [[ "$OS" == "Linux" ]]; then
  install_linux
else
  echo "Unsupported OS: $OS"
  exit 1
fi

echo "Package installation complete"
