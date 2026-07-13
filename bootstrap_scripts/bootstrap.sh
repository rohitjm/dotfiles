#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Dotfiles bootstrap
# - Cross-platform: macOS and Linux (including WSL)
# - Idempotent: safe to re-run
# - Backs up any real (non-symlink) file it would overwrite, and records
#   the moves in a rollback script that teardown.sh can use
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$HOME/.dotfiles_backup_$(date '+%Y%m%d%H%M%S')"
ROLLBACK_SCRIPT="$HOME/.dotfiles_rollback.sh"

log() { echo "[+] $*"; }

# -----------------------------
# OS detection
# -----------------------------
OS="linux"
if [[ "$(uname -s)" == "Darwin" ]]; then
  OS="macos"
fi
IS_WSL=false
if [[ "$OS" == "linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi
log "Detected OS: $OS$($IS_WSL && echo ' (WSL)')"

# -----------------------------
# Symlink helper: backs up any existing real file/dir before linking
# -----------------------------
link_dotfile() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    # Already a symlink; just repoint it.
    ln -sfn "$src" "$dest"
    log "Relinked: $dest -> $src"
    return
  fi

  if [[ -e "$dest" ]]; then
    mkdir -p "$BACKUP_DIR"
    local rel
    rel=$(basename "$dest")
    log "Backing up existing $dest -> $BACKUP_DIR/$rel"
    mv -f "$dest" "$BACKUP_DIR/$rel"
    echo "mv -f \"$BACKUP_DIR/$rel\" \"$dest\"" >> "$ROLLBACK_SCRIPT"
  fi

  ln -sfn "$src" "$dest"
  log "Linked: $dest -> $src"
}

# -----------------------------
# Package installation
# -----------------------------
install_packages() {
  if [[ "$OS" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
      log "Installing packages via Homebrew (Brewfile)..."
      brew bundle --file="$DOTFILES/homebrew/Brewfile" || \
        log "WARNING: brew bundle failed; continuing to symlink dotfiles anyway."
    else
      log "Homebrew not found; skipping package install. See https://brew.sh"
    fi
  else
    if ! command -v apt-get >/dev/null 2>&1; then
      log "apt-get not found; install nvim, tmux, tree, fzf, zsh, xclip manually."
      return
    fi

    # Only shell out to sudo for packages that are actually absent, so re-running
    # bootstrap on a provisioned machine doesn't sit there waiting for a password.
    local pkgs=(neovim tmux tree fzf zsh xclip)
    local missing=()
    for p in "${pkgs[@]}"; do
      local bin="$p"
      [[ "$p" == "neovim" ]] && bin="nvim"
      command -v "$bin" >/dev/null 2>&1 || missing+=("$p")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
      log "All packages already installed; nothing to do."
    else
      log "Installing missing packages: ${missing[*]}"
      # Non-fatal: getting the symlinks in place matters more than the packages,
      # and this script runs with `set -e`.
      { sudo apt-get update && sudo apt-get install -y "${missing[@]}"; } || \
        log "WARNING: apt install failed; continuing to symlink dotfiles anyway."
    fi
  fi
}

# -----------------------------
# Run
# -----------------------------
: > "$ROLLBACK_SCRIPT"
chmod +x "$ROLLBACK_SCRIPT"

install_packages

#### ZSH ####
link_dotfile "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

if [[ "$(basename "$SHELL")" != "zsh" ]] && command -v zsh >/dev/null 2>&1; then
  log "Default shell is not zsh. Run: chsh -s \$(command -v zsh)"
fi

#### TMUX ####
link_dotfile "$DOTFILES/tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"

#### NVIM ####
log "Running Neovim bootstrap..."
"$SCRIPT_DIR/nvim_bootstrap.sh"

#### Alacritty (optional GUI terminal config) ####
if [[ "$OS" == "macos" ]] || command -v alacritty >/dev/null 2>&1; then
  link_dotfile "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
fi

#### WezTerm (optional GUI terminal config) ####
if [[ "$OS" == "macos" ]] || command -v wezterm >/dev/null 2>&1; then
  link_dotfile "$DOTFILES/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
fi

if [[ -d "$BACKUP_DIR" ]]; then
  log "Existing files backed up to: $BACKUP_DIR"
  log "Rollback script written to: $ROLLBACK_SCRIPT (used by teardown.sh)"
fi

log "Bootstrap complete."
