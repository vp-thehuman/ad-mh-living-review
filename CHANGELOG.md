# Changelog

All notable changes to this living review will be documented here.

## [0.1.0] — 2026-05-05

### Added
- Initial PRISMA-P 2015 protocol and PROSPERO registration draft.
- PubMed and Embase search strategies (PRESS-2015 peer-review pending).
- Risk-of-bias plan (ROBINS-E + RoB 2).
- R analysis pipeline `R/00_setup.R` → `R/08_grade.R`.
- Synthetic seed dataset (`data/seed_studies.csv`) for pipeline smoke tests;
  watermarks every figure produced from seed input.
- Quarto site under `docs/` with index, methods, results, forest plots, and
  GRADE summary pages.
- Monthly GitHub Action (`.github/workflows/monthly-update.yml`) — re-runs
  searches, opens screening issues, re-pools when extracted data changes,
  re-deploys the site, tags material updates.
- `renv.lock` + `DESCRIPTION` for reproducible R environment.
