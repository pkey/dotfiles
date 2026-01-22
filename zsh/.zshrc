# Set up env variables

export PATH=$PATH:/usr/local/bin
export EDITOR=vim
export DOTFILES=$HOME/dotfiles

# Homebrew setup for both macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS Homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ "$(uname)" == "Linux" ]]; then
  # Linuxbrew
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"


source "${DOTFILES}/zsh/antigen/antigen.zsh"

antigen apply

#configure prompt
fpath+="$DOTFILES/zsh/plugins/pure"
autoload -U promptinit; promptinit
prompt pure

# Functions
source "$DOTFILES/functions.sh"

#Set up Aliases:
unalias -a
source "$DOTFILES/aliases.sh"

# Source tools
for tool in "$DOTFILES"/tools/*.sh; do
  [[ -f "$tool" ]] && source "$tool"
done

#Set up History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

#fnm
export PATH="$HOME/.fnm:$PATH"
eval "$(fnm env)"
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"; fi

if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

export MAKEFILES=global_makefile.mk

# Set up fzf
if command -v fzf 1>/dev/null 2>&1; then
    source <(fzf --zsh)
fi

# Set up zoxide
if command -v zoxide 1>/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

[[ -f "$HOME/.localrc" ]] && source "$HOME/.localrc"

# LaTex
export PATH="/Library/TeX/texbin:$PATH"

# Go. Needed in case multiple go versions are installed.
export PATH="$HOME/go/bin:$PATH"
