# 10. Loki with Alloy collection, and explicit retention and cardinality budgets

Status: accepted. Date: 2026-07-29.

## Context

Logs needed the same treatment as metrics: an opinionated default with its
limits stated rather than discovered. The candidates were Loki,
Elasticsearch/OpenSearch, or a cloud logging service (excluded by ADR 1).

## Decision

Loki in single-binary mode with filesystem storage, fed by Alloy as a
DaemonSet tailing every pod. Elasticsearch was rejected for cost gravity:
full-text indexing of logs buys query power most platform debugging never
uses, at a resource multiple Loki's label-index-plus-grep model avoids.
Alloy over Promtail because it is Grafana's stated successor and one
collector can later carry traces and metrics through the same pipeline.

The budgets are explicit and enforced, not aspirational:

- **Retention: 24h**, enforced by the compactor (`retention_enabled` — a
  review pass caught the claim without the enforcement, and the PVC would
  have grown forever).
- **Cardinality: labels are a namespace, not a payload.** The Alloy relabel
  keeps `namespace`, `pod`, `container`, `app` and nothing else — no
  request IDs, no user IDs, nothing unbounded. High-cardinality data
  belongs in log *content*, greppable via LogQL, never in the stream index.
- **Ingest: sized for boot**, 16 MB/s with 32 MB burst, because first
  minutes after a fresh boot replay every pod's backlog at once and the
  4 MB/s default silently dropped batches (found the hard way).

## Consequences

Logs cost a fraction of metrics to run, the Grafana logs panel joins
metrics on one pane, and the demo's debug-logging workloads produce
honest stream volume the pipeline demonstrably absorbs.

## What we gave up

Full-text search speed on large ranges — LogQL grep over hours of logs is
brute force and feels like it. Single-binary Loki caps at one node's
throughput, and filesystem storage dies with the node: the cloud paths
swap to object storage and simple-scalable mode at exactly the seam the
environment overlays own. And 24h retention forecloses forensics; that
number is a laptop budget, not a recommendation.
