# Security policy

This is a reference implementation intended for local and demonstration use. The
default configuration is deliberately open in places a production deployment must
not be (ArgoCD served without TLS on localhost, Vault in dev mode). Do not deploy
it to an internet-facing environment as-is.

## Reporting a vulnerability

If you find a vulnerability in this repository — a committed secret, an unsafe
default that is not documented as deliberate, a supply-chain issue — open a
GitHub security advisory on this repository or email milan.pavlovic@cumuluslab.io.
You will get a response within a week.
