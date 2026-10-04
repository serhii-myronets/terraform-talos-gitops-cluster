
# Prerequisites for Running Talos Kubernetes Cluster on Proxmox

This document describes the prerequisites and initial environment setup required to deploy a Kubernetes cluster using Talos Linux, Terraform, and Proxmox VE.

---

## Minimum Hardware Requirements

A physical server, mini PC, or spare laptop with virtualization support is sufficient.

| Resource    | Minimum (testing) | Recommended (production-like) |
|-------------|-------------------|-------------------------------|
| CPU Cores   | 4                 | 8+                            |
| RAM         | 8 GB              | 16 GB+                        |

> For running the full GitOps stack (observability, demo apps, load generation), at least 12 GB RAM is recommended.

---

## Required Software

Install the following CLI tools on your **local workstation** (not inside Proxmox):

### Mandatory

- `terraform`: Infrastructure provisioning
- `kubectl`: Kubernetes control interface
- `helmfile`: Declarative Helm release management
- `helm`: Dependency of `helmfile`
- `talosctl`: Talos Linux management CLI

### Optional

- `cilium`: Cilium CLI for CNI diagnostics

#### Installation (macOS / Ubuntu)

**macOS (Homebrew):**
```bash
brew install terraform kubectl helmfile helm
brew install talosctl cilium
```

**Ubuntu/Debian (APT + manual binaries):**
```bash
sudo apt update && sudo apt install -y terraform kubectl helmfile helm
# talosctl and cilium must be downloaded manually
```

---

## Proxmox VE Installation

Proxmox must be installed directly on the host machine that will run the cluster.

1. Download the ISO from https://www.proxmox.com/en/downloads and check its SHA256 against the site.
2. Flash it to USB, e.g. with balenaEtcher.
3. Boot the machine and install Proxmox.

> Ensure virtualization support (VT-x / AMD-V) is enabled in BIOS/UEFI.

The choices made in the installer for this lab's single NVMe disk:

| Setting | Value | Why |
|---|---|---|
| Filesystem | `zfs (RAID0)` | ZFS on one disk; RAID0 of a single disk is a plain pool |
| `ashift`, `compress`, `checksum`, `copies` | `12`, `on`, `on`, `1` | the defaults |
| ARC max size | the default, about 10% of RAM | |
| `hdsize` | about 90% of the disk (`1675` of `1863` GB) | unpartitioned space left to the SSD |
| Network interface | the one with a link | pinned names (`nic0`, `nic1`, ...) are kept |
| Hostname | `proxmox.home` | |
| Address, gateway, DNS | `192.168.8.30/24`, `192.168.8.1`, `192.168.8.1` | a static address on the LAN, outside the router's DHCP pool |

The installer creates the `vmbr0` bridge on that interface; the VMs attach to it directly on the same LAN, so the workstation reaches them without a route. VM disks live in `local-zfs` (`rpool/data`).

---

## Post-Install Configuration

Run the community post-install script on the host, in an ssh session - it asks questions:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```

The answers: the enterprise and Ceph enterprise repositories disabled (or kept, if already disabled), `pve-no-subscription` added, `pvetest` not added, the subscription nag removed, high availability left off, update and reboot.

Then the two settings specific to this lab:

```bash
# The VMs are disposable: their fsyncs, etcd's above all, need not be
# written twice. The host system on rpool/ROOT keeps sync.
zfs set sync=disabled rpool/data
```

The `powersave` governor, as described in [`cpu-power/`](./cpu-power/README.md).

### ProxMenux

[ProxMenux](https://github.com/MacRimi/ProxMenux): a menu for the host's routine tasks (`menu` in a shell on it) and ProxMenux Monitor, a web dashboard for its hardware, disks, temperatures and guests. Its installer asks questions, so it runs in an ssh session on the host, as the post-install script does:

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/MacRimi/ProxMenux/main/install_proxmenux.sh)"
```

It installs `dialog`, `curl`, `jq` and `git` from Debian, its files under `/usr/local/share/proxmenux`, and the Monitor as the systemd service `proxmenux-monitor` on port 8008. It updates itself from its own menu; nothing here pins a version.

Then, in the Monitor at `http://192.168.8.30:8008`, turn on its login - and two-factor if wanted. Anything on the LAN reaches that port, and without a login the dashboard and its API answer anyone.

---

## Navigation

[← Back to Main project README](../README.md) • [→ Continue to 01-infrastructure](../01-infrastructure/README.md)
