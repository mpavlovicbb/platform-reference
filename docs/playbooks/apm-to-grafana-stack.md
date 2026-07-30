# Playbook: commercial APM to a self-hosted Grafana stack

Written from the general pattern of a migration I ran in production; every
step here is the shape of the work, none of it is any employer's specifics.

## Drivers, and the decision

The bill is the trigger but rarely the whole story: per-host or per-GB APM
pricing punishes exactly the growth you want (more services, more telemetry),
and the renewal negotiation is where the decision actually gets made.
<<REVIEW: insert the real cost delta band you're comfortable stating — even
"reduced observability spend by roughly half" transforms this page.>>
The honest counterweights, up front: you are trading a support contract and
a polished UX for storage operations and on-call ownership of the
observability stack itself. Make the decision with both columns filled in.

## Inventory and discovery

Before touching anything, enumerate what the APM actually provides today —
not what it could provide: every dashboard anyone opened in 90 days (usage
analytics, not opinions), every alert that fired in 180 days and who acted
on it, every language agent version in every service, and every place the
vendor's query language leaked into runbooks, wikis, and muscle memory.
The single most underestimated item is **alert semantics**: APM alerts
carry vendor-specific evaluation behaviour (rollups, recovery conditions,
flap suppression) that has no one-to-one Prometheus translation.

## Parity strategy

Parity means *decision parity*, not pixel parity: for each surviving
dashboard, what decision does it serve, and can the Grafana equivalent
serve the same decision? Rebuild golden-signals views first — they cover
most incident traffic. Cardinality is the trap on this leg: APM agents
happily emit per-URL and per-customer dimensions that Prometheus pricing
made free and Prometheus reality makes fatal.
<<REVIEW: your worst real cardinality incident belongs here — the metric,
the series count, what it did to memory.>>

## Dual-run and cutover

Run both systems on full traffic for a bounded period — weeks, not months;
an unbounded dual-run becomes the permanent state that doubles cost.
Alerts migrate one service at a time: new Prometheus alert fires alongside
the APM alert, a human confirms agreement over a real incident or a game
day, then the APM alert is muted (not deleted) one on-call rotation before
removal. De-duplicate pages at the Alertmanager/receiver layer during the
overlap, or the on-call experience of the migration is double-paging, and
goodwill dies fast.

## Rollback

Per-service and boring: agents stay installed but disabled for one renewal
cycle, dashboards stay exported, and the rollback act is re-enabling a
config flag — never a re-onboarding project. The point of rollback design
is that nobody hesitates to use it in week two, which is what makes the
migration safe enough to keep moving.

## Pitfalls that cost real time

Histogram semantics differ (APM percentiles are computed agent-side;
Prometheus quantiles come from bucket math — the same p99 will not match,
and someone will escalate that mismatch as an outage). Long-retention
comparisons break the day you cut over unless you plan remote-write or
accept the history loss out loud. The vendor query language embedded in
runbooks outlives the vendor by a year. And support burden lands unevenly:
the first "Grafana is down" incident is the moment the org discovers who
owns observability now.

## Timeline shape

Roughly: a quarter end to end for a mid-sized estate — discovery and stack
build-out in the first third, dual-run and service-by-service alert
migration in the middle, tail cleanup (runbooks, agent removal, contract
wind-down) in the last. The tail is longer than anyone budgets.
<<REVIEW: replace with your real span and service count band.>>

## How you know it is done

Not when the contract ends — when three things are true: an on-call
rotation has handled real incidents purely from the new stack without
opening the old one; the last APM agent is removed from the last deploy
manifest (verified by CI grep, not memory); and the first
capacity/retention decision on the new stack has been made deliberately,
which proves ownership actually transferred.
