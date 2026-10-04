#!/bin/sh
# A cluster's admin contexts on this machine, from Infisical:
#
#   contexts.sh add <cluster> <infisical project id> <folder>
#   contexts.sh remove <cluster>
#
# add replaces the Talos context <cluster> in ~/.talos/config and the
# Kubernetes context admin@<cluster> - with its cluster and user - in
# ~/.kube/config, from TALOSCONFIG and KUBECONFIG in the folder; remove takes
# them out. Every other context, and which one is current, is left as it was.
# Run by Terraform (clients.tf); nothing is printed but the contexts' names.
set -eu

action=$1
cluster=$2
talos=${TALOSCONFIG:-$HOME/.talos/config}
kube=$HOME/.kube/config

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
umask 077

# Out of ~/.kube/config, if there: admin@<cluster> and its cluster and user.
kube_remove() {
  [ -f "$kube" ] || return 0
  kubectl --kubeconfig "$kube" config delete-context "admin@$cluster" >/dev/null 2>&1 || true
  kubectl --kubeconfig "$kube" config delete-cluster "$cluster" >/dev/null 2>&1 || true
  kubectl --kubeconfig "$kube" config delete-user "admin@$cluster" >/dev/null 2>&1 || true
}

# The Talos contexts' names, and the current one.
talos_contexts() {
  talosctl --talosconfig "$talos" config contexts 2>/dev/null | awk 'NR > 1 { print ($1 == "*" ? $2 : $1) }'
}
talos_current() {
  talosctl --talosconfig "$talos" config contexts 2>/dev/null | awk '$1 == "*" { print $2 }'
}

# Out of ~/.talos/config, if there; merging beside an old one would name the
# new one <cluster>-1. talosctl will not remove the current context, so
# another becomes current first - or, if it is the only one, the file goes.
talos_remove() {
  [ -f "$talos" ] || return 0
  talos_contexts | grep -qx "$cluster" || return 0
  if [ "$(talos_current)" = "$cluster" ]; then
    other=$(talos_contexts | grep -vx "$cluster" | head -n 1)
    if [ -z "$other" ]; then
      rm -f "$talos"
      return 0
    fi
    talosctl --talosconfig "$talos" config context "$other" >/dev/null
  fi
  talosctl --talosconfig "$talos" config remove "$cluster" --noconfirm >/dev/null
}

case $action in
add)
  project=$3
  folder=$4
  infisical secrets get TALOSCONFIG --projectId "$project" --env prod --path "$folder" --plain --silent >"$tmp/talosconfig"
  infisical secrets get KUBECONFIG --projectId "$project" --env prod --path "$folder" --plain --silent >"$tmp/kubeconfig"

  # talosctl's merge makes the new context current; keep the one that was.
  current=$(talos_current)
  talos_remove
  mkdir -p "$(dirname "$talos")"
  talosctl --talosconfig "$talos" config merge "$tmp/talosconfig" >/dev/null
  if [ -n "$current" ] && [ "$current" != "$cluster" ]; then
    talosctl --talosconfig "$talos" config context "$current" >/dev/null
  fi

  # The first file's current-context wins, so ~/.kube/config keeps its own.
  kube_remove
  mkdir -p "$(dirname "$kube")"
  [ -f "$kube" ] || : >"$kube"
  KUBECONFIG="$kube:$tmp/kubeconfig" kubectl config view --flatten >"$tmp/merged"
  cat "$tmp/merged" >"$kube"
  echo "contexts added: $cluster (talosctl), admin@$cluster (kubectl)"
  ;;
remove)
  talos_remove
  kube_remove
  echo "contexts removed: $cluster (talosctl), admin@$cluster (kubectl)"
  ;;
*)
  echo "usage: $0 add <cluster> <project id> <folder> | remove <cluster>" >&2
  exit 2
  ;;
esac
