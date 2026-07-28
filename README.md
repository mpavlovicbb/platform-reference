# platform-reference

A production-shaped internal developer platform that runs on any cloud — or none.
One command boots the whole thing on a laptop in 261 measured seconds.

[![validate](https://github.com/mpavlovicbb/platform-reference/actions/workflows/validate.yaml/badge.svg)](https://github.com/mpavlovicbb/platform-reference/actions/workflows/validate.yaml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
![Kubernetes](https://img.shields.io/badge/Kubernetes-kind%20%2B%20Cluster%20API-326CE5?logo=kubernetes&logoColor=white)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo&logoColor=white)
![Kyverno](https://img.shields.io/badge/Policy-Kyverno-blue)
![Envoy](https://img.shields.io/badge/Gateway%20API-Envoy-AC6199)

![Platform tour: healthy GitOps tree, a policy rejection, gateway routing, and a Vault-backed secret](docs/assets/tour.gif)

| Measured boot | GitOps-managed applications | Credentials in git |
|:---:|:---:|:---:|
| 261 s to fully healthy | 13, from one root | 0, enforced by three layers |

## The problem

Most platform teams are a ticket queue: developers wait days for clusters,
environments drift into unrepeatable snowflakes, and every capability is welded
to one cloud vendor's managed services. This repository is a working counterexample.
Everything — delivery, ingress, secrets, policy — reconciles from a single Git
root, and the cloud-specific surface is confined to a thin layer that swaps
between a laptop, Hetzner, AWS, or Azure. My production work of this shape lives
in private employer repositories; this reference makes that judgment publicly
reviewable.

## Architecture

```mermaid
flowchart TB
    subgraph lifecycle ["Cluster lifecycle"]
        kind["kind (local, CI)"]
        capi["Cluster API: Hetzner / AWS / Azure (planned)"]
    end
    subgraph delivery ["Delivery"]
        git[(Git root)] --> argocd["ArgoCD app-of-apps"]
    end
    subgraph day2 ["Day-2 platform"]
        gw["Envoy Gateway (Gateway API)"]
        es["External Secrets + Vault"]
        pol["Kyverno policies"]
        cm["cert-manager"]
        obs["Observability stack (planned)"]
    end
    lifecycle --> delivery
    argocd --> gw & es & pol & cm & obs
    argocd --> demo["Tenant workloads"]
```

The boundary discipline is the point: swapping Vault for a cloud secrets manager
touches one ClusterSecretStore; swapping NodePort for a LoadBalancer touches one
EnvoyProxy resource; everything above those seams is identical everywhere.

## What this demonstrates

- A developer-facing platform where onboarding a workload is a Git merge, not a ticket
- Guardrails that fail fast: bad manifests are rejected at admission with actionable messages
- Secrets that never touch the repository — generated at runtime, delivered through a swappable provider boundary
- Boot-from-nothing reproducibility, measured and gated, not claimed
- Failure-driven hardening: the commit history contains the real ordering deadlocks and drift bugs a clean-boot gate surfaced, each fixed declaratively

## For engineers — start here

| Interest | Where |
|---|---|
| Delivery topology | [bootstrap/argocd/root-app.yaml](bootstrap/argocd/root-app.yaml), [platform/root/](platform/root/) |
| Boot mechanics and health gating | [scripts/up.sh](scripts/up.sh) |
| Policy set and enforcement scoping | [platform/core/kyverno-policies/](platform/core/kyverno-policies/) |
| Secrets chain | [platform/core/external-secrets/](platform/core/external-secrets/), [platform/core/vault/](platform/core/vault/) |
| Ingress via Gateway API | [platform/core/gateway/](platform/core/gateway/) |
| CI | [.github/workflows/validate.yaml](.github/workflows/validate.yaml) |

## Quickstart

Prerequisites: Docker with 8 GB+ RAM, kind, kubectl, helm, jq.

```sh
git clone https://github.com/mpavlovicbb/platform-reference
cd platform-reference
make up      # preflight, cluster, ArgoCD, every app Synced+Healthy, URLs printed
make status  # sync and health of all applications
make down    # full teardown, no orphans
```

Try the guardrails on the running stack:

```sh
kubectl run bad --image=nginx:latest -n demo        # rejected by policy
curl -H "Host: podinfo.platform.local" localhost:8080   # routed through Envoy
kubectl -n demo get secret demo-config              # materialized from Vault
```

## Repository layout

```
bootstrap/    kind cluster config; ArgoCD install and the one hand-applied Application
platform/
  root/       app-of-apps: every Application the platform runs
  core/       cert-manager, vault, external-secrets, gateway, kyverno policies, namespaces
scripts/      up / down / status / record-cast, with preflight and health gates
docs/         assets today; architecture docs, ADRs, and playbooks land with later phases
```

## Roadmap and known limitations

Built in phases; each phase leaves `make up` green. Done: bootable skeleton
(phase 1), core platform — cert-manager, External Secrets with Vault dev-mode
backend, Envoy Gateway, Kyverno (phase 2).

Not here yet, and known:

- No observability stack — kube-prometheus-stack, Loki, Alloy, and SLO
  burn-rate alerting are next (phase 3); until then the platform has no
  dashboards, which is the biggest current gap
- No e2e boot in CI yet (phase 5) — today CI covers secret scanning and lint;
  the kind-based full-stack boot on every PR is designed but not landed
- Cloud paths are declared boundaries, not yet shipped modules — Cluster API
  for Hetzner, AWS, and Azure arrives in phase 6
- Architecture decision records and migration playbooks (phase 7) will document
  the trade-offs the commit history currently carries implicitly
- Vault runs in dev mode and ArgoCD serves plaintext on localhost — deliberate
  for local use, documented in [SECURITY.md](SECURITY.md), unsuitable for
  internet-facing deployment as-is

## License

Apache-2.0. See [LICENSE](LICENSE).
