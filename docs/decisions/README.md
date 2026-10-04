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
| [0003](0003-cilium-and-external-secrets-before-argo-cd.md) | Cilium, External Secrets and Argo CD itself are kept by Helmfile, outside Argo CD | accepted | helmfile, cilium, external-secrets |
| [0004](0004-the-lab-holds-nothing-of-core.md) | The lab holds no credential of core's | accepted | infisical, secrets, cloudflare |
| [0005](0005-applications-run-once-listed.md) | 03-gitops is laid out as core's, and an application runs once it is listed | accepted | argocd, gitops, layout |
| [0006](0006-lab-ca-under-home-ca.md) | The lab's .home certificates come from lab-ca, an intermediate under home-ca limited to .home | accepted | tls, cert-manager, home-ca |
| [0007](0007-volumes-are-proxmox-disks.md) | Persistent volumes are disks of the Proxmox host, through Proxmox CSI | accepted | storage, proxmox, csi, zfs |
| [0008](0008-observability-writes-to-core.md) | The lab collects its metrics and logs, and core stores them | accepted | observability, victoriametrics, core |
| [0009](0009-terraform-logs-in-to-infisical-as-the-owner.md) | Terraform logs in to Infisical as the owner, with the CLI's session token | accepted | terraform, infisical, identity |
| [0010](0010-the-lab-is-made-from-secrets-in-infisical.md) | The lab is made from Talos secrets kept in Infisical, and writes its client configurations back | accepted | talos, terraform, infisical, secrets |
| [0011](0011-external-secrets-logs-in-with-the-clusters-own-token.md) | External Secrets logs in to Infisical with the cluster's own ServiceAccount token | accepted | external-secrets, infisical, jwt |
