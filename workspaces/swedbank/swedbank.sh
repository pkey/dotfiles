echo "Setting up swedbank environment..."

currentDir=$(dirname $0)

#Setup swedbank aliases
alias gcfeat='git commit -m "feat($(git_current_branch | cut -d / -f2)):'
alias gcfix='git commit -m "fix($(git_current_branch | cut -d / -f2)):'

#Setup git config aliases
alias swed="${currentDir}/swedconfig"
alias my="${currentDir}/myconfig"
chmod +x ${currentDir}/swedconfig
chmod +x ${currentDir}/myconfig

#Set default git config
swed
