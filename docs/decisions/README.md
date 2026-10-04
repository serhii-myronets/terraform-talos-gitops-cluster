---
title: Decision records
tags: [index, decisions]
---

# Decisions

One file per decision still in force, or still open. Front matter carries
`status`, `date` and `tags`. Decisions about the house as a whole - the
host, the network, the router, `.home` - are in the homelab repository's
docs/decisions/; these are the lab's own.

| | Decision | Status | Tags |
|---|---|---|---|
| [0001](0001-the-lab-keeps-argo-cd.md) | The lab keeps its own Argo CD rather than copying core's Flux | accepted | argocd, flux, gitops |
| [0002](0002-talos-machines-own-their-upgrades.md) | Terraform owns the Talos and Kubernetes upgrades, through talos_machine and talos_cluster | accepted | talos, terraform, upgrades |
| [0003](0003-cilium-and-external-secrets-before-argo-cd.md) | Cilium and External Secrets are bootstrapped by Helmfile, outside Argo CD | accepted | helmfile, cilium, external-secrets |
| [0004](0004-the-lab-holds-nothing-of-core.md) | The lab holds no credential of core's | accepted | infisical, secrets, cloudflare |
| [0005](0005-applications-run-once-listed.md) | 03-gitops is laid out as core's, and an application runs once it is listed | accepted | argocd, gitops, layout |
