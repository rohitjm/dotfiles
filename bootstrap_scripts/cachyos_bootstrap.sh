#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# CachyOS (Arch) client bootstrap — ds_workstation, zflow13, and future boxes.
#
# Idempotent & re-runnable. Installs the CLI/dev toolchain, symlinks the dotfiles
# in this repo, sets zsh up, and wires kubectl to administer BOTH the rmhome and
# monlashsolutions k3s clusters (pulled from each control-plane over SSH — no
# secrets are ever committed to this repo).
#
# Usage on a fresh CachyOS install (full runbook: ZFLOW13_SETUP.md):
#   0. On the box:  sudo pacman -S openssh tailscale rsync && \
#                   sudo systemctl enable --now sshd tailscaled && sudo tailscale up
#   1. From your Mac:  ./bootstrap_scripts/sync_admin_secrets.sh <user@this-box>
#      (delivers SSH keys, git identity, both kubeconfigs, ~/.config secrets)
#   2. git clone git@github.com:rohitjm/dotfiles.git ~/Dev/dotfiles
#   3. cd ~/Dev/dotfiles && ./bootstrap_scripts/cachyos_bootstrap.sh
#
# If you DIDN'T run sync_admin_secrets (no copied kubeconfigs), this falls back to
# pulling them over SSH — set the CLUSTER CONFIG block below (monlash IP/SSH) first.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/Dev/dotfiles}"
LOG="$DOTFILES/bootstrap_scripts/cachyos_bootstrap.log"

# ── CLUSTER CONFIG (edit these) ──────────────────────────────────────────────
RMHOME_SSH="rmathew@10.0.0.39"      # rmhome control-plane (dev-01) SSH target
RMHOME_API="https://10.0.0.39:6443" # rmhome API server (LAN)
MONLASH_SSH=""                      # <<< SET: user@host for monlash CP (e.g. rmathew@10.0.x.x)
MONLASH_API=""                      # <<< SET: https://<monlash-cp-ip>:6443
# ─────────────────────────────────────────────────────────────────────────────

log()  { echo "$(date '+%F %T') - $*" | tee -a "$LOG"; }
have() { command -v "$1" >/dev/null 2>&1; }
ok()   { echo "  ✅ $*"; }
warn() { echo "  ⚠️  $*"; }

log "=== CachyOS bootstrap started (DOTFILES=$DOTFILES) ==="
have pacman || { echo "This script is for Arch/CachyOS (pacman not found)."; exit 1; }
[ -d "$DOTFILES" ] || { echo "Dotfiles not found at $DOTFILES — clone the repo first."; exit 1; }

# ── 1. system update + AUR helper (CachyOS ships paru; install if missing) ────
log "Updating system + ensuring AUR helper..."
sudo pacman -Syu --noconfirm --needed
if ! have paru && ! have yay; then
  sudo pacman -S --noconfirm --needed base-devel git
  tmp=$(mktemp -d); git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru"
  ( cd "$tmp/paru" && makepkg -si --noconfirm ); rm -rf "$tmp"
fi
AUR=$(have paru && echo paru || echo yay)
ok "AUR helper: $AUR"

# ── 2. packages from the official repos ──────────────────────────────────────
# (Maps the macOS Brewfile/leaves to Arch package names.)
log "Installing official-repo packages..."
sudo pacman -S --noconfirm --needed \
  base-devel git zsh neovim tmux starship lazygit github-cli \
  fzf ripgrep fd bat eza zoxide jq yq wget tree cmake pkgconf man-db \
  ffmpeg perl-image-exiftool pandoc protobuf enchant xorriso \
  python python-pipx uv nodejs npm rust go jdk-openjdk ruby \
  qemu-full libvirt virt-manager dnsmasq edk2-ovmf \
  kubectl helm kubectx k9s ansible \
  tailscale \
  xclip wl-clipboard unzip rsync openssh \
  || warn "some pacman packages failed — check the log"

