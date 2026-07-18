#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Wire up kubectl to administer both k3s clusters (rmhome + monlashsolutions).
#
# Pulls each cluster's kubeconfig from its control-plane over SSH (k3s stores it
# at /etc/rancher/k3s/k3s.yaml with server=127.0.0.1), rewrites the API server to
# the reachable address, renames the context/cluster/user to the cluster name,
# and flattens both into ~/.kube/config so `kubectx rmhome|monlash` switches.
#
# NOTHING here is committed — kubeconfigs contain client certs and live only in
# ~/.kube on the machine. Requires SSH access to each control-plane.
#
# Called by cachyos_bootstrap.sh, or run standalone:
#   ./cluster_setup.sh --rmhome-ssh rmathew@10.0.0.39 --rmhome-api https://10.0.0.39:6443 \
#                      --monlash-ssh user@ip --monlash-api https://ip:6443
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

RMHOME_SSH="" RMHOME_API="" MONLASH_SSH="" MONLASH_API=""
while [ $# -gt 0 ]; do case "$1" in
  --rmhome-ssh)  RMHOME_SSH="$2"; shift 2;;
  --rmhome-api)  RMHOME_API="$2"; shift 2;;
  --monlash-ssh) MONLASH_SSH="$2"; shift 2;;
  --monlash-api) MONLASH_API="$2"; shift 2;;
  *) echo "unknown arg: $1"; exit 1;;
esac; done

KDIR="$HOME/.kube"; mkdir -p "$KDIR"; chmod 700 "$KDIR"
command -v kubectl >/dev/null || { echo "kubectl not installed yet"; exit 1; }

# Pull one cluster's kubeconfig, rewrite server, rename context to $name.
pull() {
  local name="$1" ssh_target="$2" api="$3" out="$KDIR/${1}.kubeconfig"
  # If sync_admin_secrets.sh already copied this kubeconfig, use it as-is (it has
  # certs embedded + the right server) — just make sure the context is named $name.
  if [ -s "$out" ]; then
    local cur; cur=$(KUBECONFIG="$out" kubectl config current-context 2>/dev/null || true)
    [ -n "$cur" ] && [ "$cur" != "$name" ] && KUBECONFIG="$out" kubectl config rename-context "$cur" "$name" >/dev/null 2>&1 || true
    echo "  ✅ $name: using existing $out (context: $name)"; return 0
  fi
  [ -z "$ssh_target" ] && { echo "  ⏭  $name: no SSH target set — skipping (edit the config)"; return 1; }
  echo "  ⤵  $name: pulling kubeconfig from $ssh_target ..."
  if ! ssh -o ConnectTimeout=8 -o BatchMode=yes "$ssh_target" \
        'sudo cat /etc/rancher/k3s/k3s.yaml' > "$out.tmp" 2>/dev/null || [ ! -s "$out.tmp" ]; then
    echo "  ⚠️  $name: SSH pull failed (key/reachability?) — skipping"; rm -f "$out.tmp"; return 1
  fi
  sed -i "s#server: https://127.0.0.1:6443#server: ${api}#" "$out.tmp"
  # k3s names context/cluster/user all "default" → rename so both clusters coexist
  KUBECONFIG="$out.tmp" kubectl config rename-context default "$name" >/dev/null 2>&1
  mv "$out.tmp" "$out"; chmod 600 "$out"
  echo "  ✅ $name -> $out (context: $name)"
}

echo "Wiring kubectl for both clusters..."
pull rmhome  "$RMHOME_SSH"  "$RMHOME_API"  || true
pull monlash "$MONLASH_SSH" "$MONLASH_API" || true

# Flatten whatever we successfully pulled into ~/.kube/config
FILES=""
[ -f "$KDIR/rmhome.kubeconfig" ]  && FILES="$FILES:$KDIR/rmhome.kubeconfig"
[ -f "$KDIR/monlash.kubeconfig" ] && FILES="$FILES:$KDIR/monlash.kubeconfig"
FILES="${FILES#:}"
if [ -n "$FILES" ]; then
  [ -f "$KDIR/config" ] && cp "$KDIR/config" "$KDIR/config.bak.$(date +%s)"
  KUBECONFIG="$FILES" kubectl config view --flatten > "$KDIR/config.new" && mv "$KDIR/config.new" "$KDIR/config"
  chmod 600 "$KDIR/config"
  echo "  ✅ merged into ~/.kube/config — contexts:"
  kubectl config get-contexts -o name | sed 's/^/     /'
else
  echo "  ⚠️  no kubeconfigs pulled — set the SSH targets and re-run cluster_setup.sh"
fi
