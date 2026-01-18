# OGG
# Sources .zshrc and ensures symlinks are up to date
alias reload='$DOTFILES/setup_symlinks.sh && source ~/.zshrc'

# Cursor
alias cur='cursor .'

# Quick Edits
alias ealias='nvim $DOTFILES/aliases.sh'
alias edot='nvim $DOTFILES'

# Quick CDs
alias cdot='cd $DOTFILES'

#nvim
alias vim=nvim

#cd
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
alias gai='aicommit'
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
alias grfo='git fetch origin && git rebase origin/$(git symbolic-ref refs/remotes/origin/HEAD | sed "s@refs/remotes/origin/@@")'

# Git Worktrees
gwta() {
  local branch="$1"
  local base="${2:-HEAD}"
  local dir_name="${branch//\//-}"
  local worktree_path="../$(basename $(git rev-parse --show-toplevel))-$dir_name"
  git worktree add -b "$branch" "$worktree_path" "$base" && cd "$worktree_path"
}

gwtl() {
  local selected
  selected=$(git worktree list | fzf --header="Select worktree" | awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

gwtd() {
  local selected
  selected=$(git worktree list | fzf --header="Select worktree to remove" --multi | awk '{print $1}')
  [[ -n "$selected" ]] && echo "$selected" | xargs -I{} git worktree remove "{}" && cd ..
}

alias gwtls='git worktree list'

gwtla() {
  local search_dir="${1:-$HOME/repos}"
  local selected
  selected=$(fd -H -t d '^\.git$' "$search_dir" -x git -C {//} worktree list 2>/dev/null | \
    grep -v "^$" | \
    fzf --header="All worktrees in $search_dir" | \
    awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

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

### Find unpushed commits ###

alias lookIWorked='$(findUnpushedCommits)'
alias dateUpdate='GIT_COMMITTER_DATE="$(date)" git commit --amend --no-edit --date "$(date)"'

# Bazel
_bazel_fuzzy_run() {
  local target
  target=$(bazel query 'kind(".*_binary|.*_test", //...)' | fzf)
  [[ -n "$target" ]] && bazel run "$target"
}
alias bzlrun="_bazel_fuzzy_run"

_bazel_fuzzy_test() {
  local target
  target=$(bazel query 'kind(".*_test", //...)' | fzf)
  [[ -n "$target" ]] && bazel test "$target"
}
alias bzltest="_bazel_fuzzy_test"

# Vast.ai
alias vast="vastai"

# Focus workflow
alias focus='sudo $HOME/dotfiles/productivity/focus block'
alias unfocus='sudo $HOME/dotfiles/productivity/focus unblock'

# docker compose in many places is referred as docker-compose
alias docker-compose="docker compose"

# Claude
alias cc="claude"
alias eclaude='vim $DOTFILES/claude/CLAUDE.md'
