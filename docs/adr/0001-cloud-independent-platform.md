# 1. A cloud-independent platform rather than one cloud's managed services

Status: accepted. Date: 2026-07-28.

## Context

Every capability this platform provides exists as a managed service on every
major cloud: EKS/AKS for clusters, Secrets Manager/Key Vault for secrets,
CloudWatch/Azure Monitor for observability, ALB/AppGW for ingress. Leaning
into one cloud's suite is less work up front and is the right call for many
teams. This platform deliberately does the opposite: the same control plane,
delivery model, and day-2 tooling on a laptop, on Hetzner, on AWS, or on
Azure, with cloud specifics confined to a thin swappable layer.

## Decision

Portable open components — ArgoCD, External Secrets, Envoy Gateway,
Kyverno, the Prometheus/Loki stack — run identically everywhere. The
cloud-specific surface is held at three named seams: the Terraform substrate
contract (network, nodes, object storage), the ClusterSecretStore provider,
and the EnvoyProxy service type. Swapping clouds means swapping what sits
behind those seams and nothing else.

## Consequences

The local environment is a faithful miniature of production, so the entire
platform is testable in CI for free — the e2e boots the real thing on every
PR, which no managed-service architecture can offer without a cloud bill and
credentials in the pipeline. Exit costs and multi-provider strategies become
real options instead of slideware. Hetzner — a fraction of hyperscaler
compute pricing — becomes a first-class production target precisely because
nothing depends on hyperscaler services.

## What we gave up

Managed-service operational maturity, most of all. EKS's control plane SLA,
IAM-integrated everything, and CloudWatch's zero-setup ingestion are genuinely
excellent, and we run our own equivalents instead — which is engineering time
spent on undifferentiated heavy lifting. Each portable component is one more
thing to upgrade and page on. We also gave up per-cloud optimizations:
nothing here uses spot orchestration, Karpenter, or provider-native autoscaling,
because the lowest common denominator constrains the whole. This trade is
right when portability and local fidelity are strategy; it is wrong for a
single-cloud product team, and pretending otherwise would be dishonest.
