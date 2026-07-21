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

# k3s names its cluster, user, AND context all "default". Renaming only the context
# (kubectl's only rename verb) is NOT enough: when two such kubeconfigs are flattened
# into one ~/.kube/config, their identically-named "default" cluster+user entries collide
# (last wins), so every context silently resolves to the same cluster. Normalize all three
# names to $name so multiple clusters truly coexist. Needs yq (installed by the bootstrap).
normalize_names() {
  local out="$1" name="$2"
  if ! command -v yq >/dev/null; then
    echo "  ⚠️  yq not found — cluster/user names left as 'default'; contexts WILL collide on flatten"; return
  fi
  yq -y -i "
    .clusters[0].name = \"$name\" | .users[0].name = \"$name\" |
    .contexts[0].name = \"$name\" | .contexts[0].context.cluster = \"$name\" |
    .contexts[0].context.user = \"$name\" | .\"current-context\" = \"$name\"
  " "$out"
}

# Pull one cluster's kubeconfig, rewrite server, normalize all names to $name.
pull() {
  local name="$1" ssh_target="$2" api="$3" out="$KDIR/${1}.kubeconfig"
  # If sync_admin_secrets.sh already copied this kubeconfig, use it as-is (certs
  # embedded + right server); otherwise pull it from the control-plane over SSH.
  if [ -s "$out" ]; then
    echo "  ✅ $name: using existing $out"
  elif [ -z "$ssh_target" ]; then
    echo "  ⏭  $name: no SSH target set — skipping (edit the config)"; return 1
  else
    echo "  ⤵  $name: pulling kubeconfig from $ssh_target ..."
    if ! ssh -o ConnectTimeout=8 -o BatchMode=yes "$ssh_target" \
          'sudo cat /etc/rancher/k3s/k3s.yaml' > "$out.tmp" 2>/dev/null || [ ! -s "$out.tmp" ]; then
      echo "  ⚠️  $name: SSH pull failed (key/reachability?) — skipping"; rm -f "$out.tmp"; return 1
    fi
    sed -i "s#server: https://127.0.0.1:6443#server: ${api}#" "$out.tmp"
    mv "$out.tmp" "$out"; chmod 600 "$out"
  fi
  normalize_names "$out" "$name"
  echo "  ✅ $name -> $out (context/cluster/user: $name)"
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
