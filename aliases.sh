# Shell
alias reload='$DOTFILES/setup_symlinks.sh && source ~/.zshrc'                # Reload shell config

# Editor
alias cur='cursor .'                                                         # Open current dir in Cursor
alias ca='cursor agent'						   	     # Opens cursor agent
alias ealias='nvim $DOTFILES/aliases.sh'                                     # Edit aliases file
alias edot='nvim $DOTFILES'                                                  # Edit dotfiles dir
alias vim=nvim                                                               # Use neovim as vim

viz() {                                                                      # Fuzzy find file and edit
  local file
  local search_path="${1:-.}"
  file=$(fd --type f --hidden --exclude .git --max-depth 5 . "$search_path" | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
  [[ -n "$file" ]] && vim "$file"
}

# Navigation
alias -- -='cd -'                                                            # Go to previous dir
alias ..='cd ../'                                                            # Up one level
alias ...=../..                                                              # Up two levels
alias ....=../../..                                                          # Up three levels
alias .....=../../../..                                                      # Up four levels
alias ......=../../../../..                                                  # Up five levels
alias 1='cd -'                                                               # Go to previous dir
alias 2='cd -2'                                                              # Go back 2 dirs
alias 3='cd -3'                                                              # Go back 3 dirs
alias 4='cd -4'                                                              # Go back 4 dirs
alias 5='cd -5'                                                              # Go back 5 dirs
alias 6='cd -6'                                                              # Go back 6 dirs
alias 7='cd -7'                                                              # Go back 7 dirs
alias 8='cd -8'                                                              # Go back 8 dirs
alias 9='cd -9'                                                              # Go back 9 dirs
alias _=sudo                                                                 # Shortcut for sudo
alias checkout='git checkout $(git branch | fzf)'                            # Fuzzy checkout branch
alias l='ls -lah'                                                            # List all with details
alias la='ls -lAh'                                                           # List almost all with details
alias ll='ls -lh'                                                            # List with details
alias ls='ls -G'                                                             # List with colors
alias lsa='ls -lah'                                                          # List all with details
alias md='mkdir -p'                                                          # Make dir with parents
alias run-help=man                                                           # Show manual page
alias which-command=whence                                                   # Show command location
alias cdot='cd $DOTFILES'                                                    # Go to dotfiles dir

# Git
alias g=git                                                                  # Git shortcut
alias ga='git add'                                                           # Stage files
alias gaa='git add --all'                                                    # Stage all changes
alias gap='git apply'                                                        # Apply patch
alias gb='git branch'                                                        # List branches
alias 'gc!'='git commit -v --amend'                                          # Amend last commit
alias gc='git commit'                                                        # Commit staged changes
alias gai='aicommit'                                                         # AI-generated commit msg
alias gc-='git checkout -'                                                   # Checkout previous branch
alias 'gca!'='git commit -v -a --amend'                                      # Amend with all changes
alias grw='gaa && gc! --no-edit && gp!'                                      # Rewrite: stage, amend, push
alias gcb='git checkout -b'                                                  # Create and checkout branch
alias gci='git checkout project/integration'                                 # Checkout integration
alias gco='git checkout'                                                     # Checkout branch/file
alias ggpush='git push origin $(git_current_branch)'                         # Push to origin
alias 'gp!'='ggpush --force-with-lease'                                      # Force push safely
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'      # Set upstream
alias gl='git pull'                                                          # Pull from remote
alias gp='git push'                                                          # Push to remote
alias gpsup='git push --set-upstream origin $(git_current_branch)'           # Push and set upstream
alias grb='git rebase'                                                       # Rebase branch
alias grba='git rebase --abort'                                              # Abort rebase
alias grbc='git rebase --continue'                                           # Continue rebase
alias grbs='git rebase --skip'                                               # Skip rebase commit
alias grbi='git rebase -i'                                                   # Interactive rebase
alias gst='git status'                                                       # Show working tree status
alias glr='git pull --rebase'                                                # Pull with rebase
alias glrm='git pull --rebase origin master'                                 # Pull rebase from master
alias grs='git reset --staged'                                               # Unstage files
alias gro='git reset --hard origin/$(git_current_branch)'                    # Reset to origin
alias gf='git fetch origin'                                                  # Fetch from origin
alias grfo='gf && grb origin/$(git symbolic-ref refs/remotes/origin/HEAD | sed "s@refs/remotes/origin/@@")'  # Fetch and rebase default

# Git Worktree
gwta() {                                                                     # Create worktree with new branch
  local branch="$1"
  local base="${2:-HEAD}"
  local dir_name="${branch//\//-}"
  local worktree_path="/tmp/$(basename $(git rev-parse --show-toplevel))-$dir_name"
  git worktree add -b "$branch" "$worktree_path" "$base" && cd "$worktree_path"
}

gwtc() {                                                                     # Checkout branch in worktree
  local branch="$1"
  local dir_name="${branch//\//-}"
  local worktree_path="/tmp/$(basename $(git rev-parse --show-toplevel))-$dir_name"
  git worktree add "$worktree_path" "$branch" && cd "$worktree_path"
}

gwtl() {                                                                     # Fuzzy select worktree
  local selected
  selected=$(git worktree list | fzf --header="Select worktree" | awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

gwtd() {                                                                     # Fuzzy remove worktree + branch
  local selected
  selected=$(git worktree list | fzf --header="Select worktree to remove" --multi)
  [[ -z "$selected" ]] && return
  echo "$selected" | while read -r line; do
    local path=$(echo "$line" | awk '{print $1}')
    local branch=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')
    git worktree remove "$path" && [[ -n "$branch" ]] && git branch -D "$branch" 2>/dev/null
  done
  cd ..
}

alias gwtls='git worktree list'                                              # List all worktrees

gwtla() {                                                                    # Fuzzy worktree all repos
  local search_dir="${1:-$HOME/repos}"
  local selected
  selected=$(fd -H -t d '^\.git$' "$search_dir" -x git -C {//} worktree list 2>/dev/null | \
    grep -v "^$" | \
    fzf --header="All worktrees in $search_dir" | \
    awk '{print $1}')
  [[ -n "$selected" ]] && cd "$selected"
}

# Yarn
alias ybw='yarn build --watch'                                               # Build with watch mode
alias yl='yarn lint --fix'                                                   # Lint and fix
alias yt='yarn test'                                                         # Run tests

# Kubectl
alias k='kubectl'                                                            # Kubectl shortcut

# Tmux
alias mux='tmux'                                                             # Tmux shortcut
alias muxa='tmux attach'                                                     # Attach to session
alias muxad='tmux attach -d'                                                 # Attach detach others

muxnew() {                                                                   # New session and switch
  local name="$1"
  tmux switch-client -t "$(tmux new-session -d -P -s "$name")"
}
alias muxkillall='tmux kill-server'                                          # Kill tmux server
alias muxkillo='tmux kill-session -a'                                        # Kill other sessions

muxsw() {                                                                    # Switch session
    if [ -z "$1" ]; then
        tmux switch-client -l
    else
        tmux switch-client -t "$1"
    fi
}

alias muxrn='tmux rename-session '                                           # Rename current session
alias muxls='tmux list-sessions'                                             # List sessions
alias muxns='tmux new-session'                                               # New session
alias muxks='tmux kill-session'                                              # Kill session
alias muxd='tmux split-window -h'                                            # Split pane vertical
alias muxh='tmux split-window -v'                                            # Split pane horizontal
alias muxw='tmux kill-pane'                                                  # Close current pane
alias muxn='tmux new-window'                                                 # New window
alias muxlw='tmux list-windows'                                              # List windows
alias muxwn='tmux next-window'                                               # Next window
alias muxwp='tmux previous-window'                                           # Previous window
alias muxw1='tmux select-window -t :1'                                       # Go to window 1
alias muxw2='tmux select-window -t :2'                                       # Go to window 2
alias muxw3='tmux select-window -t :3'                                       # Go to window 3
alias muxw4='tmux select-window -t :4'                                       # Go to window 4
alias muxw5='tmux select-window -t :5'                                       # Go to window 5

# Workflow
alias test-update='jest --only-changed -u'                                   # Update test snapshots
alias jest='npx jest'                                                        # Run jest via npx
alias lookIWorked='$(findUnpushedCommits)'                                   # Find unpushed commits
alias dateUpdate='GIT_COMMITTER_DATE="$(date)" git commit --amend --no-edit --date "$(date)"'  # Update commit date

trypush() {                                                                  # Test format amend push
  (! git diff HEAD develop --exit-code --quiet) && \
  (! git diff HEAD master --exit-code --quiet) && \
  git status && \
  (jest --changedSince develop || true) && \
  (npm run format || true) && \
  git commit --amend -a --no-edit && \
  git push -u --force-with-lease
}

# Bazel
bzlrun() {                                                                   # Fuzzy run bazel target
  local target
  target=$(bazel query 'kind(".*_binary|.*_test", //...)' | fzf)
  [[ -n "$target" ]] && bazel run "$target"
}

bzltest() {                                                                  # Fuzzy test bazel target
  local target
  target=$(bazel query 'kind(".*_test", //...)' | fzf)
  [[ -n "$target" ]] && bazel test "$target"
}

# Focus
alias focus='sudo $HOME/dotfiles/productivity/focus block'                   # Block distracting sites
alias unfocus='sudo $HOME/dotfiles/productivity/focus unblock'               # Unblock distracting sites

# Docker
alias docker-compose="docker compose"                                        # Use new docker compose

# Claude
alias cc="claude"                                                            # Claude CLI shortcut
alias eclaude='vim $DOTFILES/claude/CLAUDE.md'                               # Edit Claude config

# Help
alias-help() {                                                               # Show aliases with desc
  local filter="${1:-}"
  local max_name=0
  local max_desc=0
  local -a entries=()

  while IFS= read -r line; do
    if [[ "$line" == \#* ]] && [[ "$line" != \#\!* ]]; then
      local section="${line#\#}"
      section="${section# }"
      entries+=("section:$section")
    elif [[ "$line" == alias\ * ]]; then
      local rest="${line#alias }"
      local name="${rest%%=*}"
      local cmd_and_comment="${rest#*=}"
      local cmd="${cmd_and_comment%%  #*}"
      local comment=""
      [[ "$cmd_and_comment" == *"  #"* ]] && comment="${cmd_and_comment##*  # }"
      name="${name//\'/}"
      name="${name//\"/}"
      cmd="${cmd#\'}"
      cmd="${cmd#\"}"
      cmd="${cmd%\'}"
      cmd="${cmd%\"}"
      entries+=("alias:$name:$comment:$cmd")
      (( ${#name} > max_name )) && max_name=${#name}
      (( ${#comment} > max_desc )) && max_desc=${#comment}
    elif [[ "$line" != " "* ]] && [[ "$line" == *"() {"* ]] && [[ "$line" == *"  # "* ]]; then
      local name="${line%%\(\)*}"
      local comment="${line##*  # }"
      entries+=("func:$name:$comment:(function)")
      (( ${#name} > max_name )) && max_name=${#name}
      (( ${#comment} > max_desc )) && max_desc=${#comment}
    fi
  done < "$DOTFILES/aliases.sh"

  local current_section=""
  local printed_section=""
  for entry in "${entries[@]}"; do
    local type="${entry%%:*}"
    local rest="${entry#*:}"

    if [[ "$type" == "section" ]]; then
      current_section="$rest"
    else
      local name="${rest%%:*}"
      rest="${rest#*:}"
      local comment="${rest%%:*}"
      local cmd="${rest#*:}"

      if [[ -z "$filter" ]] || [[ "$name" == *"$filter"* ]] || [[ "${current_section:l}" == *"${filter:l}"* ]]; then
        if [[ "$current_section" != "$printed_section" ]]; then
          printf "\n\033[1;34m── %s ──\033[0m\n" "$current_section"
          printed_section="$current_section"
        fi
        if [[ -n "$comment" ]]; then
          printf "  \033[1;32m%-${max_name}s\033[0m  \033[0;33m%-${max_desc}s\033[0m  %s\n" "$name" "$comment" "$cmd"
        else
          printf "  \033[1;32m%-${max_name}s\033[0m  %s\n" "$name" "$cmd"
        fi
      fi
    fi
  done
}

alias halias='alias-help'                                                    # Alias help shortcut
