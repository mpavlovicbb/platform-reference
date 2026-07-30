# 8. Gateway API via Envoy Gateway, not ingress-nginx

Status: accepted. Date: 2026-07-28.

## Context

ingress-nginx is the default answer for Kubernetes ingress and the one most
operators know. The Gateway API is its designed successor: role-separated
resources (GatewayClass for the platform, Gateway for the edge, HTTPRoute
for the tenant), expressive routing without annotation soup, and — after
ingress-nginx's 2025 retirement announcement — the clear long-term bet.

## Decision

Gateway API implemented by Envoy Gateway. One platform-owned Gateway is the
single north-south entrypoint; tenants attach HTTPRoutes from namespaces the
platform has labelled for gateway access (`allowedRoutes` selector — any
namespace claiming any hostname was a review finding, fixed). The
kind-specific data-plane shape (NodePort pinned to mapped host ports) lives
in one EnvoyProxy resource; cloud paths swap it for a LoadBalancer at that
same seam.

## Consequences

The role model matches the tenancy model: routes are tenant-space resources,
listeners are platform-space, and the boundary is enforced by the API
rather than convention. Envoy's config model surfaced real behaviour early —
a patched service port without a matching listener fails validation loudly,
and a stale namespace-label cache in the controller (issue #13) was found
and worked around because the e2e forces full boots.

## What we gave up

ingress-nginx's decade of operational folklore: every failure mode is a
search away, every team knows the annotations, and its raw simplicity
(one controller, one service) is genuinely easier to run than Envoy
Gateway's controller-plus-managed-data-plane pair. Gateway API's ecosystem
is younger — cert-manager's gateway solver, external-dns support, and
observability integrations all work but with fresher edges (the https
listener wiring is still an open issue here partly for that reason). For an
existing estate standardized on ingress-nginx annotations, migration is
real work with thin immediate payoff; this choice is for platforms being
built now, not a general instruction to move.
