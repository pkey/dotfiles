#!/usr/bin/env bash
# 
# Bootstrap script for setting up a new OSX machine
# 
# This should be idempotent so it can be run multiple times.
#
# Some apps don't have a cask and so still need to be installed by hand. These
# include:
#
# - Twitter (app store)
# - Postgres.app (http://postgresapp.com/)
#
# Notes:
#
# - If installing full Xcode, it's better to install that first from the app
#   store before running the bootstrap script. Otherwise, Homebrew can't access
#   the Xcode libraries as the agreement hasn't been accepted yet.
#
# Reading:
#
# - http://lapwinglabs.com/blog/hacker-guide-to-setting-up-your-mac
# - https://gist.github.com/MatthewMueller/e22d9840f9ea2fee4716
# - https://news.ycombinator.com/item?id=8402079
# - http://notes.jerzygangi.com/the-best-pgp-tutorial-for-mac-os-x-ever/

echo "Starting bootstrapping"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

PACKAGES=(
    npm
    vim
)

echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

CASKS=(
    firefox
    google-chrome
    hyper
    skype
    slack
    virtualbox
    visual-studio-code
    lastpass
)

echo "Installing cask apps..."
brew cask install ${CASKS[@]}

echo "Creating an SSH key for you..."
ssh-keygen -t rsa

echo "Please add this public key to Github \n"
echo "https://github.com/account/ssh \n"
read -p "Press [Enter] key after this..."

echo "Setting up bash scripts..."
git clone git@github.com:pkey/scripts.git ~/.scripts

echo "Creating folder structure..."
[[ ! -d Workspace ]] && mkdir ~/Workspace

echo "Setting up zsh..."
path_zshrc = "~/.zshrc"
npm install --global pure-prompt
echo "#Pure prompt config \n" >> "${path_zshrc}"
echo "autoload -U promptinit; promptinit \n" >> "${path_zshrc}"
echo "prompt pure \n" >> "${path_zshrc}"
chsh -s /bin/zsh

echo "Bootstrapping complete"
