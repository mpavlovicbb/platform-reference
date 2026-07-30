# 14. Supply chain: what is signed, what is scanned, and what deliberately is not

Status: accepted. Date: 2026-07-29.

## Context

"Supply chain security" is a spectrum from secret hygiene to full SLSA
provenance. A reference implementation should state exactly where on that
spectrum it stands, because implying more than is real is itself a supply
chain failure.

## Decision

Covered, with teeth: secrets never in git (gitignore, pre-commit gitleaks,
full-history CI scan — three layers, all verified); every third-party
version pinned exactly — charts, images, CI actions to commit SHAs, CI tool
binaries, Terraform providers with committed lock files; Renovate raising
update PRs against those pins; trivy failing CI on HIGH/CRITICAL
misconfigurations with findings fixed at source; and every release shipping
a syft SPDX SBOM signed with cosign keyless (GitHub OIDC), verification
command published beside it. The cosign v3 bundle-format break on the first
release run was fixed through the PR flow — the history shows the machinery
being exercised, not just installed.

## Consequences

A consumer can verify what a release contains and that CI produced it; a
reviewer can trace every executable byte to a pin; dependency updates are
visible PRs rather than silent drift.

## What we gave up

The upper half of the spectrum, on purpose. No SLSA provenance attestations
— the SBOM says *what*, not *how it was built*. No container image signing
or admission-time signature verification: the only first-party image
(queue-worker) is built locally into a local registry, so there is no
registry trust boundary to enforce yet; Kyverno's verifyImages waits for
the day images ship. Base images and chart contents are pinned but not
vendored — availability still depends on upstream registries. And the boot
scripts fetch the pinned ArgoCD manifest from a mutable tag over TLS
(vendoring is issue #9). Each gap is a conscious line: this repo
demonstrates the discipline that scales to full provenance without claiming
to have arrived there.
