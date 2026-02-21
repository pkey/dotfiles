# Package Management

All packages are defined in `packages.yaml` — the single source of truth for both macOS and Linux. The `install-packages.sh` script reads it and calls `brew` on macOS or `apt` on Linux.

## Sections

| Section | Installed when | macOS | Linux |
|---|---|---|---|
| `common` | Always | `brew install` | `apt-get install` |
| `full` | `--full` flag or `DOTFILES_PROFILE=full` | `brew install` | `apt-get install` |
| `macos_only` | Always (macOS only) | `brew install` | skipped |
| `macos_casks` | `--full` (macOS only) | `brew install --cask` | skipped |

## Entry format

**Simple string** — same package name on both OS:

```yaml
- tmux
```

**Object with overrides** — when brew and apt names differ:

```yaml
- name: fd
  apt: fd-find
  post_apt: ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
```

**Not in apt** — install via script instead:

```yaml
- name: zoxide
  apt: false
  script: curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
```

**Different brew name:**

```yaml
- name: build-essential
  brew: gcc
```

**Needs a repo added first (Linux):**

```yaml
- name: gh
  apt_setup: |
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) ...] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
```

## Field reference

| Field | Description |
|---|---|
| (string) | Package name, used as-is for both `brew` and `apt` |
| `name` | Package identifier (used as default brew/apt name) |
| `brew` | Override brew formula name (macOS) |
| `apt` | Override apt package name(s), space-separated. Set to `false` if not in apt |
| `apt_setup` | Shell commands to run before `apt-get install` (e.g. add repo keys) |
| `post_apt` | Shell commands to run after `apt-get install` (e.g. create symlinks) |
| `script` | Shell commands to install when `apt: false` (fallback installer) |

## Machine-specific packages

Create `packages.local.yaml` (gitignored) with the same format for packages specific to one machine.
