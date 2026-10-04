---
id: "0003"
title: Cilium, External Secrets and Argo CD itself are kept by Helmfile, outside Argo CD
date: 2026-10-03
status: accepted
tags: [helmfile, cilium, external-secrets, argocd, bootstrap]
---

# Cilium, External Secrets and Argo CD itself are kept by Helmfile, outside Argo CD

`02-bootstrap/helmfile.yaml` installs Cilium, External Secrets and Argo CD,
in that order, pinned to the kubeconfig context `admin@lab` so that nothing
reaches core whatever context is current, and keeps all three: their
upgrades are a `helmfile apply`. Core does the same, its Flux Operator
included (homelab: decisions/0015, 0021).

Argo CD does not manage itself either. Each release has one owner, its
version is in one place, and a bad value cannot break the tool that would
have to undo it. `03-gitops/apps/system/platform/argocd` holds only what sits
on top of it - its route.

The network and the secrets are what Argo CD itself stands on. Upgraded
through Git, a bad Cilium value with automatic sync would take the cluster's
network down and Argo CD's way of fixing it with it; External Secrets has to
run before any application asks for a secret. Their upgrades are a
`helmfile apply`, as on core.

Rejected: Helmfile installing them once and Argo CD adopting the releases -
itself included - as many home clusters do, and as the lab did before.
Upgrades through pull requests, at the price of two tools owning one release
and the network depending on its own GitOps.
