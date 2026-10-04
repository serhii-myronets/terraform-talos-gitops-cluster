---
id: "0001"
title: The lab keeps its own Argo CD rather than copying core's Flux
date: 2026-10-03
status: accepted
tags: [argocd, flux, gitops, lab]
---

# The lab keeps its own Argo CD rather than copying core's Flux

The lab exists to rehearse what core will go through (homelab:
decisions/0034), which argued for making it a copy of core - Flux, core's
tree, core's upgrades. The owner kept Argo CD instead, so as not to lose the
hands-on knowledge of it that core, on Flux since its decisions/0020, no
longer gives.

What the lab shares with core is everything under the GitOps engine: Talos
and Kubernetes on core's versions, Cilium and External Secrets bootstrapped
by Helmfile with core's values, external-dns publishing the same way,
Infisical's layout, Renovate-style pinned versions. A Talos, Kubernetes or
Cilium upgrade is rehearsed here; a Flux upgrade is not.

Rejected: the lab as a second Flux tree pointed at core's manifests. It
would rehearse Flux too, at the price of Argo CD, and of the lab's
applications - observability, Kafka, the OpenTelemetry demo - which core
does not run.
