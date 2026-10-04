---
id: "0007"
title: Persistent volumes are disks of the Proxmox host, through Proxmox CSI
date: 2026-10-03
status: accepted
tags: [storage, proxmox, csi, zfs]
---

# Persistent volumes are disks of the Proxmox host, through Proxmox CSI

The lab is where the owner's own services run, so its storage should behave
as it does in a cloud: a volume that outlives the machine running it, and a
pod that can move between machines with its data.

Proxmox CSI does what EBS does in AWS. A PersistentVolumeClaim becomes a
zvol in the host's pool, `local-zfs`, named `vm-9999-pvc-<uuid>`, attached
as a SCSI disk to whichever worker runs the pod and moved to another when
the pod moves. The workers carry no data of their own and can be rebuilt; a
volume's disk belongs to no VM, so destroying one leaves it. Capacity is the
pool's, about 1.5 TB, not a fixed disk per worker; ZFS checksums and
compresses each volume. Verified on 2026-10-03: a claim's file written on
worker-1 read back on worker-2, and Terraform's plan stayed clean with the
disk attached.

Two classes: `proxmox-zfs`, the default, whose disk goes with its claim, and
`proxmox-zfs-retain`, whose disk stays to be bound again by hand. The
plugin talks to Proxmox as `kubernetes-csi@pve` through a token, with a role
`CSI` that may audit VMs, change their disks and allocate in datastores
only. Every node is labelled with its topology - region `proxmox`, zone the
host - by Talos.

A new cluster does not find old volumes by itself: its PersistentVolumes are
gone with its etcd. What survives a rebuild is backups, as in a cloud -
VolSync for files, a database's own backups for databases - and, failing
those, a PersistentVolume written by hand naming the old disk.

Rejected:
- **OpenEBS LocalPV hostpath**, what the lab had: a directory on a second
  disk of each worker, sizes not enforced, a pod pinned to its node and its
  data gone with the worker.
- **OpenEBS LVM LocalPV**, as core uses: cheap snapshots and sizes enforced,
  but still a disk per worker and a pod pinned to it.

What it costs: the plugin's snapshots are experimental, full copies and need
root@pam, so backups do not lean on them; orphaned disks of a destroyed
cluster stay in `local-zfs` until removed, `pvecsictl` lists them.
