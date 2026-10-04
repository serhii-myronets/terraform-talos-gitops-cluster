---
id: "0002"
title: Terraform owns the Talos and Kubernetes upgrades, through talos_machine and talos_cluster
date: 2026-10-03
status: accepted
tags: [talos, terraform, kubernetes, upgrades]
---

# Terraform owns the Talos and Kubernetes upgrades, through talos_machine and talos_cluster

Talos provider 0.12 brought two resources: `talos_machine` applies a node's
configuration and, when its installer image changes, cordons, drains,
upgrades and uncordons the node; `talos_cluster` bootstraps etcd and runs
Talos's upgrade-k8s when its Kubernetes version changes. The lab uses both,
so an upgrade is a version in `01-infrastructure/locals.tf` and a plan -
applied with `-parallelism=1`, one node at a time.

Rejected: `talos_machine_configuration_apply` and `talos_machine_bootstrap`,
what core uses. They apply configuration and nothing more; upgrades stay a
`talosctl` procedure by hand. Rehearsing the newer resources here is how core
would learn whether to move to them.

With provider 0.12 the configuration is generated against Talos's v1.14
contract, where each part is a document of its own and the old v1alpha1 keys
for the same settings are refused beside them; the patches in
`01-infrastructure/patches/` are written that way. The contract stays at
v1.14 through upgrades and moves only on purpose.

The cluster is three control planes, so etcd keeps quorum through an
upgrade, and two workers with what is left of the host's memory.
