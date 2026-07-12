#!/usr/bin/env bash
set -euo pipefail

############################################################
# Dotfiles Bootstrap Tear-down Script
# Reverts changes made by bootstrap.sh
# WARNING: This will remove symlinks and restore backups.
############################################################

DOTFILES_BACKUP_DIR="$HOME/.dotfiles_backup"  # default backup directory prefix
ROLLBACK_SCRIPT="$HOME/.dotfiles_rollback.sh"

log() { echo "[+] $*"; }

# -----------------------------
# 1. Run rollback script if it exists
# -----------------------------
if [[ -f "$ROLLBACK_SCRIPT" ]]; then
    log "Running rollback script..."
    bash "$ROLLBACK_SCRIPT"
    log "Rollback completed."
else
    log "No rollback script found at $ROLLBACK_SCRIPT"
fi

# -----------------------------
# 2. Remove Oh-My-Zsh (if installed)
# -----------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Removing Oh-My-Zsh..."
    rm -rf "$HOME/.oh-my-zsh"
    rm -f "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zlogout"
    log "Oh-My-Zsh removed."
fi

# -----------------------------
# 3. Reset default shell to Bash
# -----------------------------
CURRENT_SHELL=$(getent passwd $USER | cut -d: -f7 2>/dev/null || echo $SHELL)
BASH_PATH=$(which bash)
if [[ "$CURRENT_SHELL" != "$BASH_PATH" ]]; then
    log "Resetting default shell to bash for user $USER..."
    chsh -s "$BASH_PATH" "$USER" || log "Failed to reset shell; do it manually with chsh -s $(which bash)"
    log "Default shell reset to bash. Please log out and log back in."
fi

# -----------------------------
# 4. Remove symlinks created for dotfiles
# -----------------------------
DOTFILE_LINKS=(
    "$HOME/.zshrc"
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/nvim"
    "$HOME/.config/alacritty/alacritty.toml"
    "$HOME/.config/wezterm/wezterm.lua"
)
for dst in "${DOTFILE_LINKS[@]}"; do
    if [[ -L "$dst" ]]; then
        log "Removing symlink: $dst"
        rm -f "$dst"
    fi
done

# -----------------------------
# 5. Restore backups (optional)
# -----------------------------
BACKUPS=($(ls -d $DOTFILES_BACKUP_DIR* 2>/dev/null || true))
if [[ ${#BACKUPS[@]} -gt 0 ]]; then
    log "Restoring backups from $DOTFILES_BACKUP_DIR*"
    for backup in "${BACKUPS[@]}"; do
        cp -r "$backup/"* "$HOME/"
        log "Restored files from $backup"
    done
fi

log "Tear-down complete. User environment reset."
