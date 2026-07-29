# Hetzner path

The primary non-hyperscaler environment: Terraform substrate + Cluster API
(CAPH). Nothing here runs in CI beyond `terraform validate` and tflint —
applying is a human act.

## Order of operations

1. **Substrate**: `HCLOUD_TOKEN=... terraform apply` here. Produces network,
   subnet, firewall, SSH key, placement group (see `outputs.tf`).
2. **Management cluster**: any existing cluster — the local kind platform
   works — with `clusterctl init --infrastructure hetzner`.
3. **Credentials**: `kubectl create secret generic hetzner
   --from-literal=hcloud=$HCLOUD_TOKEN` (runtime-created, like every other
   credential in this repo).
4. **Cluster**: fill the `<substrate.*>` values in
   [cluster-api/cluster.yaml](cluster-api/cluster.yaml) from the Terraform
   outputs and apply. CAPH provisions the load-balanced control plane and
   workers.
5. **Platform**: bootstrap ArgoCD on the new cluster the same way
   `scripts/up.sh` does for kind — same root application, same everything.
   The NodePort/LoadBalancer difference lives in the EnvoyProxy resource;
   the Vault dev backend swaps for a real secret store at the
   ClusterSecretStore boundary.
6. **Pivot (optional)**: `clusterctl move` makes the workload cluster
   self-manage once it is stable.

## Object storage

Hetzner's S3-compatible object storage is not managed by the hcloud
Terraform provider; create Loki/backup buckets against
`https://fsn1.your-objectstorage.com` with any S3 tooling and wire the
endpoint into the Loki values on this environment's overlay.
