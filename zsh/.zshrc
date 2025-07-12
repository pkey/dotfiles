# Set up env variables

export PATH=$PATH:/usr/local/bin
export EDITOR=vim
export DOTFILES=$HOME/.dotfiles

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
source ~/.dotfiles/functions.sh

#Set up Aliases: 
unalias -a
source ~/.dotfiles/aliases.sh

#Set up History
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

#fnm 
export PATH=/Users/pauliuskutka/.fnm:$PATH 
eval "`fnm env`" 
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/pauliuskutka/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/pauliuskutka/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/pauliuskutka/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/pauliuskutka/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

export MAKEFILES=global_makefile.mk

# Set up zoxide
if command -v zoxide 1>/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

[[ -f "$DOTFILES/zsh/local.zsh" ]] && source "$DOTFILES/zsh/local.zsh"


