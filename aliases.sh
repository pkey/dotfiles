# Sources .zshrc
alias reload='source ~/.zshrc'

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
alias checkout='git checkout $(git branch | fzf)'
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias ls='ls -G'
alias lsa='ls -lah'
alias md='mkdir -p'
alias run-help=man
alias which-command=whence

# Git

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
alias 'gp!'='ggpush --force-with-lease'
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
alias glrm='git pull --rebase origin master'
alias grs='git reset --staged'
alias gro='git reset --hard origin/$(git_current_branch)'

#Vim
alias v='vim'

#Yarn
alias ybw='yarn build --watch'
alias yl='yarn lint --fix'
alias yt='yarn test'


#Kubectl
alias k='kubectl'


new_tmux_and_switch() {
  local name="$1"
  tmux switch-client -t "$(tmux new-session -d -P -s "$name")"
}

#Tmux
alias mux='tmux'
alias muxa='tmux attach'
alias muxad='tmux attach -d'
alias muxnew='new_tmux_and_switch'
alias muxkillall='tmux kill-server'
alias muxkillo='tmux kill-session -a'

muxsw() {
    if [ -z "$1" ]; then
        # Use tmux's built-in last session switching
        tmux switch-client -l
    else
        tmux switch-client -t "$1"
    fi
}

# Renames current session
alias muxrn='tmux rename-session '
alias muxls='tmux list-sessions'
alias muxns='tmux new-session'
alias muxks='tmux kill-session'

# Window management
alias muxd='tmux split-window -h'  # Split vertically (left/right)
alias muxh='tmux split-window -v'  # Split horizontally (top/bottom)
alias muxw='tmux kill-pane'        # Close current pane
alias muxn='tmux new-window'       # New window
alias muxlw='tmux list-windows'     # List windows

## Window switching
alias muxwn='tmux next-window'     # Next window
alias muxwp='tmux previous-window' # Previous window
alias muxw1='tmux select-window -t :1'  # Switch to window 1
alias muxw2='tmux select-window -t :2'  # Switch to window 2
alias muxw3='tmux select-window -t :3'  # Switch to window 3
alias muxw4='tmux select-window -t :4'  # Switch to window 4
alias muxw5='tmux select-window -t :5'  # Switch to window 5

#Workflow
alias test-update='jest --only-changed -u'
alias trypush='(! git diff HEAD develop --exit-code --quiet) && (! git diff HEAD master --exit-code --quiet) && git status && (jest --changedSince develop || true) && (npm run format || true) && git commit --amend -a --no-edit && git push -u --force-with-lease'
alias jest='npx jest'

### Workflows ###

alias morning="sh ~/.dotfiles/bear/daily-note.sh"
alias toggle-fb="sudo ~/.dotfiles/productivity/toggle-fb"

### Find unpushed commits ###

alias lookIWorked='$(findUnpushedCommits)'
alias dateUpdate='GIT_COMMITTER_DATE="$(date)" git commit --amend --no-edit --date "$(date)"'
