output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

# Printed after every apply: what replaces the lab's contexts on this
# machine. A rebuilt cluster has new certificates, so the old contexts are
# removed or overwritten - never merged beside, which would leave lab-1.
output "connect" {
  value = <<-EOT
    talosctl config remove ${local.cluster.name} -y
    f=$(mktemp) && terraform output -raw talosconfig > "$f" && talosctl config merge "$f"; rm -f "$f"
    talosctl --context ${local.cluster.name} -n ${local.first_controlplane} kubeconfig --force
    kubectl --context admin@${local.cluster.name} get nodes
  EOT
}
