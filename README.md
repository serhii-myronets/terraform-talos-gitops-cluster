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
- OpenEBS for worker-node storage
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
    ├── lab-controlplane-1..3: 192.168.8.40-42
    ├── lab-worker-1..2:       192.168.8.45-46
    └── Kubernetes API VIP:    192.168.8.50
```

Nodes, addresses, versions and VM sizes are set in [`01-infrastructure/locals.tf`](./01-infrastructure/locals.tf). Each worker has a second 100 GB disk for OpenEBS.

## Repository layout

| Path | Role |
| --- | --- |
| [`00-prerequisite/`](./00-prerequisite/README.md) | Workstation, Proxmox and network preparation |
| [`01-infrastructure/`](./01-infrastructure/README.md) | Terraform resources, Talos image/config generation and machine patches |
| [`02-bootstrap/`](./02-bootstrap/README.md) | Helmfile bootstrap for Cilium and Argo CD |
| [`03-gitops/`](./03-gitops/README.md) | Argo CD Applications, Helm values and Kubernetes resources |
| [`assets/`](./assets/) | Documentation screenshots |

Inside `03-gitops`, applications are organized into four tiers:

```text
00-core          Argo CD, cert-manager, Gateway API, secrets, storage, MinIO, metrics-server
01-platform      PostgreSQL and Strimzi operator
02-services      Kafka and OpenTelemetry Demo
03-observability Grafana, Loki, Tempo, VictoriaMetrics, OpenTelemetry and exporters
```

`03-gitops/components/99-archive/` contains retired or experimental components and is not part of the active Argo CD tree.

## Deployment flow

Follow the stage-specific README files in order:

1. [Prepare the workstation and Proxmox host](./00-prerequisite/README.md).
2. [Provision Talos VMs with Terraform](./01-infrastructure/README.md).
3. [Bootstrap Cilium and Argo CD](./02-bootstrap/README.md) with Helmfile.
4. [Apply the GitOps application tiers](./03-gitops/README.md) through Argo CD.

```bash
# Run from 01-infrastructure
terraform init
terraform apply
# Merged beside existing contexts - see 01-infrastructure/README.md
f=$(mktemp) && terraform output -raw talosconfig > "$f" && talosctl config merge "$f"; rm -f "$f"
talosctl --context lab -n 192.168.8.40 kubeconfig

# Then bootstrap
cd ../02-bootstrap
helmfile apply

# Finally apply the Argo CD application roots
kubectl apply -f ../03-gitops/applications/00-core-root.yaml
kubectl apply -f ../03-gitops/applications/01-platform-root.yaml
kubectl apply -f ../03-gitops/applications/02-services-root.yaml
kubectl apply -f ../03-gitops/applications/03-observability.yaml
```

Do not commit real Proxmox credentials or bootstrap secrets. Use the example secret template and the configured Infisical integration for runtime secrets.

## Access and verification

Internal services are exposed through Cilium Gateway API resources. Active routes live alongside component configuration under `03-gitops/components/`. External access is provided by Cloudflare Tunnel; DNS and tunnel credentials are environment-specific.

```bash
kubectl get nodes
cilium status --wait
kubectl get applications -A
```

## Screenshots

| Proxmox | Argo CD |
|:---:|:---:|
| <img src="./assets/proxmox.png" width="400"/> | <img src="./assets/argocd.png" width="400"/> |

| Grafana | Tempo |
|:---:|:---:|
| <img src="./assets/grafana.png" width="400"/> | <img src="./assets/tempo.png" width="400"/> |
