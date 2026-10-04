---
id: "0011"
title: External Secrets logs in to Infisical with the cluster's own ServiceAccount token
date: 2026-10-04
status: accepted
tags: [external-secrets, infisical, jwt, serviceaccount, secrets]
---

# External Secrets logs in to Infisical with the cluster's own ServiceAccount token

The lab's External Secrets used to log in as the identity `lab` with a
Universal Auth client ID and secret, the one secret placed by hand:
`02-bootstrap/prepare-hook/initial-secret.yaml`, kept on the Mac. Now it
logs in by JWT, and nothing secret is placed anywhere.

`03-gitops/apps/system/security/external-secrets` holds a ServiceAccount,
`external-secrets/infisical`, and an empty Secret of type
`kubernetes.io/service-account-token`, which kube-controller-manager fills
with a long-lived token for it, signed with the cluster's ServiceAccount
key. The ClusterSecretStore sends that token to Infisical. The identity
`lab` has JWT auth of the static kind: it holds the public half of that key
and accepts a token with issuer `kubernetes/serviceaccount` and subject
`system:serviceaccount:external-secrets:infisical` - checked by Infisical
alone, since the cluster is not reachable from the internet. Universal Auth
is off for `lab`. Verified on 2026-10-04: every ExternalSecret synced with
the old credential deleted from the cluster and from Infisical.

The key is the same at every rebuild, because the cluster is made from
Talos secrets kept in Infisical (0010). So its public half was given to
Infisical once, by hand, from the cluster's JWKS (`/openid/v1/jwks`); it
changes only if the Talos secrets are generated anew.

Not by Terraform: `infisical_identity_jwt_auth` in provider 0.19.38 refuses
a public key computed from another resource during validation - an unknown
list element is read as an empty string, "not a valid PEM-encoded key"
(the homelab repository's traps.yaml). A key from a file would pass, but
a file kept in step with the secrets is a workaround the owner did not want.

Rejected:
- **Kubernetes auth in Infisical**: it checks a token by calling the
  cluster's TokenReview API, which Infisical Cloud cannot reach behind NAT;
  the way around it, Infisical's Gateway, is an Enterprise feature.
- **The client secret made by Terraform and put in by Talos's inline
  manifests**: no hand step either, but still a secret, in the cluster and
  in the state.
- **SOPS**, the home-ops community's usual way for the one bootstrap
  secret: the owner did not want it.
