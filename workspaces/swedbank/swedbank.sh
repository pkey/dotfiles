printf "Setting up Swedbank workspace... \U1F3E6\n"

#Setup swedbank aliases
alias gcfeat='git commit -m "feat($(git_current_branch | cut -d / -f2)):'
alias gcfix='git commit -m "fix($(git_current_branch | cut -d / -f2)):'

#TODO: Check again if this one works properly
#git config --global includeIf.gitdir:**/swedbank/.path ~/.dotfiles/swedbank/.gitconfig