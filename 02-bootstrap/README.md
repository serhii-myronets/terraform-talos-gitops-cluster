# 02-bootstrap

Helmfile that brings the lab's cluster from `NotReady` to Argo CD: Cilium, then Argo CD, then the root Applications from which Argo CD syncs [03-gitops](../03-gitops/README.md). Everything after this stage is Argo CD's.

| Release | Chart | Version |
|---|---|---|
| `cilium` | `cilium/cilium` | 1.20.2 |
| `argocd` | `argo/argo-cd` | 10.9.6 (Argo CD v3.5) |

Every command is pinned to the kubeconfig context `admin@lab`, hooks included, so nothing here reaches core whatever context is current.

## What runs, in order

1. **prepare hook** - `kubectl apply -k prepare-hook/ --server-side`: the Gateway API CRDs (v1.6.2, which Cilium 1.20 requires), the CRDs that 03-gitops applications still expect to find, and `initial-secret.yaml`, the Infisical credential External Secrets reads. Helmfile runs it before every command, `diff` and `lint` included; it is idempotent.
2. **cilium** - CNI and kube-proxy replacement with BPF masquerading, Gateway API, L2 announcements, Hubble and Prometheus metrics. Its values follow core's; every container has a memory limit, so Talos's OOM controller never picks Cilium.
3. **argocd** - installs its own CRDs. Argo CD then manages itself from the same chart and values (`03-gitops/applications/00-core/argocd.yaml`, whose chart version moves with this one).
4. **postsync hook of argocd** - `kubectl apply -f ../03-gitops/applications/`: the four root Applications.

## Before the first run

`prepare-hook/initial-secret.yaml`, ignored by Git, made from [`initial-secret.yaml.example`](./prepare-hook/initial-secret.yaml.example) with the Infisical machine identity's client ID and secret.

## Run

```bash
helmfile apply
```

To preview without side effects - `helmfile diff` applies the prepare hook - call Helm directly:

```bash
helm diff upgrade cilium cilium/cilium --version 1.20.2 -n kube-system \
  -f values/cilium-values.yaml --kube-context admin@lab
```

## Check

```bash
kubectl --context admin@lab get nodes        # Ready once Cilium runs
cilium --context admin@lab status --wait
kubectl --context admin@lab -n argocd get deploy
kubectl --context admin@lab -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d   # the admin password
```

## Navigation

[← Back to 01-infrastructure](../01-infrastructure/README.md) • [→ Continue to 03-gitops](../03-gitops/README.md)
