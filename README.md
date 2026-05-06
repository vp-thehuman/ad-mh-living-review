# Atopic Dermatitis & Mental-Health Outcomes — Rapid Living Review

> **Design:** rapid review (Cochrane RR Methods Group; PRISMA-RR 2024). Single-reviewer with intra-rater reliability validation. See `protocol/PRISMA-P_protocol.md`.

[![Monthly Update](https://github.com/USER/REPO/actions/workflows/monthly-update.yml/badge.svg)](https://github.com/USER/REPO/actions/workflows/monthly-update.yml)
[![Quarto Site](https://img.shields.io/badge/site-quarto-blue)](https://USER.github.io/REPO/)
[![PROSPERO](https://img.shields.io/badge/PROSPERO-pending-lightgrey)](https://www.crd.york.ac.uk/prospero/)

A **living** systematic review and random-effects meta-analysis of the association between atopic dermatitis (AD) and mental-health outcomes (depression, anxiety, suicidality / self-harm) in adults (≥18 y).

The pipeline re-runs **every month** via GitHub Actions: it re-executes the PubMed and Embase queries, deduplicates against the corpus, flags new records for screening, re-fits the meta-analytic models when new eligible studies are admitted, and re-renders the Quarto site.

---

## Project structure

```
ad-mh-living-review/
├── protocol/                # PROSPERO + PRISMA-P + RoB plan
├── search/                  # PubMed / Embase queries + update log
├── R/                       # Analysis pipeline (00 → 08)
├── data/                    # Seed extraction CSV + extraction template
├── docs/                    # Quarto site (rendered to gh-pages)
├── .github/workflows/       # monthly-update.yml — the living engine
├── renv.lock                # Pinned R dependencies
└── DESCRIPTION              # R package-style metadata
```

## Quickstart

```bash
# 1. Restore the pinned R environment
Rscript -e "renv::restore()"

# 2. Run the full pipeline against the seed dataset
Rscript R/00_setup.R
Rscript R/04_meta_analysis.R
Rscript R/05_subgroups.R
Rscript R/06_sensitivity.R
Rscript R/07_publication_bias.R
Rscript R/08_grade.R

# 3. Render the Quarto site
quarto render docs/
```

## Methods at a glance

| Step | Tool | Output |
|---|---|---|
| Search | PubMed E-utilities + Embase via Ovid | `data/raw_records_<date>.csv` |
| Dedup & screen | `revtools` + `metagear` | `data/screening_log.csv` |
| Extraction | Manual → CSV against template | `data/extracted.csv` |
| Risk of bias | ROBINS-E (cohort/cross-sectional) | `data/rob.csv` |
| Pooling | `metafor::rma()` REML, Hartung-Knapp | Forest plots |
| Subgroups | Age stratum, AD severity, ethnicity, sex | Mixed-effects meta-regression |
| Sensitivity | `leave1out()`, influence diagnostics | Tables in site |
| Publication bias | Egger, funnel, trim-and-fill | Funnel plots |
| Certainty | GRADE per outcome | Summary-of-findings table |

## Pre-registration

Protocol registered on PROSPERO (registration # pending — see `protocol/PROSPERO_registration.md`). The protocol follows PRISMA-P 2015 and adheres to PRISMA 2020 for reporting.

## Citation

If you use this work, please cite the protocol DOI (issued on PROSPERO acceptance) and this repository.

## Pushing to GitHub

This repo is initialised on the `master` branch. To match the GitHub default
and the badges in this README:

```bash
git branch -m master main
git remote add origin git@github.com:USER/REPO.git
git push -u origin main
```

After the first push, enable GitHub Pages (Settings → Pages → Source: GitHub
Actions) and add an `NCBI_API_KEY` secret if you want higher PubMed rate
limits.

## License

Code: MIT. Text and figures: CC-BY-4.0.
