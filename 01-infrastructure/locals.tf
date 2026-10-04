locals {
  proxmox = {
    endpoint = "https://192.168.8.30:8006/"
    node     = "proxmox"
    # The topology Proxmox CSI places volumes by: region names the Proxmox
    # "cluster" in its configuration, zone the host. Every node carries both.
    region    = "proxmox"
    bridge    = "vmbr0"
    datastore = "local-zfs" # VM disks: rpool/data, sync=disabled
    images    = "local"     # downloaded images, content type import
  }

  cluster = {
    name     = "lab"
    vip      = "192.168.8.50" # the Kubernetes API, held by one control plane at a time
    gateway  = "192.168.8.1"
    dns      = ["192.168.8.1"]
    prefix   = 24
    endpoint = "https://192.168.8.50:6443"
  }

  # Kept on core's versions, so the lab rehearses what core runs. talos_contract
  # is the configuration schema the machine configuration is generated against:
  # pinned to the version the cluster was created with, and moved on purpose,
  # never with an upgrade. Upgrades move talos_version and kubernetes_version.
  talos_version      = "v1.14.1"
  talos_contract     = "v1.14"
  kubernetes_version = "v1.37.0"

  # Control planes take 4 GB: Talos's recommended minimum, and roughly twice
  # what etcd, the API server and Cilium hold on a cluster this size. Their
  # components carry memory limits (patches/controlplane.yaml) so Talos's OOM
  # controller never picks them. The rest goes to the workers; with the ZFS ARC
  # (6.4 GB) about 7 GB of the host's 62 stays free.
  sizes = {
    controlplane = { cpu = 4, memory = 4096, disk = 20 }
    worker       = { cpu = 8, memory = 18432, disk = 40 }
  }

  nodes = {
    "controlplane-1" = { role = "controlplane", ip = "192.168.8.40", vm_id = 140 }
    "controlplane-2" = { role = "controlplane", ip = "192.168.8.41", vm_id = 141 }
    "controlplane-3" = { role = "controlplane", ip = "192.168.8.42", vm_id = 142 }
    "worker-1"       = { role = "worker", ip = "192.168.8.45", vm_id = 145 }
    "worker-2"       = { role = "worker", ip = "192.168.8.46", vm_id = 146 }
  }

  controlplanes = { for name, node in local.nodes : name => node if node.role == "controlplane" }
  workers       = { for name, node in local.nodes : name => node if node.role == "worker" }

  # The first control plane bootstraps etcd and answers before the VIP exists.
  first_controlplane = local.nodes["controlplane-1"].ip
}
