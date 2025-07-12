# Homebrew setup for both macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS Homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ "$(uname)" == "Linux" ]]; then
  # Linuxbrew
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"
