# 01-infrastructure

Terraform that builds the lab's Talos cluster on the Proxmox host: the VMs, each node's Talos configuration, etcd's bootstrap and the client configurations. Cilium and Argo CD follow in [02-bootstrap](../02-bootstrap/README.md).

## Layout

| File | |
|---|---|
| [`locals.tf`](./locals.tf) | everything that is set: Proxmox, the network, versions, VM sizes, the nodes |
| [`proxmox_nodes.tf`](./proxmox_nodes.tf) | the Talos image and the VMs |
| [`talos_configs.tf`](./talos_configs.tf) | the image schematic, machine configurations, `talos_machine` and `talos_cluster` |
| [`patches/`](./patches/) | Talos configuration documents for every node and for each role |
| [`providers.tf`](./providers.tf) | providers, and the state in R2 |
| [`variables.tf`](./variables.tf) | the Proxmox API token, the one input not in Git |

## The cluster

| | Address | vCPU | RAM | Disks |
|---|---|---|---|---|
| Kubernetes API (VIP) | 192.168.8.50 | | | |
| `lab-controlplane-1..3` | .40-.42 | 4 | 4 GB | 20 GB |
| `lab-worker-1..2` | .45-.46 | 8 | 18 GB | 40 GB + 100 GB at `/var/mnt/storage` |

Talos v1.14.1 and Kubernetes v1.37.0, the versions core runs. The VMs' disks are on `local-zfs`, imported from the Image Factory's qcow2 image with the `qemu-guest-agent` extension. Each node's address, gateway and resolver come from Proxmox's cloud-init drive.

The patches use the v1.14 configuration contract, where each part of the configuration is a document of its own: Flannel is removed and kube-proxy disabled for Cilium, the network card is aliased `lan` for the VIP, the control-plane components carry memory limits, and each worker's second disk is the user volume `storage`.

## Before the first run

- The `r2` profile in `~/.aws/credentials`, as core uses: see `core/01-talos/README.md` in the homelab repository.
- `proxmox.auto.tfvars`, ignored by Git, with a token from the Proxmox host:

  ```bash
  pveum user token add root@pam terraform --privsep 0
  ```

  ```hcl
  proxmox_api_token = "root@pam!terraform=<secret>"
  ```

## Run

```bash
terraform init
terraform plan -out=lab.plan
terraform apply lab.plan

# Add the lab beside core's contexts rather than over them: merge the Talos
# configuration, then let talosctl merge the kubeconfig.
f=$(mktemp) && terraform output -raw talosconfig > "$f" && talosctl config merge "$f"; rm -f "$f"
talosctl --context lab -n 192.168.8.40 kubeconfig
```

The Talos context is `lab` and the Kubernetes context `admin@lab`; `talosctl config merge` makes `lab` the current Talos context, `talosctl config context <name>` switches back. Nodes stay `NotReady` until Cilium is installed in 02-bootstrap.

## Upgrades

- **Talos**: change `talos_version` in `locals.tf`. Each `talos_machine` cordons, drains, upgrades and uncordons its node. Apply with `-parallelism=1`, so one node reboots at a time and etcd keeps its quorum.
- **Kubernetes**: change `kubernetes_version`. `talos_cluster` runs Talos's `upgrade-k8s`, component by component.
- **`talos_contract`** stays at the version the cluster was created with; moving it regenerates every configuration against a newer schema, and is its own change.

## Navigation

[← Back to 00-prerequisite](../00-prerequisite/README.md) • [→ Continue to 02-bootstrap](../02-bootstrap/README.md)
