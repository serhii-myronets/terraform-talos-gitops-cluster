# The admin's client configurations: made from the Talos secrets, written to
# Infisical beside them, and merged into this Mac's ~/.talos/config and
# ~/.kube/config - the contexts lab and admin@lab - with nothing to copy by
# hand. A destroy takes them out of both places again.

# The admin kubeconfig, made from the secrets like the talosconfig: valid as
# long as the Kubernetes CA, the same on every run.
ephemeral "talos_cluster_kubeconfig" "admin" {
  cluster_name    = local.cluster.name
  endpoint        = local.cluster.endpoint
  machine_secrets = local.machine_secrets
}

locals {
  # Both configurations follow from the secrets alone, so they need writing
  # again only when the secrets change. A write-only value cannot be compared
  # with what Infisical holds; this number, from the secrets' digest, is what
  # tells Terraform to write them again.
  clients_version = parseint(substr(sha256(data.infisical_secrets.talos.secrets["SECRETS_YAML"].value), 0, 8), 16)
}

# Write-only: in Infisical, never in Terraform's state.
resource "infisical_secret" "talosconfig" {
  workspace_id     = local.infisical.project_id
  env_slug         = "prod"
  folder_path      = local.infisical.talos_path
  name             = "TALOSCONFIG"
  value_wo         = ephemeral.talos_client_configuration.this.talos_config
  value_wo_version = local.clients_version
}

resource "infisical_secret" "kubeconfig" {
  workspace_id     = local.infisical.project_id
  env_slug         = "prod"
  folder_path      = local.infisical.talos_path
  name             = "KUBECONFIG"
  value_wo         = ephemeral.talos_cluster_kubeconfig.admin.kubeconfig_raw
  value_wo_version = local.clients_version
}

# The same kubeconfig for core's Headlamp, which shows the lab beside core:
# written into core's project, where core's External Secrets read it (the
# homelab repository's decisions/0042). Core holding the lab's admin
# credentials is the safe way round - core is the more trusted cluster.
resource "infisical_secret" "headlamp_kubeconfig" {
  workspace_id     = "0f683ac6-7321-435c-935e-3e68f72f2d60" # homelab, core's project
  env_slug         = "prod"
  folder_path      = "/system/headlamp"
  name             = "LAB_KUBECONFIG"
  value_wo         = ephemeral.talos_cluster_kubeconfig.admin.kubeconfig_raw
  value_wo_version = local.clients_version
}

# This Mac's contexts, from Infisical: scripts/contexts.sh replaces the lab's
# context in each file and leaves every other cluster's alone. On another
# machine, `terraform apply -replace=terraform_data.contexts` adds them there.
resource "terraform_data" "contexts" {
  depends_on = [talos_cluster.this, infisical_secret.talosconfig, infisical_secret.kubeconfig]

  triggers_replace = [local.clients_version]
  input = {
    cluster = local.cluster.name
    project = local.infisical.project_id
    path    = local.infisical.talos_path
    script  = "${path.module}/scripts/contexts.sh"
  }

  provisioner "local-exec" {
    command = "${self.input.script} add ${self.input.cluster} ${self.input.project} ${self.input.path}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.input.script} remove ${self.input.cluster}"
  }
}
