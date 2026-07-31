# Security policy

This is a reference implementation intended for local and demonstration use. The
default configuration is deliberately open in places a production deployment must
not be: ArgoCD served without TLS on localhost with anonymous read-only UI
access, Grafana with anonymous viewer access, Vault in dev mode. All of it is
reachable only via localhost port mappings, and all of it must be removed
before any internet-facing deployment.

East-west traffic is restricted where it matters: Vault accepts ingress only
from External Secrets and its own seed job, External Secrets only from the
API server's webhook path, and every tenant namespace receives a generated
network floor (default-deny ingress plus same-namespace, Prometheus, and
gateway allowances) from a Kyverno generate policy. Egress restrictions are
deliberately out of scope locally.

## Reporting a vulnerability

If you find a vulnerability in this repository — a committed secret, an unsafe
default that is not documented as deliberate, a supply-chain issue — open a
GitHub security advisory on this repository or email milan.pavlovic@cumuluslab.io.
You will get a response within a week.
