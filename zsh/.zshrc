# Fix backspace handling over SSH on some Linux distros
[[ "$OSTYPE" == linux* ]] && stty erase '^?' 2>/dev/null

# Set up env variables

export PATH=$PATH:/usr/local/bin
export EDITOR=vim
export DOTFILES=$HOME/dotfiles

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
eval "$(fnm env --use-on-cd)"
# Google Cloud SDK (installed via Homebrew)
if [ -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"
fi

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

# Set up direnv
if command -v direnv 1>/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# Set up CircleCI CLI completion
if command -v circleci 1>/dev/null 2>&1; then
    source <(circleci completion zsh)
fi

[[ -f "$HOME/.localrc" ]] && source "$HOME/.localrc"

# LaTex
export PATH="/Library/TeX/texbin:$PATH"

# Go. Needed in case multiple go versions are installed.
export PATH="$HOME/go/bin:$PATH"
