# Set up env variables

### From: https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
nvm() {
  echo ":rotating_light: NVM not loaded! Loading now..."
  export NVM_DIR=~/.nvm
  unset -f nvm
  source $(brew --prefix nvm)/nvm.sh
  nvm "$@"
}

export PATH=$PATH:/usr/local/bin
export PATH="~/miniconda3/bin:$PATH"
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

# Set up GCloud
#TODO: Review this

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/pauliuskutka/Apps/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/pauliuskutka/Apps/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/pauliuskutka/Apps/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/pauliuskutka/Apps/google-cloud-sdk/completion.zsh.inc'; fi

#Ban facebook by default
#TODO: Ban facebook, but only on home pc

#------------Set Workspace––––––––––––
if [ ! -f ~/.dotfiles/.env ]
  then
    #TODO: Add this step to bootstrap build
    echo "No default environment file. Please create one in .dotfiles/.env"
    return
  else
    source ~/.dotfiles/.env
fi

if [[ -z "${WORKSPACE}" ]];
  then
    if [[ -z "${DEFAULT_WORKSPACE}" ]] 
    then
      export WORKSPACE="default"
    else 
      export WORKSPACE=${DEFAULT_WORKSPACE}
    fi
fi

workspaceDir=~/.dotfiles/workspaces/${WORKSPACE}

source $workspaceDir/${WORKSPACE}.sh
#These environments variables overwrite the default ones
source $workspaceDir/.env

for d in $workspaceDir/.* ; do
  cp $d ~
done

echo "${WORKSPACE} workspace is ready!"

# Set Aliases for workspace switching

for d in $(dirname $0)/workspaces/* ; do
    workspace=$(basename $d)
    #TODO: This could be a function which would also have onDestroy function (to remove added configs)
    alias $workspace-workspace="export WORKSPACE=${workspace}; source ~/.zshrc"
done

# --------These depend on Environment Variables--------------
# Set up GIT
git config --global user.name $GIT_USER_NAME >> /dev/null 
git config --global user.email $GIT_USER_EMAIL >> /dev/null


# Android studio
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

#kubetcl
source <(kubectl completion zsh)
complete -F __start_kubectl k
