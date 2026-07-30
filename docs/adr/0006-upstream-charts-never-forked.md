# 6. Upstream Helm charts with inline values, never forked

Status: accepted. Date: 2026-07-28.

## Context

Every platform component ships as an upstream Helm chart. The failure mode
that kills platforms slowly is the forked chart: patched once for a small
need, then permanently divergent, upgraded never.

## Decision

Charts are consumed from upstream repositories at exact pinned versions,
configured exclusively through values declared inline in each Application
(`valuesObject`). No forks, no vendored copies, no post-render patching.
Where a chart cannot express something we need, the answer is a separate
resource in `platform/core/` next to it (the ArgoCD local overrides and the
plain-manifest Vault deployment are both this pattern) — or upstreaming a
fix, never forking.

Kustomize overlays, which the original brief anticipated for environment
differences, are deliberately absent in v1: with a single live environment
they would be structure without content. They enter when a second real
environment does, as overlays over the same untouched upstream charts.

## Consequences

Renovate can bump every chart mechanically because nothing diverges;
upgrades are version-pin diffs with upstream changelogs, not merge
conflicts. The conftest policy enforcing exact chart pins keeps the floating
`targetRevision` class of drift out at review time. Where charts fell short,
the workarounds are visible, named files — not invisible patches.

## What we gave up

Expressiveness at the margins. Inline values cannot fix a chart's template
bug (the kyverno CRD empty-labels drift had to be absorbed with
ServerSideDiff instead of a one-line template patch a fork would have
allowed). The plain-manifest Vault deployment exists precisely because the
upstream chart's dev mode hardcodes a committed token — a fork would have
been three lines; our no-fork rule made it forty. And values-only
configuration means accepting each chart's opinion of what is configurable;
when that opinion is wrong, we wait on upstream or work around it in
adjacent manifests.
