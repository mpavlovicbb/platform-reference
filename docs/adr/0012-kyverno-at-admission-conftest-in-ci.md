# 12. Kyverno at admission and Conftest in CI — deliberately both

Status: accepted. Date: 2026-07-29.

## Context

Policy can gate at review time (CI over manifests in git) or at admission
time (webhook over what actually reaches the API server). Teams often pick
one and trust it alone.

## Decision

Both, with the same rules expressed twice on purpose. Conftest/Rego runs in
CI over the repo's manifests: pinned chart versions, selfHeal on automated
sync, resource requests, no `:latest`. Kyverno enforces the workload subset
at admission, scoped by namespace label so tenants get guardrails and
platform namespaces stay out of the blast radius; privileged containers are
audited cluster-wide and enforced in labelled namespaces.

The duplication is the design. CI catches what lives in git — but helm
templates render at sync time, operators create resources git never saw,
and `kubectl run` exists; only admission sees those. Admission catches
everything — but a rejected sync is a worse developer experience than a
failed PR check; review-time feedback is minutes cheaper. Kyverno over
Gatekeeper for the same legibility reason ArgoCD won: YAML-native policies
a reviewer reads without learning Rego — while CI-side Rego stays, where
its expressiveness over arbitrary file shapes earns it.

## Consequences

The e2e proves the admission path live (`kubectl run bad --image=nginx:latest`
is rejected with an actionable message on every PR), and the review pass
that found the gaps — initContainers unchecked, an Enforce variant promised
by a comment but absent — hardened both layers at once.

## What we gave up

One engine and one source of truth. Two policy languages must be kept in
agreement by discipline, not tooling — nothing detects the Rego and the
ClusterPolicy drifting apart except review. Kyverno's admission webhook is
also a single point of failure in fail-closed mode with one replica (stated
trade-off in its values), and its pattern syntax has real expressiveness
edges: the registry-port-untagged-image case is documented as a known gap
precisely because the pattern language cannot parse image references.
