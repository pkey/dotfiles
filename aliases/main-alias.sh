alias -- -='cd -'
alias ..='cd ../'
alias ...=../..
alias ....=../../..
alias .....=../../../..
alias ......=../../../../..
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias _=sudo
alias g=git
alias ga='git add'
alias gaa='git add --all'
alias gap='git apply'
alias gb='git branch'
alias 'gc!'='git commit -v --amend'
alias gc='git commit'
alias gc-='git checkout -'
alias 'gca!'='git commit -v -a --amend'
alias grw='gaa && gc! --no-edit && gp!'
alias gcb='git checkout -b'
alias gci='git checkout project/integration'
alias gco='git checkout'
alias ggpush='git push origin $(git_current_branch)'
alias 'gp!'='ggpush --force'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gl='git pull'
alias gp='git push'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbs='git rebase --skip'
alias gst='git status'
alias glr='git pull --rebase'
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias ls='ls -G'
alias lsa='ls -lah'
alias md='mkdir -p'
alias run-help=man
alias which-command=whence

#Yarn
alias ybw='yarn build --watch'
alias yl='yarn lint --fix'
alias yt='yarn test'

#Kubectl
alias k='kubectl'

#Productivity
alias toggle-fb='sudo ~/.scripts/productivity/toggle-fb'

### Work/Personal ###
alias myconfig='sh ~/.scripts/swedbank/myconfig'
alias swedconfig='sh ~/.scripts/swedbank/swedconfig'

### Java ###
#alias j12="export JAVA_HOME=`/usr/libexec/java_home -v 12`; java -version"
alias j11="export JAVA_HOME=`/usr/libexec/java_home -v 11`; java -version"
#alias j10="export JAVA_HOME=`/usr/libexec/java_home -v 10`; java -version"
#alias j9="export JAVA_HOME=`/usr/libexec/java_home -v 9`; java -version"
alias j8="export JAVA_HOME=`/usr/libexec/java_home -v 1.8`; java -version"
#alias j7="export JAVA_HOME=`/usr/libexec/java_home -v 1.7`; java -version"
