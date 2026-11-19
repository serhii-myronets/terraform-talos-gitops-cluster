---
id: "0013"
title: The Appraisal Workbench keeps its two databases in the lab, reached from the Mac on the LAN
date: 2026-11-18
status: accepted
tags: [cloudnative-pg, postgres, postgis, appraisal, cilium]
---

# The Appraisal Workbench keeps its two databases in the lab, reached from the Mac on the LAN

The Appraisal Workbench (the owner's application, `serhii-myronets/appraisal-flow`)
ran its PostgreSQL in Docker on the Mac. On 2026-11-18 copying its maps into a
new PostGIS database filled the Mac's disk, Docker's disk failed, and the
database stopped until space was freed. Its data now lives here, as two
CloudNativePG clusters in `services/appraisal`:

- `appraisal-db`, PostgreSQL 17: the reports and everything the application
  writes about them. The owner's own data, on `proxmox-zfs-retain` so a rebuilt
  cluster finds it again. Backups to R2 through the Barman Cloud plugin are the
  next step; until then it is no worse off than on the Mac.
- `geo-db`, PostGIS: the maps it copies (zoning, FEMA, USGS water; parcels,
  roads and golf courses next). Reference data that can always be copied again
  from its sources: plain `proxmox-zfs`, no backup.

The application itself stays on the Mac for now - its agent runs under the
owner's Claude login in a macOS sandbox, and it changes many times a day - and
reaches each primary through a `LoadBalancer` Service from the lab's pool:
`192.168.8.32` and `.33`, port 5432, with CloudNativePG's TLS. Away from home
it reaches them through the router's WireGuard.

## Rejected

- **Databases on core.** core runs the house's services and has no
  CloudNativePG; the lab has the operator and the room.
- **One cluster with two databases.** Different storage classes, backup needs
  and load: the parcels' reloads should not touch the reports.
- **The databases behind the Gateway.** It speaks HTTP; PostgreSQL needs TCP.
