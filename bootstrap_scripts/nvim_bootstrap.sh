#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Universal Neovim Bootstrap Script
# - Cross-platform (macOS + Linux/WSL)
# - Safe symlinking with backups
# - Dry-run + verbose modes
# - Rollback support
# - Logging + post-install summary
# ---------------------------------------------------------------------------

set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SRC_DIR="$DOTFILES_DIR/nvim"
DEST_DIR="$HOME/.config/nvim"
LOGFILE="$SCRIPT_DIR/nvim_bootstrap.log"
BACKUP_DIR="$SCRIPT_DIR/.backup_nvim"

# Runtime flags
dry_run=false
verbose=false
rollback=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --verbose) verbose=true ;;
    --rollback) rollback=true ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: $0 [--dry-run] [--verbose] [--rollback]" >&2
      exit 1
      ;;
  esac
done

# -----------------------------
# Helpers
# -----------------------------
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

vlog() {
  if $verbose; then log "[verbose] $1"; fi
}

run() {
  if $dry_run; then
    log "[dry-run] $*"
  else
    vlog "Running: $*"
    eval "$@"
  fi
}

backup_file() {
  local file="$1"
  mkdir -p "$BACKUP_DIR"
  if [ -e "$file" ] || [ -L "$file" ]; then
    local rel
    rel=$(realpath --relative-to="$HOME" "$file" 2>/dev/null || echo "$(basename "$file")")
    local dst="$BACKUP_DIR/${rel//\//_}.bak"
    log "Backing up $file -> $dst"
    run "mv -f \"$file\" \"$dst\""
  fi
}

create_symlink() {
  local src="$1"
  local dest="$2"

  backup_file "$dest"
  run "mkdir -p \"$(dirname "$dest")\""
  run "ln -sfn \"$src\" \"$dest\""
  log "Linked: $dest -> $src"
}

# -----------------------------
# Rollback Mode
# -----------------------------
if $rollback; then
  log "Rollback started - restoring backups from $BACKUP_DIR"
  if [ ! -d "$BACKUP_DIR" ]; then
    log "No backup directory found. Nothing to rollback."
    exit 0
  fi

  for f in "$BACKUP_DIR"/*.bak; do
    [ -e "$f" ] || continue
    original="${f%.bak}"
    original="$HOME/${original##*/}"  # map back into ~/

    log "Restoring $f -> $original"
    run "mv -f \"$f\" \"$original\""
  done

  log "Rollback completed."
  exit 0
fi

# -----------------------------
# Main Install Logic
# -----------------------------
log "Neovim bootstrap started."
log "dotfiles dir: $DOTFILES_DIR"
log "source dir:   $SRC_DIR"
log "dest dir:     $DEST_DIR"

run "mkdir -p \"$DEST_DIR\""

# Walk all files and symlink them into ~/.config/nvim
log "Processing files..."
while IFS= read -r file; do
  rel="${file#$SRC_DIR/}"
  src_path="$SRC_DIR/$rel"
  dest_path="$DEST_DIR/$rel"

  create_symlink "$src_path" "$dest_path"
done < <(find "$SRC_DIR" -type f)

log "Bootstrap complete."
log "All files linked into $DEST_DIR"

# -----------------------------
# Summary
# -----------------------------
log "Summary:"
log " - Backups stored in: $BACKUP_DIR"
log " - Log stored at: $LOGFILE"
log " - Dry-run: $dry_run"
log " - Verbose: $verbose"

# -----------------------------
# Usage Help
# -----------------------------
: <<'USAGE'
Usage:
  ./nvim_bootstrap.sh            # Normal install
  ./nvim_bootstrap.sh --dry-run  # Test without writing
  ./nvim_bootstrap.sh --verbose  # Extra logging
  ./nvim_bootstrap.sh --rollback # Restore backups
USAGE
