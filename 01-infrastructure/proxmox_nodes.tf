# The Talos image, built by the Image Factory with the extensions in
# talos_configs.tf, as qcow2: an uncompressed image of content type import is
# imported through the API, so the provider needs no ssh to the host.
resource "proxmox_download_file" "talos" {
  node_name    = local.proxmox.node
  datastore_id = local.proxmox.images
  content_type = "import"
  file_name    = "talos-${local.talos_version}-${substr(talos_image_factory_schematic.this.id, 0, 8)}-nocloud-amd64.qcow2"
  url          = data.talos_image_factory_urls.this.urls.disk_image
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.nodes

  name      = each.key
  node_name = local.proxmox.node
  vm_id     = each.value.vm_id
  tags      = ["lab", "talos", each.value.role]
  on_boot   = true

  # The lab is disposable: destroy stops the VM rather than waiting on a
  # guest shutdown.
  stop_on_destroy = true
  agent {
    enabled = true
  }

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  # One host and no migration, so the guest sees the real CPU.
  cpu {
    cores = local.sizes[each.value.role].cpu
    type  = "host"
  }

  # Fixed, no ballooning: the host's memory is planned in locals.tf.
  memory {
    dedicated = local.sizes[each.value.role].memory
    floating  = 0
  }

  network_device {
    bridge = local.proxmox.bridge
  }

  disk {
    interface    = "scsi0"
    datastore_id = local.proxmox.datastore
    import_from  = proxmox_download_file.talos.id
    size         = local.sizes[each.value.role].disk
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26"
  }

  # The node's address, gateway and resolver reach Talos through the nocloud
  # datasource: the one place they are set.
  initialization {
    datastore_id = local.proxmox.datastore
    dns {
      servers = local.cluster.dns
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${local.cluster.prefix}"
        gateway = local.cluster.gateway
      }
    }
  }

  # The image is fixed at creation; upgrades go through talos_machine, not a
  # new disk.
  lifecycle {
    ignore_changes = [disk[0].import_from]
  }
}
