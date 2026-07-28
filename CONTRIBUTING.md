# Contributing

This repository is a reference implementation and a portfolio artifact. Issues and
pull requests are welcome, with that framing in mind: the goal is a small, reliable,
readable platform, not feature coverage.

## Ground rules

- One change per pull request.
- Conventional commit messages (`feat:`, `fix:`, `docs:`, `chore:`, with scope where
  it helps, e.g. `feat(observability): ...`).
- `pre-commit install` before your first commit; CI runs the same checks.
- Anything that changes what `make up` produces must keep the boot under the time
  budget stated in the README, and must leave every ArgoCD application Healthy.
- Significant design changes need an ADR in `docs/adr/` — see existing records for
  the format. An ADR without a "What we gave up" section will not be merged.
