# 03-gitops

Everything Argo CD runs on the lab, laid out as core's `core/03-gitops/apps` is in the homelab repository. Argo CD follows the `homelab` branch.

## Layout

```text
03-gitops/
├── root.yaml                 the one root Application
├── apps/
│   ├── kustomization.yaml    which Applications run - one line each
│   ├── system/
│   │   ├── network/          gateway-system, cloudflared, external-dns
│   │   ├── security/         external-secrets, cert-manager
│   │   ├── storage/          openebs, minio
│   │   ├── platform/         argocd, metrics-server, postgresql, strimzi
│   │   └── observability/    grafana, loki, tempo, victoria-metrics-*, otel-operator, ...
│   └── services/             kafka, otel-demo
└── archive/                  retired components; nothing reads them
```

Each application is a folder: `application.yaml`, the Argo CD Application, and `app/`, its manifests and Helm values. A Helm chart's values sit in `app/` beside the manifests, and the Application's directory source excludes them.

## How it runs

02-bootstrap's postsync hook applies `root.yaml`. The root Application renders `apps/kustomization.yaml` and keeps every Application listed there, each syncing automatically from its own folder. All use the `default` project.

**An application runs only once it is listed.** The applications carried over from the earlier lab are being reviewed one at a time; the ones not yet reviewed stay in `apps/` with their line commented out. Listing one deploys it. Taking one off the list does not delete it: the root does not prune.

## Names and secrets

- **Routes**: Cilium's Gateway `main-gateway` at 192.168.8.31, one HTTPRoute per service.
- **Public names** under `serhii.link`: external-dns publishes each route's name to Cloudflare as a proxied CNAME to the lab's own tunnel `lab`, as owner `lab`; cloudflared carries it to the Gateway.
- **Local names** under `.home`: a second external-dns publishes them to BIND on the router, at the Gateway's address, as owner `lab` - see decisions/0039 in the homelab repository. Core publishes its own `.home` names there as owner `core`.
- **Secrets**: External Secrets reads the lab's own Infisical project, `proxmox-lab`, through the `ClusterSecretStore` `infisical-cloud`. Keys follow core's layout: `/system/<component>/UPPER_SNAKE`.

## Navigation

[← 02-bootstrap](../02-bootstrap/README.md) • [↑ Main project README](../README.md)
