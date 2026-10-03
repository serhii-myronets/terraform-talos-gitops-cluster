# Working in this repository

This repository builds the **lab**: Talos Kubernetes clusters as VMs on one
Proxmox VE host, made to be destroyed and rebuilt. It is one part of a
larger home setup whose source of truth is another repository:

**[serhii-myronets/homelab](https://github.com/serhii-myronets/homelab)**,
cloned locally at `~/homelab`.

| Machine | What it is | Built from |
|---|---|---|
| **core** | the cluster the house depends on: Talos on two bare-metal nodes, `controlplane` 192.168.8.10 and `worker-1` .11, Flux | `~/homelab/core/` |
| **router** | GL.iNet Flint 2 at 192.168.8.1: DNS, DHCP, WireGuard | configured by hand in its UI |
| **proxmox** | this lab's hypervisor: i9-12900HK, 62 GB, one Samsung 980 PRO 2 TB | this repository |

Before changing anything, read in `~/homelab`:

- `AGENTS.md` - the rules this setup is run by; the ones that matter here
  are repeated below.
- `docs/hosts/proxmox.yaml` - the facts about this host. That file, not
  this one, is where facts about the host are recorded; update it there,
  in that repository's style, when they change.
- `docs/network.yaml` - addresses, the DHCP pool, what is free.
- `docs/decisions/0034-satellite-joins-core.md` - why the lab exists: a
  place to rehearse what core will go through.
- `docs/traps.yaml` - Talos, Cilium and storage failures already met on
  core; most apply here as well.

## Where things stand

Proxmox VE 9.2 was reinstalled on 2026-10-03 as `00-prerequisite/README.md`
describes: ZFS (RAID0) on the single disk with about 10% left unpartitioned,
`sync=disabled` on `rpool/data`, HA off, the host at 192.168.8.30 on the
flat LAN. No VMs exist yet. Still to do:

- The lab's VMs and VIP within 192.168.8.31-.49, replacing the 10.1.1.0/24
  defaults in `variables.tf`. The router's DHCP pool is .100-.249; core
  holds .10, .11 and .15-.19.
- A Proxmox API token instead of the root password, kept out of Git.
- Talos brought to the version core runs, with the `qemu-guest-agent`
  extension, since the VMs enable the agent.
- Possibly the lab as a copy of core on Flux, to rehearse upgrades,
  instead of its own Argo CD stack. A proposal, not a decision.

More than half of the host's power cycles have been unsafe shutdowns; a UPS,
or finding what cuts its power, comes before anything here should last.

`.claude/handoff.md`, if present, holds local notes from the previous
session that do not belong in a public repository. Read it first.

## Rules

**Reply to Serhii in Ukrainian; write the repository in English.**

**Never print a secret.** `terraform.tfvars`, `initial-secret.yaml`,
Terraform state and Talos configs hold credentials. Read values into
variables, filter `password|secret|token|key` from output, and never put a
credential in a tracked file. This repository is public.

**Commits carry one author.** No `Co-Authored-By`, no "Generated with", no
agent named in a commit, tag or pull request.

**Ask before anything stateful**: destroying VMs or clusters, wiping or
reinstalling the host, rewriting history, force-pushing. The owner's call,
not a step in a plan.

**See the change before making it.** `terraform plan -out=<file>`, read it,
then apply that file. `talosctl validate --strict` and `apply-config
--dry-run` before a Talos change.

**Never change the router over ssh.** Its firmware regenerates its config
from its own state; describe router changes as steps in its UI.

**Verify before writing a fact down**, on the live host, not from memory.

**zsh**: a command held in a variable is not split into words - call it
directly or through a function; a word starting with `===` breaks a command;
`l`, `h`, `g` and `k` are aliases, so do not name functions after them.
