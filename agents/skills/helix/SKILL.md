---
name: helix
description: Reference for Helix editor keybindings, commands, and configuration. Use when the user asks about Helix shortcuts, how to do X in Helix, Helix config options, or how to set up language servers/themes in Helix.
disable-model-invocation: false
---

# Helix Editor Reference

Helix is a modal editor with a **selection-first** paradigm (inspired by Kakoune): you make a selection, then act on it. The cursor is always part of a selection (at minimum, a 1-char selection).

User's config lives in `~/.config/helix/` → symlinked from `~/dotfiles/helix/`.

## Modes

| Mode | Enter | Purpose |
|---|---|---|
| Normal | `Esc` | Default; movement and commands |
| Insert | `i` / `a` / `o` | Text insertion |
| Select (extend) | `v` | Extend selections with movement |
| View | `Ctrl-w` or `z` | Scroll/center view |
| Goto | `g` | Jump commands |
| Match | `m` | Brackets, surrounds |
| Window | `Ctrl-w` | Split/window management |
| Space | `Space` | Leader menu (pickers, LSP, etc.) |

## Movement (Normal mode)

| Key | Action |
|---|---|
| `h j k l` | Left / Down / Up / Right |
| `w` / `b` / `e` | Next word start / prev word start / next word end |
| `W` / `B` / `E` | Same, but WORD (whitespace-delimited) |
| `f<char>` / `F<char>` | Find next/prev char on line |
| `t<char>` / `T<char>` | Till next/prev char on line |
| `Home` / `gh` | Line start |
| `End` / `gl` | Line end |
| `gs` | First non-whitespace on line |
| `gg` / `ge` | File start / file end |
| `Ctrl-u` / `Ctrl-d` | Half-page up / down |
| `Ctrl-b` / `Ctrl-f` | Full page up / down |
| `Ctrl-i` / `Ctrl-o` | Jumplist forward / back |
| `%` | Select whole file |

## Changes (Normal mode)

| Key | Action |
|---|---|
| `i` / `a` | Insert before / after selection |
| `I` / `A` | Insert at line start / end |
| `o` / `O` | Open line below / above |
| `d` | Delete selection (also yanks) |
| `c` | Change (delete + enter insert) |
| `r<char>` | Replace each selected char |
| `R` | Replace with yanked text |
| `u` / `U` | Undo / redo |
| `.` | Repeat last insert |
| `~` | Switch case |
| `` ` `` / `Alt-\`` | To lowercase / uppercase |
| `>` / `<` | Indent / unindent |
| `=` | Format selection |
| `J` | Join lines |
| `Alt-j` / `Alt-k` | Join below / up (without space) |

## Selection manipulation

| Key | Action |
|---|---|
| `v` | Toggle select (extend) mode |
| `x` | Extend to line (repeat: extend further) |
| `X` | Extend to line bounds |
| `;` | Collapse selection to cursor |
| `Alt-;` | Flip selection anchor/cursor |
| `,` | Keep only primary selection |
| `Alt-,` | Remove primary selection |
| `(` / `)` | Rotate primary selection backward / forward |
| `s` | Select all regex matches within selection |
| `S` | Split selection on regex |
| `Alt-s` | Split selection on newlines |
| `K` | Keep selections matching regex |
| `Alt-K` | Remove selections matching regex |
| `&` | Align selections |
| `_` | Trim whitespace from selections |
| `C` | Copy selection to next line |
| `Alt-C` | Copy selection to previous line |

## Search

| Key | Action |
|---|---|
| `/` / `?` | Search forward / backward |
| `n` / `N` | Next / previous match |
| `*` | Use selection as search pattern |
| `Alt-*` | Same, but no word boundary |

## Yank / paste / registers

| Key | Action |
|---|---|
| `y` | Yank selection |
| `p` / `P` | Paste after / before |
| `"<reg>` | Select register (e.g. `"ay` yanks to `a`) |
| `"_d` | Delete without yanking (blackhole register) |
| `"+y` / `"+p` | Yank to / paste from system clipboard |
| `"*y` / `"*p` | Yank to / paste from primary selection |
| `Q` / `q<reg>` | Play / record macro |

## Goto (`g` prefix)

| Key | Action |
|---|---|
| `gg` | File start |
| `ge` | File end |
| `gl` | Line end |
| `gh` | Line start |
| `gs` | First non-blank on line |
| `gd` | Goto definition |
| `gy` | Goto type definition |
| `gr` | Goto references |
| `gi` | Goto implementation |
| `gt` / `gc` / `gb` | Top / center / bottom of view |
| `ga` | Last accessed file |
| `gm` | Last modified file |
| `gn` / `gp` | Next / previous buffer |
| `g.` | Last modification in file |
| `gw` | Open link at cursor |

## Match (`m` prefix)

| Key | Action |
|---|---|
| `mm` | Jump to matching bracket |
| `ms<char>` | Surround selection with `<char>` |
| `mr<old><new>` | Replace surround char |
| `md<char>` | Delete surrounding char |
| `mi<char>` | Select **inside** (e.g. `mi(`, `mi"`, `miw`) |
| `ma<char>` | Select **around** (includes delimiters) |

