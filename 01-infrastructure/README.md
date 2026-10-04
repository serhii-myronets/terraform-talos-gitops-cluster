# 01-infrastructure

Terraform that builds the lab's Talos cluster on the Proxmox host: the VMs, each node's Talos configuration, etcd's bootstrap and the client configurations. Cilium and Argo CD follow in [02-bootstrap](../02-bootstrap/README.md).

## Layout

| File | |
|---|---|
| [`locals.tf`](./locals.tf) | everything that is set: Proxmox, the network, versions, VM sizes, the nodes |
| [`proxmox_nodes.tf`](./proxmox_nodes.tf) | the Talos image and the VMs |
| [`talos_configs.tf`](./talos_configs.tf) | the image schematic, the Talos secrets from Infisical, machine configurations, `talos_machine` and `talos_cluster` |
| [`clients.tf`](./clients.tf) | talosconfig and kubeconfig: into Infisical, the kubeconfig also into core's project for its Headlamp, and the contexts on this Mac |
| [`scripts/contexts.sh`](./scripts/contexts.sh) | adds or removes one cluster's contexts in `~/.talos/config` and `~/.kube/config` |
| [`patches/`](./patches/) | Talos configuration documents for every node and for each role |
| [`providers.tf`](./providers.tf) | providers, the Proxmox token from Infisical, and the state in R2 |

## The cluster

| | Address | vCPU | RAM | Disks |
|---|---|---|---|---|
| Kubernetes API (VIP) | 192.168.8.50 | | | |
| `controlplane-1..3` | .40-.42 | 4 | 4 GB | 20 GB |
| `worker-1..2` | .45-.46 | 8 | 18 GB | 40 GB |

Talos v1.14.1 and Kubernetes v1.37.0, the versions core runs. The VMs' disks are on `local-zfs`, imported from the Image Factory's qcow2 image with the `qemu-guest-agent` extension. Each node's address, gateway and resolver come from Proxmox's cloud-init drive.

The patches use the v1.14 configuration contract, where each part of the configuration is a document of its own: Flannel is removed and kube-proxy disabled for Cilium, the network card is aliased `lan` for the VIP and the control-plane components carry memory limits. Every node is labelled with its Proxmox topology - region `proxmox`, zone the host - which Proxmox CSI places volumes by.

## Before the first run

- The `r2` profile in `~/.aws/credentials`, as core uses: see `core/01-talos/README.md` in the homelab repository.
- A token for the Proxmox API in Infisical, `proxmox-lab` `/system/proxmox/API_TOKEN`, as `root@pam!terraform=<secret>` ([decisions/0012](../docs/decisions/0012-the-proxmox-token-is-in-infisical.md)) - made on the host with:

  ```bash
  pveum user token add root@pam terraform --privsep 0
  ```
- An Infisical CLI session, `infisical login`, and the `terraform` function that hands it to Terraform (below).

## Infisical

Terraform reads and writes Infisical as the owner, with the token of the CLI's own session ([decisions/0009](../docs/decisions/0009-terraform-logs-in-to-infisical-as-the-owner.md)). The provider cannot read that session itself - the CLI keeps it in the macOS Keychain - so a function in `~/.zshrc` hands it to every run:

```zsh
terraform() { INFISICAL_AUTH_METHOD=token INFISICAL_TOKEN=$(infisical user get token --plain 2>/dev/null) command terraform "$@"; }
```

The token is read fresh on each run and given to that one process only; oh-my-zsh's `tf` aliases go through the function too. `infisical login` opens a session for ten days; when it has run out, the provider fails to log in until the next `infisical login`.

## Run

```bash
terraform init
terraform plan -out=lab.plan
terraform apply lab.plan

kubectl --context admin@lab get nodes
```

Nodes stay `NotReady` until Cilium is installed in 02-bootstrap.

## Secrets and contexts

The cluster is made from **Talos secrets kept in Infisical**, `proxmox-lab` `/system/talos/SECRETS_YAML` in talosctl's `secrets.yaml` format ([decisions/0010](../docs/decisions/0010-the-lab-is-made-from-secrets-in-infisical.md)). They were placed there once; Terraform only reads them, so a destroy and an apply bring back the same cluster - the same certificate authorities, the same key ServiceAccount tokens are signed with.

From them, on every run and never stored in the state, Terraform makes the admin's talosconfig and kubeconfig, valid as long as their CAs. After an apply it writes them beside the secrets, as `TALOSCONFIG` and `KUBECONFIG`, and merges them into this Mac's `~/.talos/config` and `~/.kube/config` as the contexts `lab` and `admin@lab`, replacing the lab's and leaving core's and which context is current alone. A destroy takes them out of both places.

On another machine, after `infisical login`:

```bash
terraform plan -replace=terraform_data.contexts -out=contexts.plan
terraform apply contexts.plan
```

or, without Terraform, `scripts/contexts.sh add lab 31407031-ddd9-4d01-aaa4-b9a791c73504 /system/talos`.

## Upgrades

- **Talos**: change `talos_version` in `locals.tf`. Each `talos_machine` cordons, drains, upgrades and uncordons its node. Apply with `-parallelism=1`, so one node reboots at a time and etcd keeps its quorum.
- **Kubernetes**: change `kubernetes_version`. `talos_cluster` runs Talos's `upgrade-k8s`, component by component.
- **`talos_contract`** stays at the version the cluster was created with; moving it regenerates every configuration against a newer schema, and is its own change.

## Navigation

[← Back to 00-prerequisite](../00-prerequisite/README.md) • [→ Continue to 02-bootstrap](../02-bootstrap/README.md)
