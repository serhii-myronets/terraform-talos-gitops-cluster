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

- **online-boutique** - Google's microservices demo, chart 0.10.7, run on
  2026-10-04 and 05 at boutique.home: eleven gRPC services and a Redis for
  the cart, with startup probes for its two Python services, which their
  liveness probes killed before they served. Its Postgres option needs
  Google Cloud (AlloyDB through Secret Manager), so it stayed on Redis.
  Taken off with the OpenTelemetry demo, which covers the same ground more
  fully. To bring it back: move it to apps/services/, list it, and put
  boutique.home back in the certificate.

- **otel-demo** - the OpenTelemetry demo, chart 0.42.2, paused on
  2026-10-05 after a day of running, whole and as it ran: the Astronomy
  Shop on the lab's own operators - Kafka 4.3.1 on Strimzi with Kafbat UI at
  kafka.home, Postgres on CloudNativePG with pgweb at postgres.home - its
  logs over OTLP to the lab's vlagent and so to core, no OpenSearch. Waits
  for core to take its traces and metrics as well (Tempo, and the demo's
  metrics into VictoriaMetrics) so that its own Jaeger, Prometheus and
  Grafana can go. To bring it back: move it to apps/services/, list it in
  apps/kustomization.yaml and put its three .home names back in the
  certificate; the operators it needs stay installed.

- **awaiting-review** - two applications carried over from the earlier
  lab and not yet reviewed, in the current layout but still in the older
  multi-source form, a chart plus `$values`: minio (from `system/storage`)
  and postgresql (`system/platform`). Moved out of `apps/` on 2026-10-04,
  so that `apps/` holds only what runs; each `application.yaml` still names
  its old path. strimzi, kafka and otel-demo were here too, until fresh
  ones replaced them in `apps/` the same day - Strimzi 1.2, and the
  OpenTelemetry demo with its Kafka on it.

`assets/` holds the screenshots of that earlier lab - Proxmox, Argo CD,
Grafana, Tempo, Jaeger, Hubble, Longhorn and the rest - which the README
showed until then.
