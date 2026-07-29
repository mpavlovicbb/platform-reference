# Azure path

Reference substrate (resource group, VNet, NSG with admin-scoped API access,
TLS-hardened storage account with a private Loki container) plus CAPZ
Cluster API manifests. Validated in CI, never applied there.

Flow mirrors [the Hetzner path](../hetzner/README.md): substrate apply →
`clusterctl init --infrastructure azure` with workload-identity credentials
→ fill `<substrate.*>` from outputs → apply cluster.yaml → bootstrap ArgoCD
with the same root application.
