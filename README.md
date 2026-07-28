# platform-reference

A production-shaped internal developer platform that runs on any cloud — or none.

This repository is under active construction. The build plan, constraints, and
acceptance criteria are fixed; phases land as meaningful commits, and each phase
leaves `make up` producing a fully healthy stack.

## Status

| Phase | Scope | State |
|---|---|---|
| 1 | Bootable skeleton: kind, local registry, ArgoCD, app-of-apps | done |
| 2 | Core platform: cert-manager, external-secrets, Envoy Gateway, Kyverno | next |
| 3 | Observability: kube-prometheus-stack, Loki, Alloy, SLO alerting | planned |
| 4 | Demo workloads, seeded signals, tenant golden path | planned |
| 5 | CI, e2e in kind, supply chain (SBOM, signing) | planned |
| 6 | Cloud paths: Cluster API for Hetzner, AWS, Azure | planned |
| 7 | ADRs, migration playbooks, docs site, README to final spec | planned |

## Quickstart

Prerequisites: Docker (8 GB+ RAM allocated), kind, kubectl, helm, jq.

```sh
git clone https://github.com/mpavlovicbb/platform-reference
cd platform-reference
make up
```

`make up` boots a kind cluster with a local registry, installs ArgoCD pinned to
v3.4.5, applies the root app-of-apps, and blocks until every application is
Synced and Healthy — then prints URLs and credentials. `make down` removes
everything.

Measured boot time for the phase 1 stack: 92 seconds from `make up` to all
applications healthy (Apple M-series, 12 cores, Docker 11.7 GB; excludes the
one-time `kindest/node` image pull on a first-ever machine).

## License

Apache-2.0. See [LICENSE](LICENSE).
