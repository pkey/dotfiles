#Set workspace
if [ ! -f ~/.dotfiles/.env ]
  then
    echo "No environment file. Please create one"
    return
  else
    source ~/.dotfiles/.env
fi

if [[ -z "${WORKSPACE}" ]];
  then
    if [[ -z "${DEFAULT_WORKSPACE}" ]] 
    then
      export WORKSPACE="personal"
    else export WORKSPACE=${DEFAULT_WORKSPACE}
    fi
fi

source ~/.dotfiles/workspaces/${WORKSPACE}/${WORKSPACE}.sh

#These environments variables overwrite the default ones
source ~/.dotfiles/workspaces/${WORKSPACE}/.env

echo "Workspace: ${WORKSPACE}"

# Set Aliases for workspace switching

for d in $(dirname $0)/workspaces/* ; do
    workspace=$(basename $d)
    alias $workspace="export WORKSPACE=${workspace}; source ~/.zshrc"
done

#Terminal prompt config

autoload -U promptinit; promptinit 
prompt pure 

# Create functions
#TODO: Move this to separate folder

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
#Set up Aliases: 
source ~/.dotfiles/aliases/main-alias.sh

#Set up History
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

#Ban facebook by default
#TODO: Ban facebook, but only on home pc

# Set up NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Set up PATH
export PATH=$PATH:/usr/local/bin

# Set up GIT
git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_EMAIL

# Set up Z 
source ~/.dotfiles/z/z.sh 

# Set up GCloud
#TODO: Review this

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/pauliuskutka/Apps/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/pauliuskutka/Apps/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/pauliuskutka/Apps/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/pauliuskutka/Apps/google-cloud-sdk/completion.zsh.inc'; fi
