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
│   │   ├── storage/          proxmox-csi
│   │   ├── platform/         argocd, metrics-server
│   │   └── observability/    victoria-metrics
│   └── services/             none yet
```

Each application is a folder: `application.yaml`, the Argo CD Application, and `app/`, everything it deploys. `app/kustomization.yaml` lists the manifests and renders Helm charts with `helmCharts:` from the values beside it, so the Application has one source - the folder.

## How it runs

02-bootstrap's postsync hook applies `root.yaml`. The root Application renders `apps/kustomization.yaml` and keeps every Application listed there, each syncing automatically from its own folder. All use the `default` project.

**An application runs only once it is listed.** The applications carried over from the earlier lab are being reviewed one at a time; the ones not yet reviewed wait in [`archive/awaiting-review`](../archive/awaiting-review), outside what Argo CD reads, and move back into `apps/` once reviewed. Listing one deploys it. Taking one off the list does not delete it: the root does not prune.

## Names and secrets

- **Routes**: Cilium's Gateway `main-gateway` at 192.168.8.31, one HTTPRoute per service.
- **Public names** under `serhii.link`: external-dns publishes each route's name to Cloudflare as a proxied CNAME to the lab's own tunnel `lab`, as owner `lab`; cloudflared carries it to the Gateway.
- **Local names** under `.home`: a second external-dns publishes them to BIND on the router, at the Gateway's address, as owner `lab` - see decisions/0039 in the homelab repository. Core publishes its own `.home` names there as owner `core`.
- **Secrets**: External Secrets reads the lab's own Infisical project, `proxmox-lab`, through the `ClusterSecretStore` `infisical-cloud`. Keys follow core's layout: `/system/<component>/UPPER_SNAKE`.

## Navigation

[← 02-bootstrap](../02-bootstrap/README.md) • [↑ Main project README](../README.md)
