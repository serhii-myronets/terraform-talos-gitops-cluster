# Turned off, kept whole

What the lab ran once and runs no more. Argo CD reads `../03-gitops/apps/`,
not this directory, so nothing here is deployed, and versions are as they
were left - review them before bringing anything back.

Most are from the lab before its rebuild in 2026-10, in the old layout: a
component folder of values and manifests, with its Application gone. One is
already in the current layout and moves back as it is:

- **openebs** - `application.yaml` beside `app/`, OpenEBS 4.1.1 with
  LocalPV hostpath on each worker's second disk at `/var/mnt/storage`.
  Replaced by Proxmox CSI on 2026-10-03 (docs/decisions/0007): volumes as
  disks of the Proxmox host's ZFS pool rather than directories inside a
  worker.

`assets/` holds the screenshots of that earlier lab - Proxmox, Argo CD,
Grafana, Tempo, Jaeger, Hubble, Longhorn and the rest - which the README
showed until then.
