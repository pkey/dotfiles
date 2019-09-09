#!/usr/bin/env bash
# 
# Bootstrap script for setting up a new OSX machine
# 
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

printf "Bootstrap started... \U1F680\n"

#TODO: Setup relative paths..
#echo "Setting up bash scripts..."
#git clone git@github.com:pkey/scripts.git ~/.dotfiles

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    printf "Installing homebrew... \U1F37A\n"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

PACKAGES=(
    npm
    vim
    yarn
    node
    hub
    hyper
)

echo "Installing packages..."
brew install ${PACKAGES[@]}
echo "Cleaning up..."
brew cleanup

echo "Installing additional packages..."
echo "Installing nvm"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

echo "Done installing packages"

#Installing apps via cask
. ~/.dotfiles/steps/apps

MODULES=(
    typescript 
)

echo "Installing global npm modules..."
npm install -g ${MODULES[@]}

#Setting up code editor
. ~/.dotfiles/editor/editor.sh

echo "Creating an SSH key for you..."
ssh-keygen -t rsa

echo "Please add this public key to Github \n"
echo "https://github.com/account/ssh \n"
read -p "Press [Enter] key after this..."

echo "Creating folder structure..."
[[ ! -d Workspace ]] && mkdir ~/Workspace

#Terminal setup
. ~/.dotfiles/steps/terminal

#Vim setup
#Install vim plugin manager
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
#Copy vim rc
cp ~/.dotfiles/.vimrc ~/.vimrc

# Add global gitignore
cp ~/.dotfiles/.gitignore ~
git config --global core.excludesfile ~/.gitignore

#Macos setup
. ~/.dotfiles/steps/macos

#Final step
. ~/.zshrc

printf "Bootstrap completed \U1F389\n"
