---
title: Documentation index
tags: [index, docs]
---

# docs

The lab's own record, kept as the homelab repository keeps its docs/: facts
are YAML, verified against the live cluster; reasoning is Markdown with YAML
front matter; every fact lives in exactly one file.

**[`index.yaml`](index.yaml) is the entry point** - it maps a question to the
file that answers it, here or in the homelab repository.

| | |
|---|---|
| [`cluster.yaml`](cluster.yaml) | the lab's cluster now: nodes, versions, what is installed and what runs |
| [`decisions/`](decisions/) | why the lab is built this way |
| [`sessions/`](sessions/) | the last working session; read it before starting |

Facts about the Proxmox host, the network and the router are not here: they
live once, in the homelab repository's docs/, and so do the traps both
clusters meet.