Textobjects after `mi`/`ma`: `w` word, `W` WORD, `p` paragraph, `(`/`[`/`{`/`<`/`"`/`'` pairs, `t` tag, `g` change, `f` function, `c` class, `a` argument, `T` test, `m` comment.

## Space menu (leader)

| Key | Action |
|---|---|
| `Space f` | File picker |
| `Space F` | File picker (relative to current) |
| `Space b` | Buffer picker |
| `Space j` | Jumplist picker |
| `Space s` | Symbol picker (current file) |
| `Space S` | Workspace symbol picker |
| `Space d` / `Space D` | Diagnostics (file / workspace) |
| `Space /` | Global search |
| `Space k` | Show hover docs |
| `Space r` | Rename symbol |
| `Space a` | Code actions |
| `Space h` | Select references to symbol |
| `Space '` | Last picker |
| `Space c` | Toggle comments |
| `Space C` | Block comments |
| `Space w` | Window menu (same as `Ctrl-w`) |
| `Space y` / `Space Y` | Yank joined / to clipboard |
| `Space p` / `Space P` | Paste from clipboard |
| `Space R` | Replace with clipboard |
| `Space g` | Open changelog / debug / etc. submenu |

## Window management (`Ctrl-w` / `Space w`)

| Key | Action |
|---|---|
| `s` / `Ctrl-s` | Horizontal split |
| `v` / `Ctrl-v` | Vertical split |
| `h j k l` | Move to split left/down/up/right |
| `q` / `Ctrl-q` | Close window |
| `o` / `Ctrl-o` | Close all but current |
| `n` / `Ctrl-n` | New file in split |
| `H J K L` | Swap window left/down/up/right |

## View mode (`z` / `Z` sticky)

| Key | Action |
|---|---|
| `zz` / `zc` | Center view on cursor |
| `zt` | Cursor to top |
| `zb` | Cursor to bottom |
| `zj` / `zk` | Scroll down / up line |
| `zJ` / `zK` | Half-page down / up |

## Multi-cursor essentials

| Key | Action |
|---|---|
| `C` | Add cursor on next line (same column) |
| `Alt-C` | Add cursor on previous line |
| `s` | Multi-cursor on regex matches within selection |
| `,` | Remove all but primary |
| `Alt-,` | Remove primary only |
| `(` / `)` | Rotate primary |

## Commands (typed after `:`)

Common ones:

| Command | Purpose |
|---|---|
| `:w` / `:w!` | Write / force write |
| `:q` / `:q!` / `:wq` | Quit variants |
| `:x` | Write and quit |
| `:bc` / `:bco` | Buffer close / close others |
| `:o <path>` / `:e <path>` | Open file |
| `:reload` | Reload file |
| `:set <key> <val>` | Runtime config (e.g. `:set line-number relative`) |
| `:toggle <key>` | Toggle boolean option |
| `:config-open` | Open `~/.config/helix/config.toml` |
| `:config-reload` | Reload config |
| `:log-open` | Open the log file (useful for debugging LSP) |
| `:lsp-restart` | Restart language servers |
| `:theme <name>` | Switch theme |
| `:format` | Format buffer |
| `:sh <cmd>` | Run shell command |
| `:pipe <cmd>` | Pipe selections through command |
| `:tree-sitter-scopes` | Inspect syntax scopes at cursor |

## Configuration

Main file: `~/.config/helix/config.toml`. Current user config:

```toml
theme = "onedark"

[editor]
line-number = "absolute"
```

Common `[editor]` options:
- `line-number = "relative" | "absolute"`
- `cursorline = true`
- `auto-save = true`
- `bufferline = "always" | "multiple" | "never"`
- `color-modes = true` (colors statusline/cursor by mode)
- `true-color = true`
- `rulers = [80, 120]`
- `soft-wrap.enable = true`

Sub-sections: `[editor.cursor-shape]`, `[editor.file-picker]`, `[editor.statusline]`, `[editor.lsp]`, `[editor.indent-guides]`, `[editor.whitespace]`, `[editor.soft-wrap]`.

### Custom keymaps

Add under `[keys.normal]`, `[keys.insert]`, `[keys.select]`:

```toml
[keys.normal]
C-s = ":w"
space.space = "file_picker"

[keys.normal.g]
q = "goto_last_modified_file"
```

### Languages (`~/.config/helix/languages.toml`)

User's current setup wires Python to the `ty` language server:

```toml
[[language]]
name = "python"
language-servers = ["ty"]

[language-server.ty]
command = "ty"
args = ["server"]
```

Typical fields on `[[language]]`: `name`, `scope`, `file-types`, `roots`, `auto-format`, `formatter`, `language-servers`, `indent`, `comment-tokens`.

Define LSPs under `[language-server.<name>]` with `command`, `args`, optional `config` (JSON sent as initialization options), `environment`.

## Useful discovery

- `:tutor` — built-in interactive tutorial.
- `hx --health` — check runtime, themes, language toolchains/LSPs.
- `hx --health <lang>` — check a specific language.
- Inside editor, press `Space ?` or run `:help` — no, Helix has no `:help`; use the [official book](https://docs.helix-editor.com/) instead.
- `:tree-sitter-scopes` at cursor shows which syntax nodes are active (handy for theme/scope debugging).
