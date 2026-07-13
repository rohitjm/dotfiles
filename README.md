# dotfiles

Personal config for bootstrapping a Unix machine. Works on **macOS** and
**Linux, including WSL**.

## Bootstrap a new machine

1. **Clone and run bootstrap.**

   ```bash
   git clone <this repo> ~/Dev/dotfiles
   ~/Dev/dotfiles/bootstrap_scripts/bootstrap.sh
   ```

   It detects the OS, installs missing packages (Homebrew on macOS, apt on
   Linux), and symlinks config into place. Anything real it would overwrite is
   moved to `~/.dotfiles_backup_<timestamp>/` first, and a rollback script is
   written to `~/.dotfiles_rollback.sh`. Package installs are non-fatal — the
   symlinks land even if a package fails.

   On macOS, check that `brew bundle` resolves formulae rather than throwing a
   parse error.

2. **Reload the shell.**

   ```bash
   exec zsh
   ```

   Expect `Loaded Oh-my-ZSH!!`, `Loaded TMUX config!!`, `Loaded AI workstation
   config!!`, and no errors.

3. **Sanity-check.**

   ```bash
   echo test | pc && pp      # clipboard round-trips
   echo $DOTFILE_HOME        # ~/Dev/dotfiles
   ```

4. **Optionally point Claude Code at the local GPU** — see
   [Using the AI workstation from this machine](#using-the-ai-workstation-from-this-machine).

Re-running bootstrap is safe. To undo: `bootstrap_scripts/teardown.sh`.

### Careful with nvim on a freshly bootstrapped machine

Bootstrap symlinks `nvim/lazy-lock.json` into `~/.config/nvim/`, so lazy.nvim
can write **straight back into the repo** and clobber pinned plugin versions —
on a fresh box it rewrites the lockfile to match the handful of plugins it has
actually installed, silently dropping the rest. After the first nvim launch:

```bash
git -C ~/Dev/dotfiles diff nvim/lazy-lock.json   # restore it if it shrank
```

Tracked in issue #13.

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
  `ai-client-config` (skipped elsewhere — a client has no gateway to manage and
  no GPU to inspect).
- On a LAN client, `claude-local` runs Claude Code against the workstation's GPU.

### Using the AI workstation from this machine

Only works on the same LAN as the workstation. A VPN client (NordVPN, etc.) will
intercept the traffic and break it.

1. **On the workstation**, print the config block:

   ```bash
   ai-client-config
   ```

2. **On this machine**, save it to `untracked/.ai_env`:

   ```bash
   mkdir -p ~/Dev/dotfiles/untracked
   cat > ~/Dev/dotfiles/untracked/.ai_env    # paste the two lines, then Ctrl-D
   exec zsh
   ```

   `untracked/` is gitignored — that's the point. The API key never enters the
   repo, which is also why this step is manual rather than something bootstrap
   can do for you.

3. **Verify and use it:**

   ```bash
   aiping                    # gateway reachable?
   aimodels                  # what it can serve
   claude-local              # pick a model, run Claude Code against the GPU
   claude-local -m local-fast
   claude                    # unchanged: still the real Anthropic API
   ```

If `aiping` fails, this machine either isn't on the workstation's LAN or a VPN is
in the way.

### Don't ask the model where it's running

It will lie — not maliciously, it simply has no introspective access to its own
deployment. Claude Code's system prompt says "you are Claude Code, Anthropic's
official CLI", so a local model reads that and confabulates the rest, happily
reporting a model id like `claude-opus-4-8` that it was never given. This is
convincing and completely wrong.

Trust the infrastructure instead:

| Check | Where |
|---|---|
| Claude Code's status line | shows the real configured model, e.g. `local-fast` |
| `aigpu` | what's actually resident in the workstation's VRAM |
| `docker logs litellm` | the requests the gateway actually served |

If the model is loaded on the GPU and the gateway logged the request, the
inference ran locally, whatever the model claims about itself.
