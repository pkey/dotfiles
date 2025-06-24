if [[ "$(uname)" == "Darwin" ]]; then
  # Only run this on macOS
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"
