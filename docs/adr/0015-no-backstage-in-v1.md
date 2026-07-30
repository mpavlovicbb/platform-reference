# 15. No Backstage in v1 — the golden path is ApplicationSets and one file

Status: accepted. Date: 2026-07-29.

## Context

"Internal developer platform" and "Backstage" have become nearly synonymous,
and the pressure to include a portal in anything calling itself an IDP is
real. This platform ships without one, and the reasoning deserves a record
because resisting that pressure was a decision, not an omission.

## Decision

The golden path is the ApplicationSet plus a one-file tenant contract, and
the portal surface is what already exists: the ArgoCD UI for delivery state
and Grafana for operational state. Backstage was evaluated and cut for v1
on three grounds. Weight: a Node.js monolith with a Postgres dependency and
its own plugin lifecycle would be the single heaviest component in the
platform, on a boot budget measured in seconds. Fit: Backstage's core value
— catalog, TechDocs, scaffolder templates — presumes an organization's
worth of services and teams; a reference with three tenants would be
demonstrating chrome, not capability. Honesty: a half-integrated portal
(catalog stubs, empty scorecards) reads as ambition; a one-file onboarding
that demonstrably works reads as engineering.

## Consequences

The onboarding contract is testable and tested (PR #14: one YAML file, full
tenant), the boot stays under budget, and the platform's complexity spends
where it differentiates — delivery, policy, observability. Developers get
task-focused UIs that already exist rather than a portal to maintain.

## What we gave up

Discoverability and the service catalog, which at real-organization scale
are not chrome at all: fifty teams cannot grep a repo to learn what exists,
who owns it, and whether it is healthy — that is precisely the problem
Backstage solves and one-file-in-git does not. We also gave up scaffolder
templates (our path onboards a *workload*, not a repository with CI and
ownership metadata) and the recruiting reality that "we run Backstage" is
itself a signal some organizations want. The roadmap keeps a portal as
future direction; the graduation trigger is the catalog problem becoming
real, not portal envy.
