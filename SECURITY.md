# Security policy

This is a reference implementation intended for local and demonstration use. The
default configuration is deliberately open in places a production deployment must
not be: ArgoCD served without TLS on localhost with anonymous read-only UI
access, Grafana with anonymous viewer access, Vault in dev mode. All of it is
reachable only via localhost port mappings, and all of it must be removed
before any internet-facing deployment.

Known gap, tracked for a later phase: no NetworkPolicies ship yet — east-west
traffic is unrestricted, including plaintext access to the dev-mode Vault
service from any pod. A production deployment needs default-deny policies in
the vault, external-secrets, and tenant namespaces before anything else.

## Reporting a vulnerability

If you find a vulnerability in this repository — a committed secret, an unsafe
default that is not documented as deliberate, a supply-chain issue — open a
GitHub security advisory on this repository or email milan.pavlovic@cumuluslab.io.
You will get a response within a week.
