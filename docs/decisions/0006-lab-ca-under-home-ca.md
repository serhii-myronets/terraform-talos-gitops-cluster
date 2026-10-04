---
id: "0006"
title: The lab's .home certificates come from lab-ca, an intermediate under home-ca limited to .home
date: 2026-10-03
status: accepted
tags: [tls, cert-manager, home-ca, security]
---

# The lab's .home certificates come from lab-ca, an intermediate under home-ca limited to .home

Core signs its .home certificate with home-ca, the house's root, whose
certificate and key it reads from Infisical; every device trusts that root.
The lab needs the same for its own .home names, without what would make it
dangerous: whoever holds a root's key can sign any name, and every device in
the house would believe it.

lab-ca is an intermediate signed by home-ca once, on the Mac, with the
root's key read from Infisical into the signing command and never written
down. It carries a critical name constraint - DNS `home` only - and
`pathlen:0`, so it can sign .home server certificates and nothing else: a
certificate it signs for any other name fails verification. Its certificate,
key and the root's certificate are in the lab's Infisical project at
/system/lab-ca; cert-manager's ClusterIssuer `lab-ca` signs the Gateway's
`home-tls`, listing the lab's names only. Devices install nothing.

Rejected:
- **home-ca's own key in the lab**: simplest, and it puts a key that can
  impersonate any site for every device into the least trusted cluster.
- **A separate root for the lab**: complete isolation, at the price of
  trusting a second root on every device.
- **No local HTTPS**: the lab only through serhii.link, the tunnel and
  Cloudflare Access.

What is left: lab-ca can still sign one of core's .home names, and the lab's
TSIG key can publish any .home name, so a lab taken over could impersonate,
say, vault.home. There is no revocation for lab-ca short of replacing
home-ca. Keeping the lab's own access closed - Argo CD's anonymous admin
first - is what stands between the two.

lab-ca is valid until 2031-10-03; nothing renews it. Issue the next the same
way: a P-256 key, signed by home-ca for 1825 days with `basicConstraints
critical CA:TRUE pathlen:0`, `keyUsage critical keyCertSign cRLSign
digitalSignature` and `nameConstraints critical permitted;DNS:home`, stored
as TLS_CRT, TLS_KEY and CA_CRT.
