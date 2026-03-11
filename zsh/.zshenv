export DOTFILES="$HOME/dotfiles"

export HISTFILE="$HOME/.zsh_history"

# Homebrew (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Fix GPG signing for git commits
if [[ -t 0 ]]; then
    export GPG_TTY=$(tty)
else
    export GPG_TTY=""
fi

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Ghostty shell integration (custom ZDOTDIR breaks auto-injection)
if [[ "$TERM_PROGRAM" == "ghostty" && -z "$GHOSTTY_RESOURCES_DIR" ]]; then
  export GHOSTTY_RESOURCES_DIR="/Applications/Ghostty.app/Contents/Resources/ghostty"
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi
