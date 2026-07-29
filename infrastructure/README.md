# Infrastructure — the substrate layer

Terraform provides only what sits **below the kubelet**: network, node
prerequisites, DNS, object storage. Everything above it — the cluster's
contents — is GitOps from `platform/`, identical on every cloud. Cluster
lifecycle itself belongs to Cluster API, not Terraform: Terraform makes the
ground, Cluster API grows the cluster, ArgoCD fills it.

## The contract

Every `modules/<cloud>-substrate` implements the same variable and output
interface. That interface is the cloud-agnostic layer — the modules
themselves are intentionally cloud-specific, because pretending one module
can abstract three clouds produces the worst of each.

| Variables (in) | Outputs (out) |
|---|---|
| `name`, `environment` | `network_id` |
| `region` / `location` | `subnet_ids` |
| `network_cidr` | `object_store` (bucket/container id) |
| `allowed_admin_cidrs` | `ssh_key_ref` (where applicable) |

Swapping clouds means swapping which module an environment calls; nothing
above the contract changes.

## Environments

| Path | Status |
|---|---|
| `environments/local` | kind — provisioned by `make up`, not Terraform; see its README |
| `environments/hetzner` | primary non-hyperscaler path: substrate + Cluster API (CAPH) |
| `environments/aws` | substrate + Cluster API (CAPA) reference |
| `environments/azure` | substrate + Cluster API (CAPZ) reference |

All cloud environments are **documented and validated, never CI-applied**:
CI runs `terraform validate` and tflint against each, with no credentials
anywhere near the pipeline. Applying them is a deliberate human act,
described in each environment's README.
