# Local path

The local substrate is Docker: a kind cluster with a registry sidecar,
provisioned by `make up` (see [bootstrap/kind/](../../../bootstrap/kind/)
and [scripts/up.sh](../../../scripts/up.sh)) — deliberately not Terraform.
Wrapping `kind create cluster` in a null-resource would add a state file and
a second lifecycle owner to something a shell script expresses in one line,
while the contract the cloud paths implement (network, nodes, object store)
collapses locally to "Docker exists".

This directory exists so the environment list is complete and honest about
that decision.
