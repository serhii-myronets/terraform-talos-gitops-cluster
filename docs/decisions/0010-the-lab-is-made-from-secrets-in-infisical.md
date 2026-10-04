---
id: "0010"
title: The lab is made from Talos secrets kept in Infisical, and writes its client configurations back
date: 2026-10-04
status: accepted
tags: [talos, terraform, infisical, secrets, kubeconfig, talosconfig]
---

# The lab is made from Talos secrets kept in Infisical, and writes its client configurations back

Until 2026-10-04 Terraform generated the lab's Talos secrets itself, with
`talos_machine_secrets`, so every destroy and apply made a new cluster: new
certificate authorities, a new talosconfig and kubeconfig to fetch and merge
by hand, and a new key for ServiceAccount tokens - which would have made the
lab's External Secrets log in by JWT only until the next rebuild, since
Infisical checks those tokens against a key it is given once.

Now the secrets are in Infisical, `proxmox-lab` `/system/talos/SECRETS_YAML`,
in talosctl's `secrets.yaml` format - core's layout (the homelab
repository's decisions/0037). They were the running cluster's, moved there
without a rebuild: `talos_machine_secrets` was dropped from the state
unharmed, and the plan changed no node's configuration. Terraform reads them
on every run, so a rebuild is the same cluster.

From them the Talos provider's ephemeral resources make the admin's
talosconfig and kubeconfig on each run, valid as long as their CAs (2036)
and the same every time, so they are never kept in Terraform's state; nodes
and `talos_cluster` take the client configuration write-only. Terraform
writes both beside the secrets, as `TALOSCONFIG` and `KUBECONFIG`, and
`scripts/contexts.sh` merges them into the Mac's `~/.talos/config` and
`~/.kube/config`, replacing the context `lab` in each and leaving
every other; a destroy removes them again. They are written again only when
the secrets change.

What is accepted: the identity `lab`, which the lab's External Secrets log
in as, reads the whole project, so the lab's cluster can read its own Talos
secrets - full control of itself. Its Argo CD already gives that to anyone
on the LAN; core accepted the same (0037).

Rejected:
- **Keeping `talos_machine_secrets`**, a new cluster at every rebuild: the
  contexts to replace by hand each time, and no login for External Secrets
  that outlives one cluster.
- **The configurations from the running cluster** (`talos_cluster_kubeconfig`,
  `talosctl kubeconfig`): they need the cluster up, and certificates that
  expire within a year.
- **Terraform writing ~/.talos/config and ~/.kube/config whole**
  (`local_file`): both hold core's contexts too.
