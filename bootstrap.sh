#!/usr/bin/env bash
# 
# Bootstrap script for setting up a new OSX machine
# 
#
# - If installing full Xcode, it's better to install that first from the app
#   store before running the bootstrap script. Otherwise, Homebrew can't acces
#   the Xcode libraries as the agreement hasn't been accepted yet.
#
# Reading:
#
# - http://lapwinglabs.com/blog/hacker-guide-to-setting-up-your-mac
# - https://gist.github.com/MatthewMueller/e22d9840f9ea2fee4716
# - https://news.ycombinator.com/item?id=8402079
# - http://notes.jerzygangi.com/the-best-pgp-tutorial-for-mac-os-x-ever/

printf "Bootstrap started... \U1F680\n"

export DOTFILES="$HOME/.dotfiles"

# Setup submodules
git -C "$DOTFILES" submodule update --init --recursive

#TODO: Setup relative paths..

# Check for Homebrew, install if we don't have it
if ! command -v brew >/dev/null 2>&1; then
  printf "Installing Homebrew... 🍺\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# Install brews
brew bundle

# Update homebrew recipes
brew update

#TODO: move to brewfile
#PACKAGES=()

#echo "Installing packages..."
#brew install ${PACKAGES[@]}
#echo "Cleaning up..."
#brew cleanup

echo "Installing additional packages..."

if ! command -v fnm &>/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash
else
  echo "fnm already installed ✅"
fi

echo "Done installing packages"

# Sync Config
ln -sf ~/.dotfiles/vim/.vimrc ~/.vimrc
ln -sf ~/.dotfiles/.zshenv ~/.zshenv

### REVISIT ###
#Installing apps via cask
#TODO: figure this out later 
#. ~/.dotfiles/steps/apps
#
#
#
#MODULES=(
#    typescript 
#)
#
#echo "Installing global npm modules..."
#npm install -g ${MODULES[@]}
#
#Setting up code editor
#. ~/.dotfiles/editor/editor.sh
#
#
#echo "Creating an SSH key for you..."
#if [ ! -f ~/.ssh/id_rsa ]; then
#    ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
#    pbcopy < ~/.ssh/id_rsa.pub 
#    echo "Public key copied to your clipboard. Please add it to Github... \n"
#    echo "https://github.com/account/ssh \n"
#    #If CI, wait for only one second
#        if [ ! -z $CI ] ; then
#        read -p "Press [Enter] key after this..." -t 1
#        else 
#        read -p "Press [Enter] key after this..."
#        fi
#    else
#    echo "Key already exists!"
#fi
#
#echo "Creating folder structure..."
#[[ ! -d Workspace ]] && mkdir ~/Workspace
#
##Terminal setup
#. ~/.dotfiles/steps/terminal
#
#Vim setup
#Install vim plugin manager
#curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
#    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
#Copy vim rc
#cp ~/.dotfiles/.vimrc ~/.vimrc

# Add global gitignore
#cp ~/.dotfiles/.gitignore ~
#git config --global core.excludesfile ~/.gitignore

#Macos setup
#. ~/.dotfiles/steps/macos

# Source ZSH config
#. ~/.zshrc

printf "Bootstrap completed \U1F389\n"
printf "Reload terminal!"
