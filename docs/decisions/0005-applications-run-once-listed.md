---
id: "0005"
title: 03-gitops is laid out as core's, and an application runs once it is listed
date: 2026-10-03
status: accepted
tags: [argocd, gitops, layout]
---

# 03-gitops is laid out as core's, and an application runs once it is listed

`03-gitops/apps` follows core's `core/03-gitops/apps`: `system/<category>/<name>`
and `services/<name>`, each an `application.yaml` - core's `ks.yaml` - beside
an `app/` folder with its manifests and values. One root Application,
`03-gitops/root.yaml`, renders `apps/kustomization.yaml`, as core's root
renders its own; 02-bootstrap applies it.

The applications came over from the lab as it was before the rebuild, and
each is reviewed before it runs again - versions, values, secrets, names.
Listing an application in `apps/kustomization.yaml` is what deploys it; the
unreviewed ones wait in `apps/` with their line commented out. The root does
not prune, so taking a line out leaves the application running until it is
deleted on purpose.

Rejected: four tier roots - core, platform, services, observability - each
deploying everything under it. A root could not hold back one application,
so every review meant applying files by hand. The four AppProjects went with
them: each allowed every source and destination, so `default` does the same
with less.
