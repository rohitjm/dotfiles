#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Push admin CREDENTIALS from this Mac to a fresh admin box (e.g. the zflow13),
# so it can do everything this machine can: administer BOTH k3s clusters (rmhome +
# monlashsolutions), run claude-local, drive the finance stack, SSH the nodes, etc.
#
# NONE of this lives in the repo — it's a one-shot secure copy over SSH/Tailscale.
# It copies: SSH keys, git identity, both kubeconfigs, and the ~/.config secret
# dirs. It does NOT need kubectl on the target (the bootstrap merges kubeconfigs).
#
# Run this AFTER the target has sshd running + is reachable, and BEFORE cloning
# the dotfiles repo there (this is what delivers the GitHub SSH key).
#
#   ./sync_admin_secrets.sh rmathew@zflow13         # Tailscale MagicDNS name, or
#   ./sync_admin_secrets.sh rmathew@10.0.0.xx       # LAN IP
#
# Security note: this copies PRIVATE keys. That's the simplest way to get parity
# (GitHub + every node's authorized_keys already trust this key). If you'd rather
# not copy private keys, generate a new key on the target instead and add it to
# GitHub + each node's ~/.ssh/authorized_keys — then skip section 1 here.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "usage: $0 user@host   (Tailscale name or LAN IP of the new box)"; exit 1; }

command -v rsync >/dev/null || { echo "rsync not found on this Mac"; exit 1; }
echo "→ Testing SSH to $TARGET ..."
ssh -o ConnectTimeout=8 -o BatchMode=no "$TARGET" 'echo "  connected as $(whoami)@$(hostname)"' || {
  echo "✗ can't SSH to $TARGET. On the target: sudo systemctl enable --now sshd, and make sure it's reachable (Tailscale up / same LAN)."; exit 1; }

R() { rsync -av --chmod=F600 "$@"; }   # copy files as 0600

# ── 1. SSH keys (GitHub + node/cluster access) ───────────────────────────────
echo "→ SSH keys ..."
ssh "$TARGET" 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
for k in id_ed25519 id_ed25519.pub monlashsolutions_github monlashsolutions_github.pub config known_hosts; do
  [ -f "$HOME/.ssh/$k" ] && R "$HOME/.ssh/$k" "$TARGET:.ssh/$k"
done

# ── 2. git identity (global + the per-dir includes; rewrite Mac paths) ────────
echo "→ git identity ..."
for g in .gitconfig .gitconfig-personal .gitconfig-monlash; do
  [ -f "$HOME/$g" ] && R "$HOME/$g" "$TARGET:$g"
done
# includeIf paths in ~/.gitconfig are Mac-absolute (/Users/rohitmathew/...) —
# rewrite to the target's $HOME so the conditional includes still resolve.
ssh "$TARGET" 'f=~/.gitconfig; [ -f "$f" ] && sed -i "s#/Users/rohitmathew/#$HOME/#g" "$f" && echo "  rewrote gitconfig include paths -> $HOME"'

# ── 3. kubeconfigs (rmhome + monlash; monlash renamed to the bootstrap name) ──
echo "→ kubeconfigs ..."
ssh "$TARGET" 'mkdir -p ~/.kube && chmod 700 ~/.kube'
[ -f "$HOME/.kube/rmhome.kubeconfig" ]            && R "$HOME/.kube/rmhome.kubeconfig"            "$TARGET:.kube/rmhome.kubeconfig"
[ -f "$HOME/.kube/monlashsolutions-dev-01.yaml" ] && R "$HOME/.kube/monlashsolutions-dev-01.yaml" "$TARGET:.kube/monlash.kubeconfig"

# ── 4. ~/.config secret dirs (rmhome 48 secrets, pihole, monlash PAT) ─────────
echo "→ ~/.config secrets ..."
for d in rmhome pihole monlashsolutions; do
  if [ -d "$HOME/.config/$d" ]; then
    ssh "$TARGET" "mkdir -p ~/.config/$d && chmod 700 ~/.config/$d"
    rsync -av --chmod=F600 "$HOME/.config/$d/" "$TARGET:.config/$d/"
  fi
done

cat <<EOF

✅ Credentials pushed to $TARGET.
Next, ON the target (zflow13):
  1. git clone git@github.com:rohitjm/dotfiles.git ~/Dev/dotfiles   # key is now there
  2. cd ~/Dev/dotfiles && ./bootstrap_scripts/cachyos_bootstrap.sh  # toolchain + merges kubeconfigs
  3. exec zsh ; kubectx rmhome | kubectx monlash                    # verify both clusters
Note: monlash's API is https://monlashsolutions-dev-01:6443 — that name must resolve
on the target (Tailscale MagicDNS on the monlash tailnet, or add it to /etc/hosts).
EOF
