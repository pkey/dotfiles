# Set up env variables

export PATH=$PATH:/usr/local/bin
export EDITOR=vim
source "${HOME}/.dotfiles/zsh/antigen/antigen.zsh"

#Terminal prompt config

antigen bundle sindresorhus/pure
PURE_PROMPT_SYMBOL="➜"
antigen apply

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
