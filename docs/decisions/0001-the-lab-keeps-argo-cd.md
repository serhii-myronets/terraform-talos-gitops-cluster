---
id: "0001"
title: The lab keeps its own Argo CD rather than copying core's Flux
date: 2026-10-03
status: accepted
tags: [argocd, flux, gitops, lab]
---

# The lab keeps its own Argo CD rather than copying core's Flux

The lab is the owner's production-like setup, for the owner's own services
and for learning. Copying core - Flux, core's tree - was weighed, since the
homelab repository once saw the lab as core's canary (its decisions/0034).
The owner kept Argo CD instead, so as not to lose the hands-on knowledge of
it that core, on Flux since its decisions/0020, no longer gives.

What the lab shares with core is most of what lies under the GitOps engine:
Talos and Kubernetes on core's versions, Cilium and External Secrets
bootstrapped by Helmfile with core's values, external-dns publishing the
same way, Infisical's layout. Where the lab differs, it is for being a
cluster of VMs rather than of bare metal - its storage above all
(decisions/0007).

Rejected: the lab as a second Flux tree pointed at core's manifests - at the
price of Argo CD, and of running the owner's own services in the lab's own
way rather than core's.
