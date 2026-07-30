# 5. App-of-apps root with ApplicationSets for tenants, not ApplicationSet-only

Status: accepted. Date: 2026-07-28.

## Context

Two topologies compete for the delivery root: a single app-of-apps
Application recursing over a directory of child Applications, or generating
everything from ApplicationSets. Some teams go all-in on the latter.

## Decision

Both, by role. Platform components are plain Application manifests under one
app-of-apps root: each component's file is its complete, reviewable delivery
contract — chart pin, values, sync policy, wave — and `git log` on that file
is the component's history. Tenants are an ApplicationSet with a git file
generator, because tenants are cattle by definition: they share one template
and differ only in the values a one-file onboarding supplies.

The dividing line is intent. Hand-curated things that differ from each other
get files; stamped-out things that must not differ get a generator.

## Consequences

The root stays diffable and boring — reviewing a platform change is reading
one YAML file, not evaluating a template in your head. Tenant onboarding is
one file (proven in PR #14), and the template enforces uniformity: labels,
enforcement scope, and sync policy cannot drift per tenant because no tenant
owns them. Sync waves order the platform layer; wave gating works because
the Application health check was restored (see ADR 4's consequences).

## What we gave up

Total uniformity and DRY. Twelve-plus platform Application files share
noticeable boilerplate — repoURL, destination, retry stanzas — that an
ApplicationSet-only design would collapse into one template. Every new
platform component is copy-adjust-review instead of add-one-generator-entry.
We also accepted two mental models where one could suffice, and a mild
inconsistency: tenants get `managedNamespaceMetadata`, platform namespaces
come from a dedicated app. The trade holds while the platform layer is
curated by hand; if component count triples, this ADR gets revisited.
