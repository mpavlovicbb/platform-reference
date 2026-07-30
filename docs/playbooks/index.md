# Migration playbooks

Three migrations I have run in production, written from the general
pattern — the drivers, mechanics, rollback design, and the pitfalls that
cost real time. No employer specifics; the shape of the work is the value.

- [Commercial APM to a self-hosted Grafana stack](apm-to-grafana-stack.md)
- [Flux to ArgoCD](flux-to-argocd.md)
- [Jenkins to GitHub Actions](jenkins-to-github-actions.md)

Each follows the same spine: drivers and the decision → inventory and
discovery → parity strategy → cutover mechanics → rollback → pitfalls →
timeline shape → how you know it is done.
