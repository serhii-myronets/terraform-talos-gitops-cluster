---
id: "0009"
title: Terraform logs in to Infisical as the owner, with the CLI's session token
date: 2026-10-04
status: accepted
tags: [terraform, infisical, secrets, identity]
---

# Terraform logs in to Infisical as the owner, with the CLI's session token

01-infrastructure is to produce credentials and put them where the cluster
reads them, rather than the owner creating them by hand: Proxmox CSI's token
written to Infisical, and the lab identity's login kept in step with each
rebuilt cluster. For that the Infisical provider has to log in.

It logs in as the owner. The provider documents its `token` as a machine
identity's, but Infisical's API takes the owner's own access token as well -
the one `infisical login` keeps for the CLI. Verified on 2026-10-04: with it
the provider read the lab project's folders, and wrote and deleted a secret.
The CLI keeps it in the macOS Keychain, where the provider cannot read it,
so a one-line `terraform` function in ~/.zshrc reads it from the CLI on
every run and passes it to that process alone; nothing is stored in a file,
a tfvars or Git. The session lasts ten days, then `infisical login` again.

Terraform can do what the owner can, in every project. That is no more than
the owner applying by hand, and no cluster holds the token.

Rejected:
- **A machine identity `terraform`**, an organization admin with Universal
  Auth credentials in the Keychain: the same reach, plus a long-lived secret
  to keep, and the fourth of the five identities the free plan allows,
  people included - the owner, `core` and `lab` hold three.
- **The token in a tfvars file**: a secret in plain text on disk, edited
  every ten days.
- **direnv and an .envrc**: a tool more, and the token read only on
  entering the directory, so stale after a new `infisical login`.
- **One identity for both clusters**, to save a slot: core's and the lab's
  would then read each other's projects, which decisions/0004 ended.
