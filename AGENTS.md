# AGENTS.md

This file provides guidance to agents on how to work with this repository.

## Repository Overview

This is a personal dotfiles repository for macOS/Linux system configuration and development environment setup. It manages shell configuration (zsh), git, vim/neovim, tmux, and includes automated bootstrap scripts for new machine setup.

## Common Commands

### Bootstrap and Installation

```bash
# Minimal installation (essential packages only)
./bootstrap.sh

# Full installation (includes all development tools)
./bootstrap.sh --full

# Remote installation
bash <(curl -fsSL https://raw.githubusercontent.com/pkey/dotfiles/main/bootstrap.sh)
```

The bootstrap script:
- Installs Homebrew and packages from `Brewfile` or `Brewfile.minimal`
- Sets up git configuration with GPG signing (key: EAB2D9EB6CD93324)
- Creates symlinks for shell configs (.zshenv, .zshrc, .zprofile)
- Installs pipx package (uv)
- Configures zsh as default shell
- Full install also sets up Cursor, AWS CLI, and additional tools

### Pre-commit Hooks

```bash
make pre-commit-install    # Install pre-commit hooks
make pre-commit-run        # Run hooks on all files
make pre-commit-update     # Update hook versions
make help                  # Show available make commands
```

Pre-commit checks include: trailing whitespace, end-of-file fixer, merge conflicts, YAML/JSON validation, shellcheck, and gitleaks (secret detection).

### Git Submodules

The repository uses git submodules for:
- `zsh/antigen` - Zsh plugin manager
- `zsh/plugins/pure` - Pure prompt theme

Update submodules with:
```bash
git submodule update --init --recursive
```

## Architecture and Structure

### Configuration Organization

- **zsh/** - Shell configuration with antigen plugin manager and pure prompt
- **~/.localrc** - Local/private overrides (machine-specific settings, secrets via `secret` command)
- **git/** - Git configuration with GPG signing enabled and global gitignore
  - `hooks/post-merge-bootstrap` - Auto-runs bootstrap on git pull/merge
- **vim/** - Minimal vim configuration
- **tmux/** - Tmux configuration with TPM plugin manager and resurrect plugin
- **productivity/** - Utility scripts (e.g., `toggle-fb` for blocking distracting websites)
- **steps/** - Setup scripts (e.g., `steps/macos` for macOS system defaults)

### Key Configuration Files

- `aliases.sh` (159 lines) - Extensive git, tmux, kubectl, navigation, and development aliases
- `functions.sh` (38 lines) - Custom shell functions:
  - `byebranch()` - Delete local and remote branch
  - `merge()` - Merge GitHub PR via API (requires GITHUB_TOKEN)
  - `findUnpushedCommits()` - Find unpushed commits in subdirectories

### Multi-OS Support

The bootstrap script detects OS and uses appropriate Homebrew paths:
- macOS: `/opt/homebrew/bin/brew`
- Linux: `/home/linuxbrew/.linuxbrew/bin/brew`

Two Brewfile variants:
- `Brewfile.minimal` - Essential packages (zsh, python, pipx, fd, fzf, zoxide, ripgrep, bat, tmux)
- `Brewfile` - Extended packages (adds fnm, gcc, gh, pre-commit, gnupg, cursor, 1password-cli, etc.)

### Development Tools Setup

- **Python**: Managed via pipx for CLI tools; pyenv for version management
- **Node**: fnm (Fast Node Manager) configured in .zshrc
- **Shell**: Zsh with antigen plugin manager and pure prompt
- **Directory Navigation**: zoxide integration (use `z` command)

### Notable Workflows

**Git Workflow Aliases** (GPG-signed commits enabled by default):
- `grw` - Stage all, amend commit, force-push (rewrite workflow)
- `gro` - Reset hard to origin branch
- `glr` - Pull with rebase
- `grfo` - Fetch and rebase from origin

**Tmux Session Management**:
- `muxa` - Attach to tmux session
- `muxsw` - Switch tmux session
- `muxd` - Split pane vertically
- `muxh` - Split pane horizontally
- Auto-restore sessions via tmux-resurrect plugin

## Known Issues

From TODO.md:
- Full install can take >10 minutes and may get stuck during package upgrades
- Python installed via brew may not be immediately available in PATH
- `fnm` not picked up on Linux machines
- VSCode history issues
- Plans to create "minidot" for quick setups

## Testing Changes

After modifying shell configuration:
```bash
# Reload zsh configuration
source ~/.zshrc

# Re-run bootstrap to test changes
./bootstrap.sh
```

After modifying git hooks or pre-commit config:
```bash
make pre-commit-install
make pre-commit-run
```
