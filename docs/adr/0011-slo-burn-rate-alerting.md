# 11. Multi-window burn-rate alerting on SLOs; static thresholds rejected

Status: accepted. Date: 2026-07-29.

## Context

The demo workload needed alerting that demonstrates practice worth copying.
The default everyone writes first — `error_rate > X for 5m` — pages on
blips, sleeps through slow bleeds, and encodes no opinion about how much
failure the service is allowed.

## Decision

An explicit SLO (99% availability over 30 days) with multi-window,
multi-burn-rate alerts in the SRE-workbook shape: page when the 5m and 1h
windows both burn budget at 14.4x (budget gone in under two days), warn
when 30m and 6h both burn at 6x. Recording rules compute the ratios;
alerts combine them; the thresholds appear as lines on the same dashboard
panel humans read, so alert logic and operator view cannot drift apart.

Static thresholds were rejected with reasons, not fashion: they alert on
symptoms without severity context (0.1% errors and 40% errors are the same
"above threshold"), the multi-window AND is what separates real burn from a
single bad scrape, and a threshold with no budget behind it cannot answer
"can we ship today?" — the question SLOs exist to answer.

## Consequences

The pipeline is verified end to end on every e2e: fault-injected traffic
trips `PodinfoErrorBudgetFastBurn` in Prometheus and lands in Alertmanager.
Alert volume is structurally low — two alerts per SLO, both meaning "the
budget is actually at risk," which is the entire point.

## What we gave up

Simplicity and coverage. Burn-rate machinery is four recording rules and
two alerts where a threshold is one line — teams without SLO literacy will
read it slower, and tuning burn multipliers is genuinely harder than
tuning a threshold. SLO alerting also only covers what has an SLO:
saturation, certificate expiry, and job failures still need conventional
alerts (kube-prometheus-stack's defaults carry that load here). And a
30-day window on a demo cluster is theatre in the small — the mechanism is
what the repo demonstrates, not the specific numbers.
