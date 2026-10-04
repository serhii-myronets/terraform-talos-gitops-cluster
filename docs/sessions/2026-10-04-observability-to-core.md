---
date: 2026-10-04
title: The lab rebuilt once more, and its metrics and logs written to core
tags: [proxmox, terraform, talos, observability, victoriametrics, csi]
---

# The lab rebuilt once more, and its metrics and logs written to core

One day. The facts are in ../cluster.yaml, the choices in ../decisions/;
the host's side - its CPU and ProxMenux - is in the homelab repository's
session note of the same day.

## The VMs

Proxmox had been showing the control planes at 100% of their memory. Not
real: with `balloon: 0` it reports the QEMU process's memory, and a guest's
page cache fills all of it. The balloon device came back with its minimum
equal to the memory, so nothing is taken from a guest but Proxmox reads the
guest's own figures - 1.4 of 4 GiB on a control plane. Adding the device
needs the VM stopped and started, and the owner took the occasion to destroy
and apply the whole cluster.

Its contexts then had to replace the old ones, whose certificates were gone
with the cluster: `config merge` would have added `lab-1` beside. The
commands are now the Terraform output `connect`, printed after every apply.
The rebuild came up whole through 02-bootstrap and Argo CD without a hand
on it. No system extension beyond qemu-guest-agent is needed: i915 and
intel-ucode are core's because it is bare metal.

## Observability

The nine observability applications waiting for review were a second stack
in pieces. The owner asked where one stack belongs; the answer was core,
because it must outlive a lab that is rebuilt as a matter of course
(decisions/0008, and the homelab repository's 0040). The lab runs core's
chart cut down to its agents. Two fields failed Argo's server-side apply
before it ran - vmagent's queue volume is `statefulMode` and
`statefulStorage`, and VLAgent names its CA `caSecretKeyRef` - and vlagent
needed the control planes' taint tolerated. vmagent's 5 Gi queue was the
first real claim on Proxmox CSI. Core's metrics are now kept a month, as
its logs.

Still open:
- The rest of the review: minio (MinIO's community edition is no longer
  released - archive, or Garage or SeaweedFS if S3 is needed), postgresql
  (a Bitnami chart - CloudNativePG instead), strimzi, kafka, otel-demo.
- An ApplicationSet once every application is reviewed.
- Core's VictoriaMetrics disk: 100 Gi; watch how the lab's series fill it.
