# AWS path

Reference substrate (VPC, public/private subnets, NAT egress, flow logs,
encrypted versioned S3) plus CAPA Cluster API manifests. Validated in CI,
never applied there.

Flow is identical in shape to [the Hetzner path](../hetzner/README.md):
substrate apply → `clusterctl init --infrastructure aws` (credentials
via `clusterawsadm bootstrap iam`) → fill `<substrate.*>` from outputs →
apply cluster.yaml → bootstrap ArgoCD with the same root application.

The S3 bucket doubles as the Loki object store on this path — swap Loki's
filesystem storage in a values overlay; the ADR on log architecture covers
when that switch is warranted.
