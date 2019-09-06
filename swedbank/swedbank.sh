echo "Setting up swedbank environment..."

#Setup swedbank aliases
alias gcfeat='git commit -m "feat($(git_current_branch | cut -d / -f2)):'
alias gcfix='git commit -m "fix($(git_current_branch | cut -d / -f2)):'

#Setup git config aliases
alias swed='~/.dotfiles/swedbank/swedconfig'
alias my='~/.dotfiles/swedbank/myconfig'
chmod +x ~/.dotfiles/swedbank/swedconfig
chmod +x ~/.dotfiles/swedbank/myconfig

#Set default git config
swed
