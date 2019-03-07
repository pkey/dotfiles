echo "Setting up swedbank environment..."

#Setup swedbank aliases
alias gcfeat='git commit -m "feat($(git_current_branch | cut -d / -f2)):'
alias gcfix='git commit -m "fix($(git_current_branch | cut -d / -f2)):'

#Setup git config aliases
alias swed='~/.scripts/swedbank/swedconfig'
alias my='~/.scripts/swedbank/myconfig'
chmod +x ~/.scripts/swedbank/swedconfig
chmod +x ~/.scripts/swedbank/myconfig

#Set default git config
swed