# ── 3. packages from the AUR ─────────────────────────────────────────────────
log "Installing AUR packages..."
$AUR -S --noconfirm --needed \
  kubeseal kustomize argocd \
  visual-studio-code-bin wezterm alacritty \
  || warn "some AUR packages failed — skip GUI ones on a headless box"

# ── 4. AI / coding tools ─────────────────────────────────────────────────────
log "Installing AI/coding CLIs..."
have claude || npm install -g @anthropic-ai/claude-code || warn "claude-code install failed"
have aider  || uv tool install aider-chat || warn "aider install failed"
# LM Studio (GUI) is AUR: '$AUR -S lmstudio' — install manually on desktops only.

# ── 5. oh-my-zsh + shell plugins ─────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ── 6. symlink dotfiles ──────────────────────────────────────────────────────
log "Symlinking dotfiles..."
link() { mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; ok "$2 -> $1"; }
link "$DOTFILES/zsh/.zshrc.linux"        "$HOME/.zshrc"          # Linux zshrc (see file)
link "$DOTFILES/zsh/.oh-my-zsh"          "$HOME/.oh-my-zsh-conf" # sourced by .zshrc.linux
link "$DOTFILES/tmux/.tmux.conf"         "$HOME/.tmux.conf"
link "$DOTFILES/nvim"                    "$HOME/.config/nvim"
[ -f "$DOTFILES/alacritty/alacritty.toml" ] && link "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
[ -f "$DOTFILES/wezterm/wezterm.lua" ]      && link "$DOTFILES/wezterm/wezterm.lua"      "$HOME/.config/wezterm/wezterm.lua"

# ── 7. default shell -> zsh ──────────────────────────────────────────────────
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  log "Setting default shell to zsh..."
  sudo chsh -s "$(command -v zsh)" "$USER" || warn "chsh failed — run manually"
fi

# ── 8. cluster admin — wire up kubectl for both clusters ─────────────────────
"$DOTFILES/bootstrap_scripts/cluster_setup.sh" \
  --rmhome-ssh "$RMHOME_SSH" --rmhome-api "$RMHOME_API" \
  --monlash-ssh "$MONLASH_SSH" --monlash-api "$MONLASH_API" || warn "cluster setup incomplete"

# ── 9. libvirt (for the Windows VM on ds_workstation) ────────────────────────
if have virsh; then
  sudo systemctl enable --now libvirtd 2>/dev/null || true
  sudo usermod -aG libvirt,kvm "$USER" 2>/dev/null || true
  ok "libvirtd enabled; added $USER to libvirt,kvm (re-login to take effect)"
fi

# ── 10. tailscale (off-LAN cluster access + monlash MagicDNS) ─────────────────
if have tailscale; then
  sudo systemctl enable --now tailscaled 2>/dev/null || true
  if ! tailscale status >/dev/null 2>&1; then
    warn "tailscale installed but not logged in — run:  sudo tailscale up   (same account as this Mac)"
  else
    ok "tailscale up ($(tailscale ip -4 2>/dev/null | head -1))"
  fi
fi

# ── 11. git identity fallback (sync_admin_secrets.sh normally copies ~/.gitconfig) ──
if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
  git config --global user.name  "Rohit Mathew"
  git config --global user.email "rohit.mathew@thevirtussolution.com"
  ok "set fallback git identity (edit ~/.gitconfig if you synced per-dir identities)"
fi

log "=== bootstrap complete ==="
cat <<EOF

Next steps:
  • Re-login (or 'exec zsh') to pick up the new shell, groups, and PATH.
  • Cluster access:  kubectx rmhome   |   kubectx monlash   (kb = kubectl)
  • gh auth login   (GitHub CLI)   •   claude    (Claude Code)
  • On ds_workstation: set MONLASH_SSH/MONLASH_API above if you skipped it,
    then re-run — and see the rmhome repo for k3s-join + IOMMU/VM setup.
EOF
