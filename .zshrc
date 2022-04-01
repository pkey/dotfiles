# Set up env variables

export PATH=$PATH:/usr/local/bin
export EDITOR=vim

#Terminal prompt config

autoload -U promptinit; promptinit 
prompt pure 
fpath+=("$HOME/.zsh/pure")
# Create functions

source ~/.dotfiles/functions.sh

#Set up Aliases: 
unalias -a
source ~/.dotfiles/aliases.sh

#Set up History
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history


# Set up Z 
source ~/.dotfiles/z/z.sh 

#snyk
source ~/.dotfiles/workspaces/snyk/.snykrc

#fnm 
export PATH=/Users/pauliuskutka/.fnm:$PATH 
eval "`fnm env`" 