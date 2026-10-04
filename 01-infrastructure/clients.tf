# The admin's client configurations: made from the Talos secrets, written to
# Infisical beside them, and merged into this Mac's ~/.talos/config and
# ~/.kube/config - both contexts named lab - with nothing to copy by hand.
# A destroy takes them out of both places again.

# The admin kubeconfig, made from the secrets like the talosconfig: valid as
# long as the Kubernetes CA, the same on every run.
ephemeral "talos_cluster_kubeconfig" "admin" {
  cluster_name    = local.cluster.name
  endpoint        = local.cluster.endpoint
  machine_secrets = local.machine_secrets
}

data "infisical_secret_metadata" "talos_secrets" {
  project_id       = local.infisical.project_id
  environment_slug = "prod"
  folder_path      = local.infisical.talos_path
  name             = "SECRETS_YAML"
}

locals {
  # Talos names the kubeconfig's context and user admin@lab; here both are
  # named for the cluster, lab, as the Talos context is - in ~/.kube/config
  # and in core's Headlamp alike.
  kubeconfig_talos = yamldecode(ephemeral.talos_cluster_kubeconfig.admin.kubeconfig_raw)
  kubeconfig = yamlencode(merge(local.kubeconfig_talos, {
    contexts = [{
      name    = local.cluster.name
      context = { cluster = local.cluster.name, user = local.cluster.name, namespace = "default" }
    }]
    users             = [for user in local.kubeconfig_talos.users : merge(user, { name = local.cluster.name })]
    "current-context" = local.cluster.name
  }))

  # Both configurations follow from the secrets alone, so they need writing
  # again only when the secrets change - or how they are written, which
  # clients_format counts. A write-only value cannot be compared with what
  # Infisical holds, so a version tells Terraform to write them again, and
  # the provider takes only a version higher than the last: the secrets'
  # own version in Infisical, which only grows, times 100, plus the format.
  # Bump clients_format when this file changes what it writes.
  clients_format  = 2 # 2: contexts named for the cluster
  clients_version = data.infisical_secret_metadata.talos_secrets.secret_version * 100 + local.clients_format
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
  value_wo         = local.kubeconfig
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
  value_wo         = local.kubeconfig
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
