# 9. kube-prometheus-stack, and the scale where Mimir or Thanos becomes necessary

Status: accepted. Date: 2026-07-29.

## Context

Metrics needed an opinionated default. kube-prometheus-stack bundles
Prometheus, Alertmanager, exporters, dashboards, and the operator CRD model
(ServiceMonitor, PrometheusRule) that the rest of the platform builds on.
The looming question with any Prometheus is when a single instance stops
being enough.

## Decision

kube-prometheus-stack, single Prometheus, 24h local retention, with
selectors opened (`*SelectorNilUsesHelmValues: false`) so tenants bring
ServiceMonitors and rules without helm-label ceremony. Grafana admin
credentials are runtime-generated like every credential here; dashboards are
sidecar-provisioned from ConfigMaps in git — no hand-clicked state.

Mimir and Thanos are deliberately not installed, and the threshold for
revisiting is written down: a single well-resourced Prometheus comfortably
serves a few million active series and one cluster's HA pair with short
retention. Reach for Thanos/Mimir when any of these hold — multi-cluster
global query becomes a product requirement; retention beyond weeks matters
for capacity or compliance; active series push past the several-million
band and vertical scaling is exhausted; or teams need query isolation with
tenancy guarantees. None hold for a single-cluster reference.

## Consequences

One stateful component instead of six microservices; the operator CRDs give
tenants a paved road for scrape and alert config; the demo SLO machinery
(ADR 11) runs on plain PrometheusRules portable to any future backend.

## What we gave up

Durability and history. 24h retention means metrics die young, and a
Prometheus pod eviction loses in-flight state — acceptable locally,
disqualifying for production compliance. No global view: the moment a
second cluster exists, cross-cluster queries require exactly the Thanos
sidecar or remote-write-to-Mimir this ADR defers. And single-instance means
scrape gaps during restarts; the HA pair that fixes it doubles resource
cost, which the laptop budget declined to pay.
