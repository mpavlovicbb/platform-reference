# 7. External Secrets Operator and the provider abstraction boundary

Status: accepted. Date: 2026-07-28.

## Context

GitOps forbids secrets in git; something must deliver them into the cluster
from a system of record. Candidates: External Secrets Operator, sealed
secrets (encrypted in git), SOPS-encrypted values, or Vault's injector
sidecar.

## Decision

External Secrets Operator with a single ClusterSecretStore named `platform`
as the only seam workloads see. Locally the store fronts a dev-mode Vault
whose root token is generated at boot and exists only in-cluster; on the
cloud paths the same store swaps to AWS Secrets Manager or Azure Key Vault
with workload identity — consumers reference `platform` either way and
cannot tell the difference. Sealed-secrets and SOPS were rejected because
both put ciphertext in git: rotation becomes a commit, key loss becomes a
repo-wide re-encryption, and audit trails split between git and the KMS.
The Vault injector was rejected for coupling workloads to Vault
specifically — the opposite of a swappable boundary.

The demo chain is deliberately end-to-end: a Sync-hook job seeds Vault with
runtime-generated values, an ExternalSecret materializes them into a plain
Secret, and the e2e asserts the whole path on every PR.

## Consequences

Zero credentials in git across all of history (gitleaks-verified, three
enforcement layers), secrets rotate in the backend without touching the
repo, and cloud migration of the secret system of record is one spec change.

## What we gave up

The operator itself is now critical-path infrastructure: if ESO is down,
new pods needing fresh secrets are down, a failure mode sealed-secrets
simply does not have. Secrets exist as plain Kubernetes Secrets at rest in
etcd — anyone with etcd access has them, where the injector's
in-memory-only model was stricter. And the dev-mode Vault is in-memory: a
restart loses the seed, which cost a real bug (the reseed-on-sync hook
exists because of it) and stands in for the operational care a real
backend needs.
