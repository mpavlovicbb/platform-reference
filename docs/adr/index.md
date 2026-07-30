# Architecture decision records

Every significant choice in this platform, recorded MADR-style with the
section that matters most: **what we gave up**. A decision record that only
lists benefits is marketing; these are not.

| # | Decision |
|---|---|
| [1](0001-cloud-independent-platform.md) | A cloud-independent platform rather than one cloud's managed services |
| [2](0002-kind-locally-cluster-api-for-real-clusters.md) | kind for local development, Cluster API for real clusters |
| [3](0003-kubeadm-over-talos-and-managed.md) | kubeadm via Cluster API, not Talos, not managed control planes |
| [4](0004-argocd-over-flux.md) | ArgoCD over Flux |
| [5](0005-app-of-apps-with-applicationsets.md) | App-of-apps root with ApplicationSets for tenants |
| [6](0006-upstream-charts-never-forked.md) | Upstream Helm charts with inline values, never forked |
| [7](0007-external-secrets-and-the-provider-boundary.md) | External Secrets Operator and the provider abstraction boundary |
| [8](0008-gateway-api-over-ingress-nginx.md) | Gateway API via Envoy Gateway, not ingress-nginx |
| [9](0009-kube-prometheus-stack-and-the-mimir-threshold.md) | kube-prometheus-stack, and the scale where Mimir/Thanos becomes necessary |
| [10](0010-loki-and-alloy-with-budgets.md) | Loki with Alloy collection, and explicit retention and cardinality budgets |
| [11](0011-slo-burn-rate-alerting.md) | Multi-window burn-rate alerting on SLOs; static thresholds rejected |
| [12](0012-kyverno-at-admission-conftest-in-ci.md) | Kyverno at admission and Conftest in CI — deliberately both |
| [13](0013-namespace-per-tenant-over-vcluster.md) | Namespace-per-tenant over vcluster — and where that breaks down |
| [14](0014-supply-chain-scope.md) | Supply chain: what is signed, what is scanned, what deliberately is not |
| [15](0015-no-backstage-in-v1.md) | No Backstage in v1 — the golden path is ApplicationSets and one file |
