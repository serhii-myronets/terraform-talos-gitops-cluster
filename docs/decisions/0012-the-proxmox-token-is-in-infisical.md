---
id: "0012"
title: Terraform's Proxmox token is in the lab's Infisical project, not in a file on the Mac
date: 2026-10-04
status: accepted
tags: [proxmox, terraform, infisical, secrets]
---

# Terraform's Proxmox token is in the lab's Infisical project, not in a file on the Mac

Terraform talks to the Proxmox API with the token `root@pam!terraform`,
without privilege separation: root on the hypervisor. It lived in
`01-infrastructure/proxmox.auto.tfvars`, ignored by Git, in plain text on
the Mac. Once Terraform logged in to Infisical anyway (0009), it moved to
`proxmox-lab` `/system/proxmox/API_TOKEN`; an ephemeral `infisical_secret`
hands it to the Proxmox provider on each run, and it is never kept in the
state. Verified on 2026-10-04: the plan read every VM and found no changes.

What is accepted, at the owner's choice: the identity `lab` reads the whole
project, so the lab's cluster can read root's token for the host it runs
on - from a pod that reached External Secrets, or anyone using its anonymous
Argo CD, to root on the hypervisor and a machine on the LAN. The host serves
only the lab, which the owner weighed as reason enough to keep the token
with it.

Rejected:
- **A separate project no machine identity reads** (`operator`): the token
  out of the cluster's reach, for one more project to keep; the owner chose
  the lab's project.
- **The file**: a secret in plain text on disk, copied by hand to any other
  machine that applies.
