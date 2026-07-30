# A platform that runs on any cloud — or none

One command boots a production-shaped internal developer platform — GitOps
delivery, policy enforcement, runtime secrets, gateway, metrics, logs, and
SLO alerting — on a laptop in under 8 minutes, measured. The same platform,
above one thin seam, targets Hetzner, AWS, or Azure.

![Architecture: cluster lifecycle, GitOps delivery, day-2 platform](assets/architecture.svg)

| Measured boot | Applications from one Git root | Decision records |
|:---:|:---:|:---:|
| 447 s to fully healthy | 21 | 15, each with "what we gave up" |

[Repository](https://github.com/mpavlovicbb/platform-reference){ .md-button .md-button--primary }
[Decision records](adr/index.md){ .md-button }
[Migration playbooks](playbooks/index.md){ .md-button }

## Why this exists

My production platform work lives in private employer repositories. This
reference makes that judgment publicly reviewable: the architecture is
real, every claim is measured or CI-enforced, and the decision records
say what each choice cost — not only what it bought. Every pull request
boots the entire platform from nothing before it may merge.

## Where to go

- **[Architecture](architecture/index.md)** — the three layers and the
  seams that make the cloud swappable
- **[Decision records](adr/index.md)** — fifteen choices, honestly costed
- **[Playbooks](playbooks/index.md)** — three production migrations,
  written from the general pattern
- **[The repository](https://github.com/mpavlovicbb/platform-reference)** —
  clone it, `make up`, try the guardrails
