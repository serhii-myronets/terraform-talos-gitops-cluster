# Turned off, kept whole

What the lab ran once and runs no more. Argo CD reads `../03-gitops/apps/`,
not this directory, so nothing here is deployed, and versions are as they
were left - review them before bringing anything back.

Most are from the lab before its rebuild in 2026-10, in the old layout: a
component folder of values and manifests, with its Application gone. Two are
already in the current layout and move back as they are:

- **openebs** - `application.yaml` beside `app/`, OpenEBS 4.1.1 with
  LocalPV hostpath on each worker's second disk at `/var/mnt/storage`.
  Replaced by Proxmox CSI on 2026-10-03 (docs/decisions/0007): volumes as
  disks of the Proxmox host's ZFS pool rather than directories inside a
  worker.

- **observability** - nine applications in the current layout: Grafana,
  Loki, Tempo, Fluent Bit, the VictoriaMetrics operator and server,
  kube-state-metrics, node-exporter and the OpenTelemetry operator, a
  second stack in pieces. Replaced on 2026-10-04 by
  `system/observability/victoria-metrics`, the lab's agents writing to
  core's stores (docs/decisions/0008).

`assets/` holds the screenshots of that earlier lab - Proxmox, Argo CD,
Grafana, Tempo, Jaeger, Hubble, Longhorn and the rest - which the README
showed until then.
