# 13. Namespace-per-tenant over vcluster — and where that breaks down

Status: accepted. Date: 2026-07-29.

## Context

The golden path needs a tenancy unit. The pragmatic end of the spectrum is
a namespace per tenant with policy guardrails; the strong-isolation end is
virtual clusters (vcluster) or physical cluster-per-tenant.

## Decision

Namespace-per-tenant. The ApplicationSet stamps each tenant a namespace
carrying enforcement labels (`managedNamespaceMetadata`, so labels are
platform-owned, not tenant-suppliable), Kyverno enforces workload policy
inside it, and gateway access is an explicit platform-granted label. The
boundary is soft multi-tenancy: guardrails against mistakes, not walls
against adversaries.

vcluster was rejected for v1 on cost-of-fidelity grounds: each virtual
cluster adds its own control plane to run, upgrade, and observe; the
observability and gateway stacks would need per-vcluster wiring that would
dominate the reference; and the teams this platform models — internal
product teams — need isolation from each other's accidents, not from each
other's intent.

## Consequences

Onboarding stays a one-file merge with sub-minute materialization, every
platform service (scraping, logging, routing, policy) reaches tenants with
zero per-tenant configuration, and cluster-wide capacity is shared
efficiently.

## What we gave up

Real isolation, and it is worth being precise about where the namespace
model breaks down: CRDs and their versions are cluster-global — two tenants
needing different operator versions is unsolvable here; anything
cluster-scoped (webhooks, ClusterRoles, an operator watching all
namespaces) escapes the boundary; noisy neighbours share kernels, kubelets,
and the API server, so a tenant can degrade others without violating any
policy; and namespace admins who can create pods can, absent the enforced
policies, probe the node. When any of those become real requirements —
hostile tenants, conflicting CRDs, compliance demanding hard walls —
vcluster (cheaper) or cluster-per-tenant via the existing Cluster API paths
(stronger) is the graduation, and the roadmap names it as future direction
rather than pretending namespaces stretch that far.
