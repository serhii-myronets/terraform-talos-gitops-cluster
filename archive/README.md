# Turned off, kept whole

What the lab ran once and runs no more. Argo CD reads `../03-gitops/apps/`,
not this directory, so nothing here is deployed, and versions are as they
were left - review them before bringing anything back.

Most are from the lab before its rebuild in 2026-10, in the old layout: a
component folder of values and manifests, with its Application gone. Four are
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

- **tetragon** - Cilium's eBPF runtime security, chart 1.7.1, run for an
  evening on 2026-10-04 to learn it: every process in every pod, files and
  connections through a TracingPolicy, and a kill from the kernel. Taken
  off the same day. Its events answer what logs cannot - what ran inside a
  container, written by no one inside it - but they are worth keeping only
  where someone watches them, a security team with alerts; in a lab with one
  user and no code of anyone else's they were five pods and noise in core's
  log store. Its CRDs are made by its operator, not by Argo CD, and were
  deleted by hand with it.

- **awaiting-review** - five applications carried over from the earlier
  lab and not yet reviewed, in the current layout but still in the older
  multi-source form, a chart plus `$values`: minio (from
  `system/storage`), postgresql and strimzi (`system/platform`), kafka and
  otel-demo (`services`). Moved out of `apps/` on 2026-10-04, so that
  `apps/` holds only what runs. Their `application.yaml` still names its
  old path, so each moves back to where it was; strimzi needs its CRDs
  again, which 02-bootstrap's prepare hook no longer lists.

`assets/` holds the screenshots of that earlier lab - Proxmox, Argo CD,
Grafana, Tempo, Jaeger, Hubble, Longhorn and the rest - which the README
showed until then.
