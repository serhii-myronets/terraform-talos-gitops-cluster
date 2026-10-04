---
id: "0003"
title: Cilium and External Secrets are bootstrapped by Helmfile, outside Argo CD
date: 2026-10-03
status: accepted
tags: [helmfile, cilium, external-secrets, argocd, bootstrap]
---

# Cilium and External Secrets are bootstrapped by Helmfile, outside Argo CD

`02-bootstrap/helmfile.yaml` installs Cilium, External Secrets and Argo CD,
in that order, pinned to the kubeconfig context `admin@lab` so that nothing
reaches core whatever context is current. Argo CD then manages itself from
the same chart and values, but not the two below it. Core does the same
(homelab: decisions/0015).

The network and the secrets are what Argo CD itself stands on. Upgraded
through Git, a bad Cilium value with automatic sync would take the cluster's
network down and Argo CD's way of fixing it with it; External Secrets has to
run before any application asks for a secret. Their upgrades are a
`helmfile apply`, as on core - which is also the procedure the lab rehearses.

Rejected: Helmfile installing them once and Argo CD adopting the releases,
as many home clusters do. Upgrades through pull requests, at the price of
two tools owning one release and the network depending on its own GitOps.
