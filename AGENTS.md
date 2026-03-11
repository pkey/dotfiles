# AGENTS.md

Personal dotfiles repo for macOS/Linux. Manages zsh, git, vim/neovim, tmux, and automated bootstrap.

## Structure

- **zsh/** - Shell config (.zshenv, .zshrc, .zprofile), antigen plugin manager, pure prompt
- **git/** - Git config with GPG signing, global gitignore, hooks
- **vim/** , **tmux/** - Editor and terminal multiplexer config
- **aliases.sh** - All aliases (one-liners with inline comments)
- **tools/*.sh** - Shell functions auto-sourced by .zshrc
- **bin/** - Scripts symlinked to `~/.local/bin`
- **packages.yaml** - Single source of truth for OS packages (brew/apt)
- **system/** - System-level config (crontab, sudoers)
- **steps/** - Setup scripts (e.g., macOS defaults)

## Commands

```bash
./bootstrap.sh           # Minimal install
./bootstrap.sh --full    # Full install
make pre-commit-run      # Run all pre-commit hooks
source ~/.zshrc          # Reload shell after changes
```

## Pre-commit

Hooks: trailing whitespace, end-of-file fixer, merge conflicts, YAML/JSON validation, shellcheck, gitleaks.

```bash
make pre-commit-install  # Install hooks
make pre-commit-run      # Run on all files
```
