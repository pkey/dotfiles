#Set workspace
if [ ! -f ~/.scripts/.env ]
  then
    echo "Environment file does not exist. Using default variables"
  else
    source ~/.scripts/.env
fi

if [[ -z "${WORKSPACE}" ]];
  then
    export WORKSPACE="Personal"
fi

echo "Workspace: ${WORKSPACE}"

#Pure prompt config 

autoload -U promptinit; promptinit 

prompt pure 

#Functions
#--Git

git_current_branch () {
    if ! git rev-parse 2> /dev/null
    then
        print "$0: not a repository: $PWD" >&2
        return 1
    fi
    local ref="$(git symbolic-ref HEAD 2> /dev/null)"
    if [[ -n "$ref" ]]
    then
        print "${ref#refs/heads/}"
        return 0
    else
        return 1
    fi
}
#Aliases: 
source ~/.scripts/aliases/main-alias.sh

#Work
#TODO: add completely separate config for work
if [[ "$WORKSPACE" = "Swedbank" ]]; then
  source ~/.scripts/swedbank/swedbank.sh
fi

#Add history appending
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

#Ban facebook by default
#TODO: Ban facebook, but only on home pc

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH=$PATH:/usr/local/bin
