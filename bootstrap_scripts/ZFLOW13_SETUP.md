# ZFlow13 (CachyOS) — admin machine setup

Turn a fresh CachyOS install into a full **control/admin box** with parity to the
MacBook: dotfiles + toolchain, and connectivity to **both** k3s clusters
(`rmhome` + `monlashsolutions`), `claude-local`, the finance stack, node SSH, etc.

Two halves:
- **Public** (in this repo): `cachyos_bootstrap.sh` — toolchain, dotfiles, shell, tailscale.
- **Secret** (never in the repo): `sync_admin_secrets.sh` — pushes SSH keys, git
  identity, kubeconfigs, and `~/.config/{rmhome,pihole,monlashsolutions}` from the Mac.

The ordering below resolves the chicken-and-egg (the box needs the GitHub SSH key
*before* it can clone this private repo — so secrets are pushed first).

---

## Step 0 — on the ZFlow13: minimal reachability
```bash
sudo pacman -Syu --needed openssh tailscale rsync
sudo systemctl enable --now sshd tailscaled
sudo tailscale up            # log in with the SAME account as the Mac
tailscale ip -4              # note the name/IP (e.g. zflow13 / 100.x.y.z)
```
Now the Mac can reach it as `rmathew@zflow13` (Tailscale MagicDNS) or by LAN IP.

## Step 1 — from the MacBook: push credentials
```bash
cd ~/Dev/dotfiles
./bootstrap_scripts/sync_admin_secrets.sh rmathew@zflow13     # Tailscale name or LAN IP
```
Copies (all as `0600`): `~/.ssh` keys, `~/.gitconfig*` (paths rewritten for Linux),
`~/.kube/{rmhome.kubeconfig, monlash.kubeconfig}`, and the three `~/.config` secret dirs.

## Step 2 — on the ZFlow13: clone + bootstrap
```bash
git clone git@github.com:rohitjm/dotfiles.git ~/Dev/dotfiles     # SSH key is now present
cd ~/Dev/dotfiles && ./bootstrap_scripts/cachyos_bootstrap.sh
exec zsh
```
The bootstrap installs the toolchain (kubectl/helm/kubectx/k9s/ansible/argocd/kubeseal,
git/gh/nvim/tmux, claude-code/aider), oh-my-zsh, symlinks dotfiles, sets zsh, enables
tailscale + libvirt, and **merges the copied kubeconfigs** into `~/.kube/config`
(contexts `rmhome` + `monlash`).

## Step 3 — verify parity
```bash
kubectx rmhome  && kubectl get nodes          # 10.0.0.39:6443 — needs LAN or tailscale
kubectx monlash && kubectl get nodes          # monlashsolutions-dev-01:6443 (see note)
gh auth login                                 # GitHub CLI (interactive, one-time)
claude --version                              # Claude Code
loadai && claude-local --version              # local-LLM Claude Code (uses litellm_master_key)
```

---

## Notes / gotchas
- **monlash API is a hostname** (`https://monlashsolutions-dev-01:6443`). It must
  resolve on the ZFlow13 — either via **Tailscale MagicDNS** (if that node is on the
  same tailnet) or add an `/etc/hosts` entry pointing at its IP. `rmhome` uses the LAN
  IP `10.0.0.39`, so you must be on the home Wi-Fi (or reach it via tailscale).
- **rmhome node SSH**: `ssh rmathew@10.0.0.{39,34,31}` works once the key is synced.
- **Private keys are copied** for parity (GitHub + node `authorized_keys` already trust
  `id_ed25519`). To avoid copying private keys, generate a new key on the box instead and
  add it to GitHub + each node's `authorized_keys`, then skip section 1 of the sync script.
- **Re-runnable**: both scripts are idempotent. Re-run `sync_admin_secrets.sh` anytime a
  secret changes on the Mac; re-run `cachyos_bootstrap.sh` to pick up new tools/dotfiles.
- **claude-local**: needs `~/.config/rmhome/litellm_master_key` (synced) and the `.ai`
  helper (`loadai` in the Linux zshrc). Points Claude Code at the AI workstation.
