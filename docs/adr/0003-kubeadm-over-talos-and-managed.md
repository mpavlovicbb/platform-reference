# 3. kubeadm via Cluster API, not Talos, not managed control planes

Status: accepted. Date: 2026-07-28.

## Context

Three credible ways to get a production control plane: kubeadm machines
managed by Cluster API, an immutable special-purpose OS like Talos, or the
cloud's managed offering (EKS/AKS). Each is defensible; this platform had to
pick one primary.

## Decision

kubeadm through Cluster API's KubeadmControlPlane, on stock Ubuntu images.

Managed control planes were rejected as the *primary* because they are
per-cloud by definition — the one thing this platform's thesis forbids — and
because they hide exactly the layer a reference implementation exists to
show. CAPA and CAPZ both support managed variants; the AWS/Azure READMEs
note that a team committed to one cloud should consider them.

Talos was rejected for v1 with genuine reluctance: its immutability and
API-driven management are the direction the industry is moving, and CAPI
support (CACPPT) is solid. But it replaces the OS layer everyone knows with
one most teams don't, which raises the walkthrough cost of a reference repo,
and its Hetzner story requires custom image plumbing that would dominate the
phase. It is the most likely future revision of this ADR.

## Consequences

Boring, documented, debuggable: every Kubernetes operator knows kubeadm's
shape, SSH exists when things go wrong, and CAPH provides stock Ubuntu
images out of the box. The control plane is fully declarative through CAPI
regardless.

## What we gave up

Immutability and its security posture — kubeadm-on-Ubuntu means package
drift, SSH as an attack surface, and node configuration that can rot.
Managed control planes' etcd operations, version upgrades, and SLAs are all
ours to own now; a 3-replica KubeadmControlPlane is not the same thing as
EKS's control plane and pretending parity would be false. We also carry OS
patching, which Talos would have deleted as a category.
