# Talos Kubernetes homelab on Proxmox

Infrastructure and GitOps configuration for a Talos Linux Kubernetes cluster running on Proxmox VE.

The repository is split into three deployment stages:

```text
00-prerequisite  →  01-infrastructure  →  02-bootstrap  →  03-gitops
  host setup          Terraform/Talos       Cilium + Argo CD     workloads
```

## What is deployed

- Talos Linux VMs provisioned on Proxmox with Terraform, Talos upgrades and Kubernetes upgrades included
- 3 control-plane nodes and 2 workers
- Cilium as the CNI, with kube-proxy replacement, eBPF, Hubble and Gateway API
- Argo CD managing the rest of the cluster from the `homelab` branch
- Proxmox CSI: persistent volumes as disks of the host's ZFS pool, attached to whichever worker runs the pod
- External Secrets Operator backed by Infisical
- Cilium Gateway API (`Gateway`/`HTTPRoute`) for service exposure
- PostgreSQL and Strimzi-managed Kafka
- Observability with OpenTelemetry, VictoriaMetrics, Loki, Fluent Bit, Tempo and Grafana
- OpenTelemetry Demo as an example instrumented workload
- Cloudflare Tunnel for external access

This is a homelab/learning environment. Resource sizes, credentials, network addresses and enabled workloads are repository-specific and should be reviewed before reuse.

## Architecture

One Proxmox host on the home LAN, `192.168.8.0/24`:

```text
Proxmox VE (192.168.8.30)
└── vmbr0
    ├── controlplane-1..3: 192.168.8.40-42
    ├── worker-1..2:       192.168.8.45-46
    └── Kubernetes API VIP:    192.168.8.50
```

Nodes, addresses, versions and VM sizes are set in [`01-infrastructure/locals.tf`](./01-infrastructure/locals.tf). Workers have no data disks of their own: persistent volumes come from the host's ZFS pool through Proxmox CSI.

## Repository layout

| Path | Role |
| --- | --- |
| [`00-prerequisite/`](./00-prerequisite/README.md) | Workstation, Proxmox and network preparation |
| [`01-infrastructure/`](./01-infrastructure/README.md) | Terraform resources, Talos image/config generation and machine patches |
| [`02-bootstrap/`](./02-bootstrap/README.md) | Helmfile bootstrap for Cilium and Argo CD |
| [`03-gitops/`](./03-gitops/README.md) | Argo CD Applications, Helm values and Kubernetes resources |
| [`docs/`](./docs/README.md) | the lab's record: the cluster as it runs, decisions, the last session |
| [`archive/`](./archive/README.md) | what the lab ran once, kept whole; nothing reads it |

Inside `03-gitops`, applications are laid out as core's are in the homelab repository: `apps/system/<category>/<name>` and `apps/services/<name>`, each an `application.yaml` beside its `app/` folder. `apps/kustomization.yaml` lists the ones that run.

## Deployment flow

Follow the stage-specific README files in order:

1. [Prepare the workstation and Proxmox host](./00-prerequisite/README.md).
2. [Provision Talos VMs with Terraform](./01-infrastructure/README.md).
3. [Bootstrap Cilium and Argo CD](./02-bootstrap/README.md) with Helmfile.
4. [Let Argo CD run 03-gitops](./03-gitops/README.md) - the bootstrap applies its root Application.

```bash
# Run from 01-infrastructure
terraform init
terraform plan -out=lab.plan && terraform apply lab.plan
# The context lab is now in ~/.talos/config and in ~/.kube/config

# Then bootstrap: Cilium, External Secrets, Argo CD, and the root Application
cd ../02-bootstrap
helmfile apply
```

Do not commit real Proxmox credentials or bootstrap secrets. Use the example secret template and the configured Infisical integration for runtime secrets.

## Access and verification

Internal services are exposed through Cilium Gateway API resources. Each route lives in its application's `app/` folder under `03-gitops/apps/`. External access is provided by Cloudflare Tunnel; DNS and tunnel credentials are environment-specific.

```bash
kubectl get nodes
cilium status --wait
kubectl get applications -A
```
