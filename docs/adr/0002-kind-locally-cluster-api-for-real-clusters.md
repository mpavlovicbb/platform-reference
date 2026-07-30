# 2. kind for local development, Cluster API for real clusters

Status: accepted. Date: 2026-07-28.

## Context

The platform needs a local path that boots in minutes on a laptop and in CI,
and a production path that manages real machine fleets. One tool for both is
attractive; no tool is actually good at both.

## Decision

Local and CI clusters are kind: single node, containerd registry mirror to a
local registry sidecar, host port mappings instead of load balancers. Real
clusters are Cluster API — CAPH on Hetzner as the primary documented path,
CAPA and CAPZ as references — consuming the Terraform substrate through its
output contract. Everything above the kubelet is identical GitOps either way.

A single node for kind, deliberately: the full platform fits comfortably,
boots faster, and multi-node kind adds moving parts without fidelity —
real scheduling behaviour, node failure, and rolling upgrades are exercised
on the Cluster API paths, where they are real.

## Consequences

`make up` reaches a fully healthy 21-application platform in 447 measured
seconds locally and inside a GitHub Actions runner, which makes
boot-from-nothing a required PR check rather than a claim. Cluster API keeps
cluster lifecycle declarative and provider-agnostic — the Cluster and
MachineDeployment shapes are the same on all three clouds, and `clusterctl
move` allows workload clusters to self-manage.

## What we gave up

kind is not production-shaped in the ways that bite quietly: no real load
balancer (NodePort mappings stand in), no cloud controller manager, no PV
topology, one shared kernel. A class of bugs — LB health checks, zone
spreading, CSI behaviour — cannot appear locally and will only surface on
the cloud paths. We also gave up the "one tool everywhere" story: k3d,
minikube, and cloud-provider dev clusters each pitch it, and each either
brings its own divergences or costs money per developer. Two tools with an
identical GitOps payload was the smaller lie.
