# Playbook: Flux to ArgoCD

Written from the general pattern of a consolidation I ran in production;
the shape is real, the specifics are deliberately generic. Read ADR 4
first — if Flux is working for you, this migration's best outcome may be
deciding not to run it.

## Drivers, and the decision

Legitimate drivers: consolidating mixed delivery tooling onto one engine
<<REVIEW: name the real mix you consolidated from — e.g. "Flux plus
hand-rolled helm pipelines plus kubectl-in-CI" — without employer detail>>,
the operational legibility of ArgoCD's UI for incident response and
onboarding, and ApplicationSet-driven tenancy. Illegitimate driver:
believing ArgoCD is "more GitOps." It is not; it is differently shaped.

## Inventory and discovery

Enumerate every Kustomization and HelmRelease with its source, interval,
health checks, and dependencies (`dependsOn` graphs especially — ArgoCD
sync waves are the nearest equivalent and the mapping is manual). Flag
everything using Flux-specific behaviour: postBuild variable substitution,
SOPS decryption in-controller, image update automation, and notification
providers. Each needs an explicit ArgoCD answer (respectively: values/
overlays, External Secrets or a decryption plugin, Image Updater or
Renovate-on-git, notifications controller) — none migrates for free.

## Parity strategy

Map repository-by-repository, not resource-by-resource: a Flux
Kustomization becomes an ArgoCD Application with the same source path, and
the Flux dependency graph becomes sync waves within an app-of-apps.
**Helm release ownership is the heart of the migration**: Flux's
helm-controller owns releases via Helm secrets metadata; ArgoCD does not
use `helm install` at all — it templates and applies. Adopting a live
release therefore means ArgoCD taking over resources that carry Flux/Helm
ownership metadata. The safe sequence per release: suspend the Flux
HelmRelease, create the ArgoCD Application against the same chart+values,
let it diff (expect labels/annotations churn), sync with ServerSideApply,
verify zero workload restarts, then delete the suspended HelmRelease and
eventually the Helm release secret.

## Running both controllers safely

Both can run cluster-wide during the migration if and only if ownership is
disjoint: Flux suspended on anything ArgoCD has adopted, ArgoCD's
auto-sync off on anything not yet adopted. The failure mode is both
reconciling one resource — a silent tug-of-war that manifests as flapping
replicas or reverting config. Prune is the sharp edge: ArgoCD prune stays
off per-application until that application's Flux ownership is fully
retired. <<REVIEW: if you hit a real tug-of-war incident, two sentences on
what flapped and how it was spotted make this section land.>>

## RBAC differences

Flux inherits Kubernetes RBAC per-controller and per-namespace; ArgoCD
introduces its own project/RBAC layer on top (AppProjects, policy CSV,
SSO group mappings). Teams that had namespace-scoped Flux need equivalent
AppProject boundaries — source repo allowlists, destination restrictions —
or the migration silently broadens who can deploy what.

## Rollback

Per-application and cheap by construction: the suspended HelmRelease is the
rollback — unsuspend it, remove the ArgoCD Application (non-cascading), and
Flux resumes. Retire that safety net only after an application has synced
cleanly through a real change, not just through adoption.

## Pitfalls that cost real time

Bootstrap ordering (ArgoCD must exist before it can manage anything,
including — if you go there — itself; decide explicitly whether ArgoCD
manages ArgoCD). Helm hooks behave differently (Flux runs them via Helm;
ArgoCD reinterprets them as its own hook system — test-hook and
post-install semantics shift). CRD ownership transfer produces enormous
server-side-apply diffs that look like disasters and are usually
`managedFields` churn. And drift you never knew about: Flux's default
intervals may have masked resources someone edited live months ago; ArgoCD
adoption surfaces all of it at once on day one.

## Timeline shape

Weeks per platform-sized estate, dominated not by the mechanics but by the
per-team walk-through of adopted releases: mechanics are days, trust is the
long pole. <<REVIEW: real span and release-count band.>>

## How you know it is done

The Flux controllers are scaled to zero for a full release cycle with no
one noticing; every Application has survived at least one real change (not
just adoption) through auto-sync; and the on-call runbook's "how do I see
what's deployed" answer references only one tool.
