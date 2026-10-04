resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = ["siderolabs/qemu-guest-agent"]
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version     = local.talos_version
  schematic_id      = talos_image_factory_schematic.this.id
  platform          = "nocloud"
  disk_image_format = "qcow2"
}

# The cluster's Talos secrets - its certificate authorities, the key
# ServiceAccount tokens are signed with, etcd's encryption key - from
# Infisical, in talosctl's secrets.yaml format. Generated once and kept there,
# so every rebuild is the same cluster: the same CAs, talosconfig and
# kubeconfig, and the same key Infisical checks the lab's External Secrets
# by (docs/decisions/0010).
data "infisical_secrets" "talos" {
  workspace_id = local.infisical.project_id
  env_slug     = "prod"
  folder_path  = local.infisical.talos_path
}

locals {
  talos_secrets = yamldecode(data.infisical_secrets.talos.secrets["SECRETS_YAML"].value)

  # secrets.yaml's names, as the Talos provider spells them.
  machine_secrets = {
    cluster = {
      id     = local.talos_secrets.cluster.id
      secret = local.talos_secrets.cluster.secret
    }
    secrets = {
      bootstrap_token             = local.talos_secrets.secrets.bootstraptoken
      secretbox_encryption_secret = local.talos_secrets.secrets.secretboxencryptionsecret
      aescbc_encryption_secret    = try(local.talos_secrets.secrets.aescbcencryptionsecret, null)
    }
    trustdinfo = {
      token = local.talos_secrets.trustdinfo.token
    }
    certs = {
      etcd               = { cert = local.talos_secrets.certs.etcd.crt, key = local.talos_secrets.certs.etcd.key }
      k8s                = { cert = local.talos_secrets.certs.k8s.crt, key = local.talos_secrets.certs.k8s.key }
      k8s_aggregator     = { cert = local.talos_secrets.certs.k8saggregator.crt, key = local.talos_secrets.certs.k8saggregator.key }
      k8s_serviceaccount = { key = local.talos_secrets.certs.k8sserviceaccount.key }
      os                 = { cert = local.talos_secrets.certs.os.crt, key = local.talos_secrets.certs.os.key }
    }
  }
}

# The admin's Talos client configuration, made from the secrets on each run
# and never stored: its certificate is valid as long as the OS CA, until
# 2036, and comes out the same every time.
ephemeral "talos_client_configuration" "this" {
  cluster_name    = local.cluster.name
  machine_secrets = local.machine_secrets
  endpoints       = [for node in local.controlplanes : node.ip]
  nodes           = [for node in local.nodes : node.ip]
}

# Until 2026-10-04 Terraform generated the secrets itself, and a rebuild made
# a new cluster. Forgotten, not destroyed: what it held is in Infisical now.
removed {
  from = talos_machine_secrets.this
  lifecycle {
    destroy = false
  }
}

# Each node's configuration: the patches for every node and for its role, then
# what is its own.
data "talos_machine_configuration" "node" {
  for_each = local.nodes

  cluster_name       = local.cluster.name
  cluster_endpoint   = local.cluster.endpoint
  machine_type       = each.value.role
  machine_secrets    = local.machine_secrets
  talos_version      = local.talos_contract
  kubernetes_version = local.kubernetes_version

  config_patches = concat(
    [
      file("${path.module}/patches/common.yaml"),
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "HostnameConfig"
        auto       = "off"
        hostname   = each.key
      }),
      # What `talosctl upgrade` and a reinstall default to; talos_machine
      # upgrades to the same image.
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "UnattendedInstallConfig"
        installer  = { image = data.talos_image_factory_urls.this.urls.installer }
        # The patch must name the disk again. scsi0, the system disk, is
        # always sda: the VMs have SCSI disks only.
        provisioning = { diskSelector = { match = "disk.dev_path == \"/dev/sda\"" } }
      }),
    ],
    # A role's own patch, where it has one.
    fileexists("${path.module}/patches/${each.value.role}.yaml") ? [file("${path.module}/patches/${each.value.role}.yaml")] : [],
    # Where Proxmox CSI may attach a volume to this node: the host it runs on.
    [yamlencode({
      apiVersion = "v1alpha1"
      kind       = "KubeNodeConfig"
      labels = {
        "topology.kubernetes.io/region" = local.proxmox.region
        "topology.kubernetes.io/zone"   = local.proxmox.node
      }
    })],
    each.value.role == "controlplane" ? [
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "Layer2VIPConfig"
        name       = local.cluster.vip
        link       = "lan" # the alias in patches/common.yaml
      }),
    ] : [],
  )
}

# Only to drain a node before an upgrade reboots it. Generated from the
# secrets, so it needs no running cluster and is never stored.
ephemeral "talos_cluster_kubeconfig" "drain" {
  cluster_name    = local.cluster.name
  endpoint        = local.cluster.endpoint
  machine_secrets = local.machine_secrets
}

# A node's configuration, and its Talos version: a changed installer image
# upgrades it in place, cordoned and drained first. Kubernetes versions belong
# to talos_cluster. Run an upgrade with -parallelism=1, so one node at a time
# reboots and etcd keeps its quorum.
resource "talos_machine" "controlplane" {
  for_each   = local.controlplanes
  depends_on = [proxmox_virtual_environment_vm.node]

  node                            = each.value.ip
  client_configuration_wo         = ephemeral.talos_client_configuration.this.client_configuration
  machine_configuration           = data.talos_machine_configuration.node[each.key].machine_configuration
  image                           = data.talos_image_factory_urls.this.urls.installer
  kubeconfig_wo                   = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
  ignore_kubernetes_upgrade_drift = true
}

# Bootstraps etcd on the first control plane and owns the Kubernetes version:
# a change runs Talos's upgrade-k8s, component by component.
resource "talos_cluster" "this" {
  depends_on = [talos_machine.controlplane]

  node                    = local.first_controlplane
  control_plane_nodes     = [for node in local.controlplanes : node.ip]
  client_configuration_wo = ephemeral.talos_client_configuration.this.client_configuration
  kubernetes_version      = local.kubernetes_version
}

resource "talos_machine" "worker" {
  for_each   = local.workers
  depends_on = [talos_cluster.this]

  node                            = each.value.ip
  client_configuration_wo         = ephemeral.talos_client_configuration.this.client_configuration
  machine_configuration           = data.talos_machine_configuration.node[each.key].machine_configuration
  image                           = data.talos_image_factory_urls.this.urls.installer
  kubeconfig_wo                   = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
  ignore_kubernetes_upgrade_drift = true
}

# The kubeconfig came from the running cluster until 2026-10-04; it is made
# from the secrets now (clients.tf).
removed {
  from = talos_cluster_kubeconfig.this
  lifecycle {
    destroy = false
  }
}
