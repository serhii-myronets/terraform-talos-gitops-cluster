---
date: 2026-10-03
title: The lab rebuilt on the LAN, and its applications under review
tags: [proxmox, talos, terraform, helmfile, argocd, infisical, cloudflare, external-dns]
---

# The lab rebuilt on the LAN, and its applications under review

One day. What follows is the story; the facts are in ../cluster.yaml and the
choices in ../decisions/. The same day's work on the house - .home served by
BIND on the router - is in the homelab repository's session note.

## From the host up

Proxmox was reinstalled on the flat LAN at 192.168.8.30, ZFS on the single
disk; the community post-install script set the repositories, the rest is in
00-prerequisite. The lab's main had been tagged v0.1.0 before; it got a
GitHub release as the state from before all of this.

01-infrastructure was rewritten: providers bpg/proxmox 0.115 and Talos 0.12,
the image as qcow2 imported through the API with a token instead of the root
password, settings in locals.tf, state in R2. Talos 1.14's contract refused
the old patches beside its new documents, so they were rewritten as
documents. The first build named the nodes lab-*, which the owner did not
want; renaming means rebuilding, so it was destroyed and built again as
controlplane-1..3 and worker-1..2. A kubeconfig written with `>` replaced the
owner's core context once; both READMEs now merge contexts instead.

02-bootstrap gained a pinned context - without it helmfile would have
installed onto core - Cilium 1.20 with core's values, Gateway API CRDs v1.6,
External Secrets moved in from Argo CD, and Argo CD 3.5 installing its own
CRDs. A `helmfile lint` ran the prepare hook against the lab unasked; its
leftover CRDs had to be deleted before External Secrets would install.

## Secrets, names, the tunnel

The lab had been reading core's Infisical project with core's organization
admin identity; it has its own project and identity now (decisions/0004),
keys laid out as core's. It got its own tunnel and external-dns as owner
`lab`, and a second external-dns for .home once the router had BIND. Making
AdGuard writable for it was tried and undone - the homelab note tells it.

## 03-gitops

Every application came over from the old lab and is reviewed before it runs
again. The four tier roots were replaced by one root and a list
(decisions/0005), and the tree laid out as core's. Four applications run:
gateway-system, cloudflared, external-dns and external-secrets. Whether to
move to an ApplicationSet was weighed: worth it for one template instead of
22 Applications, but the list suits a review better; Helm values are to move
into each app's kustomization.yaml as it is reviewed, which makes either easy.

external-dns was the first moved: both its charts render from helmCharts in
its kustomization.yaml, the same objects as before.

Still open:
- cert-manager next, and with it a .home listener on the Gateway - until then
  the lab publishes no .home name.
- The rest of the review, in apps/kustomization.yaml order.
- An ApplicationSet once every application is reviewed.
