---
id: "0014"
title: appraisal-db backs up to R2 through the Barman Cloud plugin, beside core's backups
date: 2026-11-18
status: accepted
tags: [cloudnative-pg, backup, r2, barman]
---

# appraisal-db backs up to R2 through the Barman Cloud plugin, beside core's backups

`appraisal-db` (0013) holds data that exists nowhere else, on a host whose
power cycles have more often been unsafe than not. It is backed up the way
CloudNativePG intends: the Barman Cloud plugin (`system/platform/plugin-barman-cloud`,
chart 0.8.1, plugin 0.15) archives every WAL segment as it is written and takes
a base backup daily at 04:30, into R2, bucket `homelab-backups`, prefix
`lab/cnpg/` - the bucket core already writes to, with the key pair the lab's
Infisical keeps at `/system/backups`. 30 days are kept, so a restore can go to
any moment of them.

`geo-db` was first left without a backup; since 0015 it is backed up weekly.

## Rejected

- **VolSync of the volume, as on core.** A file copy of a running PostgreSQL is
  only consistent with the WAL beside it; the plugin gives point-in-time
  recovery and is CloudNativePG's own way.
- **A bucket of the lab's own.** One bucket, one key pair and one place to look
  for every backup of the house; the prefix keeps the lab apart.
