DOTFILES="$HOME/dotfiles"
export ZDOTDIR="$DOTFILES/zsh"

# Force fix incorrect USER_ZDOTDIR that points to wrong location
unset USER_ZDOTDIR

# Force correct HISTFILE regardless of USER_ZDOTDIR
export HISTFILE="$HOME/.zsh_history"

# Fix GPG signing for git commits
if [[ -t 0 ]]; then
    export GPG_TTY=$(tty)
else
    export GPG_TTY=""
fi
. "$HOME/.cargo/env"
