# dotfiles

Personal config for bootstrapping a Unix machine. Works on **macOS** and
**Linux, including WSL**.

## Bootstrap a new machine

```bash
git clone <this repo> ~/Dev/dotfiles
~/Dev/dotfiles/bootstrap_scripts/bootstrap.sh
```

It detects the OS, installs any missing packages (Homebrew on macOS, apt on
Linux), and symlinks config into place. Anything real it would overwrite is
moved to `~/.dotfiles_backup_<timestamp>/` first, and a rollback script is
written to `~/.dotfiles_rollback.sh`.

Re-running is safe. To undo: `bootstrap_scripts/teardown.sh`.

## What goes where

| Source | Symlinked to |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `nvim/` | `~/.config/nvim/` (per-file symlinks) |
| `tmux/.tmux.conf` | `~/.config/tmux/tmux.conf` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/` (if alacritty present) |
| `wezterm/wezterm.lua` | `~/.config/wezterm/` (if wezterm present) |

## Shell layout

`.zshrc` sources these on startup:

- `zsh/.oh-my-zsh` — theme + plugins
- `zsh/.tmux` — tmux aliases (`tx`, `txa`, `tmux-grid`, ...)
- `zsh/.clipboard-helper` — cross-platform `pc`/`pp`. Picks `pbcopy` on macOS,
  `clip.exe`/`powershell.exe` on WSL, `wl-copy`/`xclip`/`xsel` on Linux. Run
  `install-clipboard-tool` if none are present.
- `zsh/.ai` — local AI workstation helpers (see below)

Machine-specific secrets go in `untracked/` (gitignored) and are sourced only if
present, so the same `.zshrc` works everywhere.

## Portability notes

macOS-specific PATH entries (Homebrew, `/Applications/...`, openJDK) are behind a
`uname == Darwin` guard. pyenv, Go, nvm, and SDKMAN are each loaded only if
actually installed, so a fresh box doesn't spew errors on shell startup.

## Local AI workstation

This machine (RTX PRO 6000, 96GB) serves LLM inference to the LAN, replacing SaaS
inference for Claude Code and other clients. The stack lives **outside this repo**
at `~/Dev/ai-stack` — it holds a secret and is machine-specific infrastructure
rather than portable config. See `~/Dev/ai-stack/README.md`.

`zsh/.ai` is portable and works on **any machine**:

- On the workstation it also defines `aiup`, `aidown`, `ailogs`, `aigpu`, and
  `ai-client-config` (those are skipped elsewhere, since a client has no gateway
  to manage and no GPU to inspect).
- On a LAN client, `claude-local` runs Claude Code against the workstation's GPU.
  It needs `untracked/.ai_env` with `AI_GATEWAY_URL` and `AI_GATEWAY_KEY` — run
  `ai-client-config` on the workstation to print that block. It's gitignored, so
  the key never lands in the repo.
