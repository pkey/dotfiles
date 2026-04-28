export DOTFILES="$HOME/dotfiles"

export HISTFILE="$HOME/.zsh_history"

# Homebrew
export HOMEBREW_NO_AUTO_UPDATE=1
if [[ "$(uname)" == "Darwin" ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Stabilise SSH agent socket for forwarded agents (tmux / reattached sessions).
# On each fresh SSH login, $SSH_AUTH_SOCK points at a new /tmp/ssh-XXX/agent.NNN
# which is invisible to any shell that inherited an older value. We repoint
# ~/.ssh/agent.sock at the live socket and have every shell use that symlink,
# so long-lived tmux panes keep working across reconnects.
if [[ -n "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" && -S "$SSH_AUTH_SOCK" ]]; then
  ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
elif [[ ! -S "$HOME/.ssh/agent.sock" ]]; then
  # Symlink target died (previous forwarding session ended). Find a live one.
  for sock in /tmp/ssh-*/agent.*(Nom); do
    [[ -O "$sock" && -S "$sock" ]] || continue
    ln -sfn "$sock" "$HOME/.ssh/agent.sock"
    break
  done
fi
[[ -e "$HOME/.ssh/agent.sock" ]] && export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# Fix GPG signing for git commits
if [[ -t 0 ]]; then
    export GPG_TTY=$(tty)
    # Point gpg-agent at the current TTY (needed in tmux / forwarded sessions)
    command -v gpg-connect-agent >/dev/null 2>&1 && \
        gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
else
    export GPG_TTY=""
fi

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Ghostty shell integration (custom ZDOTDIR breaks auto-injection)
# Use $TERM, not $TERM_PROGRAM — the latter leaks to child processes (e.g. Cursor)
if [[ "$TERM" == "xterm-ghostty" && -z "$GHOSTTY_RESOURCES_DIR" ]]; then
  export GHOSTTY_RESOURCES_DIR="/Applications/Ghostty.app/Contents/Resources/ghostty"
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi
