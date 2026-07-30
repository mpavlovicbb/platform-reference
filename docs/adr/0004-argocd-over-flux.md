# 4. ArgoCD over Flux

Status: accepted. Date: 2026-07-28.

## Context

Both ArgoCD and Flux are mature, CNCF-graduated GitOps engines; both would
run this platform correctly. Having operated both, the choice is about
operating texture, not capability.

## Decision

ArgoCD. Three reasons carried it. The UI is a genuine operational surface,
not a dashboard: the application tree, live diffs, and sync waves visible in
one place shorten every incident and every onboarding — and for a reference
repo meant to be *shown*, that legibility is doubly weighted. The
Application/ApplicationSet model maps directly onto the golden path (a git
file generator turning one tenant YAML into a full onboarding is a first-class
primitive, not an assembly). And health assessment as a core concept — apps
aggregate resource health, waves gate on it — gave the boot gate its
"Synced and Healthy or fail loudly" contract.

## Consequences

The whole delivery story is one root Application plus children, inspectable
at a glance. The costs showed up quickly and are documented in this repo's
history: the Application health check for app-of-apps had to be restored via
argocd-cm (removed upstream in 1.8), phantom drift on chart-rendered empty
maps needed per-app ServerSideDiff, and ArgoCD's repo-server lists refs with
go-git, which silently cannot speak git's dumb HTTP protocol — the e2e
design changed because of it.

## What we gave up

Flux's composability and lightness. Its controller-per-concern design
(source, kustomize, helm, notification) is cleaner engineering than ArgoCD's
monolith, its multi-tenancy story is more principled, its HelmRelease
handles upstream charts with less ceremony, and it consumes fewer resources
— which mattered on a laptop budget. We also gave up bootstrap symmetry:
`flux bootstrap` manages its own installation from git natively, where our
ArgoCD install is a pinned manifest applied by a script with local patches.
Teams already fluent in Flux lose nothing by staying; the migration playbook
in this repo exists precisely because switching is sometimes worth it and
sometimes is not.
