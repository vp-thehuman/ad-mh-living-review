# `data/`

This directory holds the review's working data files.

## Files

| File | Purpose |
|---|---|
| `extraction_template.csv` | Empty template — the canonical column schema reviewers use during extraction. |
| `seed_studies.csv` | **Synthetic** seed dataset (12 rows) used to smoke-test the analysis pipeline. **Do not interpret as real evidence.** Replace with the real extracted dataset before any quantitative claim. |
| `extracted.csv` | Real, reviewer-extracted dataset (created during the review, currently absent). |
| `rob.csv` | ROBINS-E / RoB 2 ratings, long format. |
| `grade.csv` | GRADE rationale and certainty per outcome. |
| `screening_log.csv` | Audit trail of include/exclude decisions per record. |
| `raw_records_<date>.csv` | Raw exports from each pipeline run (PubMed + Embase). |

## Why a synthetic seed?

Until the real screening completes, the pipeline still needs *something* to
exercise: model fitting, plot rendering, GRADE rule firing, and the GitHub
Action's render step. The seed dataset provides that. The analysis pipeline
writes a watermark (`SEED DATA — DO NOT CITE`) onto every figure and table
when `seed_studies.csv` is the input, so any rendered Quarto site built
against the seed is unmistakable.
