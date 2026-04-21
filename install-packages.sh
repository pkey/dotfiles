#!/usr/bin/env bash

# OS-aware package installer
# Reads packages.yaml and dispatches to brew (macOS/Linux) or apt (Linux fallback)

set -e

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PACKAGES_FILE="$DOTFILES/packages.yaml"
PACKAGES_LOCAL="$DOTFILES/packages.local.yaml"
FULL_INSTALL="${FULL_INSTALL:-false}"
OS="$(uname -s)"

ensure_yq() {
  # Require Mike Farah's Go-based yq (not the Python jq wrapper).
  # Detect it by checking that type output uses YAML tags (e.g. "!!str").
  if command -v yq >/dev/null 2>&1; then
    local yq_type
    yq_type=$(printf 'foo: bar\n' | yq -r '.foo | type' 2>/dev/null)
    if [[ "$yq_type" == "!!str" ]]; then
      return
    fi
  fi
  echo "Downloading yq (Go version)..."
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

# generate_brewfile <brewfile> <packages_yaml> [taps_key]
# taps_key defaults to "macos_taps"; use "linux_taps" on Linux
generate_brewfile() {
  local brewfile="$1"
  local file="$2"
  local taps_key="${3:-macos_taps}"
  [[ -f "$file" ]] || return

  local tap_count
  tap_count=$(yq -r ".${taps_key} | length // 0" "$file")
  for ((i = 0; i < tap_count; i++)); do
    echo "tap \"$(yq -r ".${taps_key}[$i]" "$file")\"" >> "$brewfile"
  done

  local sections=("common")
  [[ "$OS" == "Darwin" ]] && sections+=("macos_only")
  [[ "$FULL_INSTALL" == true ]] && sections+=("full")

  for section in "${sections[@]}"; do
    local count
    count=$(yq -r ".${section} | length // 0" "$file")
    for ((i = 0; i < count; i++)); do
      local is_string
      is_string=$(yq -r ".${section}[$i] | type" "$file")
      if [[ "$is_string" == "!!str" ]]; then
        echo "brew \"$(yq -r ".${section}[$i]" "$file")\"" >> "$brewfile"
      else
        local name brew_name
        name=$(yq -r ".${section}[$i].name" "$file")
        brew_name=$(yq -r ".${section}[$i].brew // \"\"" "$file")
        [[ "$brew_name" == "false" ]] && continue
        echo "brew \"${brew_name:-$name}\"" >> "$brewfile"
      fi
    done
  done

  if [[ "$FULL_INSTALL" == true && "$OS" == "Darwin" ]]; then
    local cask_count
    cask_count=$(yq -r '.macos_casks | length // 0' "$file")
    for ((i = 0; i < cask_count; i++)); do
      echo "cask \"$(yq -r ".macos_casks[$i]" "$file")\"" >> "$brewfile"
    done
  fi
}

run_macos() {
  local brewfile
  brewfile=$(mktemp /tmp/Brewfile.XXXXXX)
  # shellcheck disable=SC2064
  trap "rm -f '$brewfile'" EXIT

  generate_brewfile "$brewfile" "$PACKAGES_FILE"
  [[ -f "$PACKAGES_LOCAL" ]] && generate_brewfile "$brewfile" "$PACKAGES_LOCAL"

  # Remove casks listed in packages.local.yaml exclude_casks
  if [[ -f "$PACKAGES_LOCAL" ]]; then
    local exclude_count
    exclude_count=$(yq -r '.exclude_casks | length // 0' "$PACKAGES_LOCAL")
    for ((i = 0; i < exclude_count; i++)); do
      local cask_name tmpfile
      cask_name=$(yq -r ".exclude_casks[$i]" "$PACKAGES_LOCAL")
      tmpfile=$(mktemp)
      grep -v "cask \"$cask_name\"" "$brewfile" > "$tmpfile"
      mv "$tmpfile" "$brewfile"
    done
  fi

  echo "Generated Brewfile:"
  cat "$brewfile"
  echo ""

  brew bundle --file="$brewfile"

  if [[ "$SKIP_CLEANUP" != true ]]; then
    echo "Cleaning up unlisted brew packages..."
    brew bundle cleanup --force --file="$brewfile"
    brew autoremove 2>/dev/null || true
    echo "Cleanup complete"
  fi
}

install_linux() {
  mkdir -p "$HOME/.local/bin"

  local sections=("common")
  [[ "$FULL_INSTALL" == true ]] && sections+=("full")

  # === Brew step ===
  local HAS_BREW=false
  command -v brew >/dev/null 2>&1 && HAS_BREW=true

  if [[ "$HAS_BREW" == true ]]; then
    local brewfile
    brewfile=$(mktemp /tmp/Brewfile.XXXXXX)
    # shellcheck disable=SC2064
    trap "rm -f '$brewfile'" EXIT

    generate_brewfile "$brewfile" "$PACKAGES_FILE" "linux_taps"
    [[ -f "$PACKAGES_LOCAL" ]] && generate_brewfile "$brewfile" "$PACKAGES_LOCAL" "linux_taps"

    echo "Generated Linux Brewfile:"
    cat "$brewfile"
    echo ""
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$brewfile"
  fi

  # === Apt step ===
  # When brew is available: only install packages with explicit apt: field
  # When brew is not available: install everything via apt (original behavior)
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
        # Simple string package: brew handles it; apt only if no brew
        [[ "$HAS_BREW" == false ]] && apt_packages+=("$(yq -r ".${section}[$i]" "$PACKAGES_FILE")")
      else
        local name apt_name apt_setup post_apt script brew_name
        name=$(yq -r ".${section}[$i].name" "$PACKAGES_FILE")
        apt_name=$(yq -r ".${section}[$i].apt" "$PACKAGES_FILE")
        brew_name=$(yq -r ".${section}[$i].brew // \"\"" "$PACKAGES_FILE")
        [[ "$apt_name" == "null" ]] && apt_name=""
        apt_setup=$(yq -r ".${section}[$i].apt_setup // \"\"" "$PACKAGES_FILE")
        post_apt=$(yq -r ".${section}[$i].post_apt // \"\"" "$PACKAGES_FILE")
        script=$(yq -r ".${section}[$i].script // \"\"" "$PACKAGES_FILE")

        # brew: false → use apt or script
        if [[ "$brew_name" == "false" ]]; then
          if [[ "$apt_name" == "false" ]]; then
            [[ -n "$script" ]] && script_commands+=("echo \"Installing $name via script...\" && $script")
          elif [[ -n "$apt_name" ]]; then
            [[ -n "$apt_setup" ]] && setup_commands+=("$apt_setup")
            # shellcheck disable=SC2206
            apt_packages+=($apt_name)
            [[ -n "$post_apt" ]] && post_commands+=("$post_apt")
          else
            apt_packages+=("$name")
          fi
          continue
        fi

        if [[ "$HAS_BREW" == true ]]; then
          # Package handled by brew; still install via apt if explicitly specified
          # (e.g. build-essential: needed as brew prerequisite)
          if [[ -n "$apt_name" && "$apt_name" != "false" ]]; then
            # shellcheck disable=SC2206
            apt_packages+=($apt_name)
            [[ -n "$post_apt" ]] && post_commands+=("$post_apt")
          fi
          continue
        fi

        # No brew: fall back to apt
        [[ -n "$apt_setup" ]] && setup_commands+=("$apt_setup")
        if [[ "$apt_name" == "false" ]]; then
          [[ -n "$script" ]] && script_commands+=("echo \"Installing $name via script...\" && $script")
        elif [[ -n "$apt_name" ]]; then
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
          [[ "$HAS_BREW" == false ]] && apt_packages+=("$(yq -r ".${section}[$i]" "$PACKAGES_LOCAL")")
        else
          local name apt_name brew_name
          name=$(yq -r ".${section}[$i].name" "$PACKAGES_LOCAL")
          apt_name=$(yq -r ".${section}[$i].apt" "$PACKAGES_LOCAL")
          brew_name=$(yq -r ".${section}[$i].brew // \"\"" "$PACKAGES_LOCAL")
          [[ "$apt_name" == "null" ]] && apt_name=""
          if [[ "$HAS_BREW" == true ]]; then
            if [[ "$brew_name" == "false" && "$apt_name" != "false" ]]; then
              apt_packages+=("${apt_name:-$name}")
            elif [[ -n "$apt_name" && "$apt_name" != "false" ]]; then
              # shellcheck disable=SC2206
              apt_packages+=($apt_name)
            fi
          else
            if [[ "$apt_name" != "false" ]]; then
              apt_packages+=("${apt_name:-$name}")
            fi
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
  run_macos
elif [[ "$OS" == "Linux" ]]; then
  install_linux
else
  echo "Unsupported OS: $OS"
  exit 1
fi

echo "Package installation complete"
