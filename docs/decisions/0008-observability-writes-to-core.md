---
id: "0008"
title: The lab collects its metrics and logs, and core stores them
date: 2026-10-04
status: accepted
tags: [observability, victoriametrics, victorialogs, core]
amends: ["0004"]
---

# The lab collects its metrics and logs, and core stores them

The house has one observability stack, on core - the homelab repository's
decisions/0040 holds the reasoning. The lab runs the same chart at the same
version, `victoria-metrics-k8s-stack` 0.95.0, with only what collects:

| | role |
|---|---|
| the operator | turns VMAgent, VLAgent and the scrape objects into pods and configuration; reads ServiceMonitors too |
| vmagent | scrapes every target the operator finds, labels it `cluster=lab`, writes to core; queues on a 5 Gi volume while core is away, as a StatefulSet |
| vlagent | a DaemonSet reading every pod's log, field `cluster=lab`, writes to core |
| kube-state-metrics | the Kubernetes objects' state as metrics |
| node-exporter | each node's CPU, memory, disks and network |

VMSingle, VLSingle, Grafana, vmalert, Alertmanager, the dashboards and the
rules are core's; the rules there group by `cluster`, so they cover the lab.

Both agents write to `https://ingest.home` with a token that can only write
(the Secret `ingest`, from `/system/observability/INGEST_TOKEN`), trusting
home-ca's root from `/system/lab-ca/CA_CRT`. That token is the one credential
of core's the lab holds, an exception to decisions/0004.

Rejected: the nine separate applications the lab had - Grafana, Loki,
Tempo, Fluent Bit, the VictoriaMetrics operator and server,
kube-state-metrics, node-exporter, the OpenTelemetry operator - which made a
second stack, in pieces.
