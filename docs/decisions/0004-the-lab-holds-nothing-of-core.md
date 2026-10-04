---
id: "0004"
title: The lab holds no credential of core's
date: 2026-10-03
status: accepted
tags: [infisical, secrets, cloudflare, external-dns, security]
---

# The lab holds no credential of core's

The lab is the least trusted place in the house: rebuilt often, with an
anonymous admin in Argo CD. Until 2026-10-03 it read core's Infisical project
with the machine identity `homelab` - an organization admin, which by then
nothing else used; core itself read through `talos-cluster` - so anyone
with the lab could read core's backup keys, the router's backup key and
home-ca.

Now everything the lab holds is its own:

- Infisical project `proxmox-lab`, environment `prod`, keys laid out as
  core's are (`/system/<component>/UPPER_SNAKE`), read by the machine
  identity `lab`, which has no access to core's project or the organization.
  Its credential is `02-bootstrap/prepare-hook/initial-secret.yaml`, ignored
  by Git, with a copy in the project at `/system/infisical` for a rebuild
  from another machine, as core keeps its own.
- The Cloudflare tunnel `lab`, beside core's `beelink`, and its own DNS
  token.
- A TSIG key `lab` for the router's BIND, and external-dns owner `lab` in
  Cloudflare and in BIND, so neither cluster touches the other's records.

Rejected: a folder for the lab in core's project. Narrowing an identity to a
folder needs Infisical's custom roles, and a mistake there would hand the
lab core's secrets again.

On 2026-10-04 the identities were set to one per cluster with plain names:
`core` replaced `talos-cluster` - a member of core's project, whose client
secret had been printed into a working session - with no access to the
organization and Viewer on core's project; `homelab` was deleted. What logs
in to Infisical now is the owner, `core` and `lab`.
