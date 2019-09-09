# Paulius' .dotfiles :wrench:

## Getting started :rocket:

1. `git clone git@github.com:pkey/.dotfiles.git` to your home folder. Everything should end up in `~/.dotfiles`.
2. `sh ~/.dotfiles/bootstrap.sh`
3. Let it fly

## Environment

`.env` file might be used to define the environment variables:

- `DEFAULT_WORKSPACE`: defines default workspace to launch session with if no `WORKSPACE` env is present.
- `GIT_USER_NAME`: your git user name
- `GIT_USER_EMAIL`: your git user email

**Each workspace can have its own `.env`. Environment variables defined there will override the ones in root directory**

## Testing :fire:

Testing of `.dotfiles` (especially `bootstrap.sh`) can be done on a fresh virtual machine. How to set up virtual machine:

- For MacOS: https://github.com/myspaghetti/macos-guest-virtualbox

## Inspirations

:star: https://github.com/mathiasbynens/dotfiles  
:star: https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789
