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

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in local.controlplanes : node.ip]
  nodes                = [for node in local.nodes : node.ip]
}

# Each node's configuration: the patches for every node and for its role, then
# what is its own.
data "talos_machine_configuration" "node" {
  for_each = local.nodes

  cluster_name       = local.cluster.name
  cluster_endpoint   = local.cluster.endpoint
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = local.talos_contract
  kubernetes_version = local.kubernetes_version

  config_patches = concat(
    [
      file("${path.module}/patches/common.yaml"),
      file("${path.module}/patches/${each.value.role}.yaml"),
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
  machine_secrets = talos_machine_secrets.this.machine_secrets
}

# A node's configuration, and its Talos version: a changed installer image
# upgrades it in place, cordoned and drained first. Kubernetes versions belong
# to talos_cluster. Run an upgrade with -parallelism=1, so one node at a time
# reboots and etcd keeps its quorum.
resource "talos_machine" "controlplane" {
  for_each   = local.controlplanes
  depends_on = [proxmox_virtual_environment_vm.node]

  node                            = each.value.ip
  client_configuration            = talos_machine_secrets.this.client_configuration
  machine_configuration           = data.talos_machine_configuration.node[each.key].machine_configuration
  image                           = data.talos_image_factory_urls.this.urls.installer
  kubeconfig_wo                   = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
  ignore_kubernetes_upgrade_drift = true
}

# Bootstraps etcd on the first control plane and owns the Kubernetes version:
# a change runs Talos's upgrade-k8s, component by component.
resource "talos_cluster" "this" {
  depends_on = [talos_machine.controlplane]

  node                 = local.first_controlplane
  control_plane_nodes  = [for node in local.controlplanes : node.ip]
  client_configuration = talos_machine_secrets.this.client_configuration
  kubernetes_version   = local.kubernetes_version
}

resource "talos_machine" "worker" {
  for_each   = local.workers
  depends_on = [talos_cluster.this]

  node                            = each.value.ip
  client_configuration            = talos_machine_secrets.this.client_configuration
  machine_configuration           = data.talos_machine_configuration.node[each.key].machine_configuration
  image                           = data.talos_image_factory_urls.this.urls.installer
  kubeconfig_wo                   = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
  ignore_kubernetes_upgrade_drift = true
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_cluster.this]

  node                 = local.first_controlplane
  client_configuration = talos_machine_secrets.this.client_configuration
}
