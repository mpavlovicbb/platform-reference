# Playbook: Jenkins to GitHub Actions

Written from the general pattern of a migration I ran without stopping the
release train; shape real, specifics generic.

## Drivers, and the decision

The real driver is rarely Jenkins itself — it is the Jenkins *instance*:
years of plugin archaeology, a single stateful server everyone fears
upgrading, and pipeline logic that lives half in Jenkinsfiles and half in
UI configuration nobody can diff. GitHub Actions trades that for
config-in-repo, managed orchestration, and an ecosystem — at the price of
per-minute billing (or self-hosted runner ops) and a vendor coupling
Jenkins never had. <<REVIEW: your real pipeline/job count band and what
finally forced the decision.>>

## Inventory and discovery

Export every job and classify ruthlessly: freestyle UI jobs (highest risk —
their logic exists nowhere in git), Jenkinsfiles using shared libraries,
and jobs nobody has run in six months (delete, do not migrate — a
migration is the best deletion opportunity the estate will ever get).
Inventory the invisible dependencies: credentials in the Jenkins store,
tools baked into agent AMIs/images over the years, jobs keyed to specific
agent labels, and cron triggers whose downstream consumers nobody
remembers. The shared library is its own workstream: map every function to
its consumers before writing its replacement.

## Parity strategy

Shared libraries become reusable workflows and composite actions — but
translate *interfaces*, not line-by-line internals: a `buildAndPush()`
library call becomes a reusable workflow with typed inputs, and this is
the moment to fix the interface sins the library accreted.
Freestyle jobs get rewritten from observed behaviour (their config XML is
documentation of intent, not implementation to port). Credentials move
from the Jenkins store to GitHub environments/secrets — and because
Actions has no per-stage credential scoping inside a job, some pipelines
need splitting into jobs to preserve least privilege.

## Runner topology and security

Decide early, it shapes everything: hosted runners for public/generic
work, self-hosted for anything needing network position, caches, or
special hardware. Self-hosted runners are the security heart of the
migration — never attach them to repositories that accept fork PRs,
run them ephemeral (fresh VM/container per job, actions-runner-controller
on the platform fits naturally), and scope runner groups per team rather
than one shared pool, or you have rebuilt the shared-mutable-Jenkins-agent
problem with a new logo. Pin third-party actions to commit SHAs from day
one; the marketplace is the new plugin directory, with the same trust
problem.

## Cutover mechanics

Per-repository, gated on parity: the Actions workflow runs in parallel
(on push, but not yet the deploy gate) until it has produced identical
artifacts/results for a bounded period, then branch protection flips the
required check from the Jenkins webhook status to the Actions check, then
the Jenkins job is disabled (not deleted) for one release cycle.
Deploy-triggering jobs cut over last and one at a time.

## Rollback

The disabled Jenkins job is the rollback: re-enable, flip the required
status check back. Keep the Jenkins server alive but frozen (no new jobs
accepted) until the last required check has been flipped for a full cycle
— the graveyard period is what makes per-repo rollback credible.

## Pitfalls that cost real time

What does not translate cleanly, learned the slow way: long-lived
workspace assumptions (Jenkins agents accumulated state between builds;
Actions runners start clean — builds that "worked" were depending on
leftovers), caching (a real design problem in Actions — cache keys,
scope, and 10 GB limits — where Jenkins just had a disk), cron-heavy
estates (schedule triggers on default branch only, delayed under load),
matrix/fan-in patterns (Jenkins parallel with join logic needs rethinking
as job dependencies), and log/artifact retention differences that
surprise auditors. Budget real time for the two or three pipelines that
are secretly load-bearing for another team.

## Timeline shape

A quarter-scale effort for hundreds of jobs, front-loaded on the shared
library rewrite, then a long steady per-repo middle that parallelizes
across teams, then the graveyard tail. The last five percent of jobs take
a quarter of the time. <<REVIEW: real numbers band.>>

## How you know it is done

Branch protection on every active repo requires only Actions checks; the
Jenkins server has been down for a month and the only people who noticed
were the ones decommissioning it; and the first new service onboarded
post-migration got CI by copying a reusable workflow, not by asking
anyone.
