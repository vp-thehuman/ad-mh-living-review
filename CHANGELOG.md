# Changelog

All notable changes to this living review are documented here.

## [0.2.0] — 2026-05-06

### Changed — methodology pivot
- **Switched from full systematic review to rapid living review** (Cochrane
  Rapid Reviews Methods Group; PRISMA-RR 2024). Single-reviewer design with
  intra-rater reliability validation.
- Calibration step (50-record dual-screen with ≥ 14-day washout, κ ≥ 0.8 to
  proceed) added.
- Validation-sample re-screening (20% of records, ≥ 14-day washout) added.
- GRADE downgrade for rapid-review design dropped if validation κ ≥ 0.8.

### Updated
- `protocol/PRISMA-P_protocol.md` — full rewrite as rapid review.
- `protocol/PROSPERO_registration.md` — registration fields updated.
- `docs/methods.qmd` — site reflects rapid-review design.
- `README.md` — top-line summary updated.

## [0.1.0] — 2026-05-05

### Added
- Initial PRISMA-P 2015 protocol and PROSPERO registration draft.
- PubMed and Embase search strategies.
- ROBINS-E + RoB 2 plan.
- R analysis pipeline (00–08).
- Synthetic seed dataset for pipeline smoke tests.
- Quarto site under `docs/`.
- Monthly GitHub Action.
- `renv.lock` + `DESCRIPTION` + `.gitignore` + MIT LICENSE.
