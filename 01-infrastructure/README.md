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
| [`.envrc`](./.envrc) | the Infisical CLI session's token, into the environment |

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
- `proxmox.auto.tfvars`, ignored by Git, with a token from the Proxmox host:

  ```bash
  pveum user token add root@pam terraform --privsep 0
  ```

  ```hcl
  proxmox_api_token = "root@pam!terraform=<secret>"
  ```
- An Infisical CLI session, `infisical login`, and direnv to hand it to Terraform (below).

## Infisical

Terraform reads and writes Infisical as the owner, with the token of the CLI's own session ([decisions/0009](../docs/decisions/0009-terraform-logs-in-to-infisical-as-the-owner.md)): `infisical login` opens it for ten days, and [`.envrc`](./.envrc) exports it whenever a shell enters this directory. When it has run out, `infisical login` again.

Once:

```bash
brew install direnv   # then add: eval "$(direnv hook zsh)"  to ~/.zshrc
direnv allow          # in this directory, again after each change to .envrc
```

Without direnv, the same by hand before a plan:

```bash
export INFISICAL_AUTH_METHOD=token INFISICAL_TOKEN=$(infisical user get token --plain)
```

## Run

```bash
terraform init
terraform plan -out=lab.plan
terraform apply lab.plan

# The lab's contexts, beside core's: the apply prints these as the output
# `connect`, and `terraform output -raw connect` prints them again.
talosctl config remove lab -y
f=$(mktemp) && terraform output -raw talosconfig > "$f" && talosctl config merge "$f"; rm -f "$f"
talosctl --context lab -n 192.168.8.40 kubeconfig --force
kubectl --context admin@lab get nodes
```

The Talos context is `lab` and the Kubernetes context `admin@lab`. A rebuilt cluster has new certificates, so its contexts replace the old ones: `config remove` first, since `config merge` would add the new one beside as `lab-1`, and `--force`, which overwrites `admin@lab` in `~/.kube/config` and leaves core's contexts alone. On a first build `config remove` finds nothing and says so. `talosctl config merge` makes `lab` the current Talos context, `talosctl config context <name>` switches back. Nodes stay `NotReady` until Cilium is installed in 02-bootstrap.

## Upgrades

- **Talos**: change `talos_version` in `locals.tf`. Each `talos_machine` cordons, drains, upgrades and uncordons its node. Apply with `-parallelism=1`, so one node reboots at a time and etcd keeps its quorum.
- **Kubernetes**: change `kubernetes_version`. `talos_cluster` runs Talos's `upgrade-k8s`, component by component.
- **`talos_contract`** stays at the version the cluster was created with; moving it regenerates every configuration against a newer schema, and is its own change.

## Navigation

[← Back to 00-prerequisite](../00-prerequisite/README.md) • [→ Continue to 02-bootstrap](../02-bootstrap/README.md)
