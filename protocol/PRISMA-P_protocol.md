# PRISMA-P 2015 / PRISMA-RR 2024 Protocol — Rapid Review

**Title:** A rapid living review with random-effects meta-analysis of the
association between atopic dermatitis and mental-health outcomes
(depression, anxiety, suicidality / self-harm) in adults.

**Version:** 2.0 (2026-05-06) — switched from full SR (v1.0) to rapid review.

---

## Why a rapid review

Amended to a **rapid review** following the Cochrane Rapid Reviews Methods
Group (Garritty et al. 2021) and Tricco et al. (2017), reported per
**PRISMA-RR** (Stevens et al. 2024). The change reflects single-reviewer
resourcing. Methodological streamlining is documented, justified, and
bounded by intra-rater reliability checks so residual error can be
quantified and disclosed.

## Streamlining (per Cochrane RR guidance)

| Step | Full SR standard | This rapid review | Mitigation |
|---|---|---|---|
| Title/abstract screen | Two reviewers, independent, blinded | One reviewer | Pre-screening calibration on a 50-record pilot batch (self-test against pre-specified eligibility); 20% of all records re-screened by the same reviewer after a ≥ 14-day washout for intra-rater reliability (target Cohen's κ ≥ 0.8). |
| Full-text screen | Two reviewers, independent | One reviewer | Decisions and reasons logged in `data/screening_log.csv`; 10% sample re-screened after washout. |
| Extraction | Two reviewers, independent, into duplicate forms | One reviewer | Self-verification pass against the PDF for high-risk items (effect estimate, CI, sample size, AD definition, outcome ascertainment) on every included study after a ≥ 7-day washout. |
| Risk of bias | Two reviewers, independent | One reviewer | 20% of studies re-rated after washout; intra-rater κ reported. |
| Search | Multi-database + grey + hand-search | PubMed + Embase + Cochrane CENTRAL + reference-list hand-search of all included studies; PsycINFO and grey literature limited to the top 3 most-cited reviews of AD–mental-health outcomes | Documented limitation; report any indirectness implications in GRADE. |

## Eligibility

Adults ≥ 18 years with AD by Hanifin-Rajka, UK Working Party criteria,
ICD-10 L20, or validated self-report; comparator = adults without AD;
outcomes = depression, anxiety, suicidality / self-harm by validated scale
or registry diagnosis. No language restriction. Database inception to most
recent automated pipeline run.

## Calibration

Before formal screening, the reviewer screens a **calibration batch** of
50 records against the pre-specified eligibility criteria, then re-screens
the same batch ≥ 14 days later blinded to the first decision. Intra-rater
κ ≥ 0.8 is required to begin formal screening. If κ < 0.8, the eligibility
guide is revised, the rationale is documented in `CHANGELOG.md`, and
calibration repeats.

## Validation-sample re-screening

A random 20% of the formal screening corpus is re-screened by the same
reviewer after a ≥ 14-day washout, blinded. Cohen's κ on this sample is
the headline reliability statistic for the review and is reported in the
PRISMA flow diagram footnote.

## Quantitative synthesis

Unchanged from v1.0: random-effects meta-analysis with REML τ², Hartung-
Knapp-Sidik-Jonkman CIs, prediction intervals, leave-one-out, influence
diagnostics, Egger + trim-and-fill (k ≥ 10), GRADE per outcome. Implemented
via `metafor::rma()` in R.

## Living-review operations

Unchanged: GitHub Actions cron on the 1st of every month re-runs PubMed
and Embase queries, deduplicates against the corpus, opens a screening
issue, re-pools and re-renders the site when extracted data changes, tags
releases with > 10% pooled-OR drift.

## GRADE implication

The rapid-review design and single-reviewer screening contribute one
downgrade level under "study limitations" in GRADE for each pooled outcome,
**unless** intra-rater validation κ ≥ 0.8 (almost-perfect agreement,
Landis & Koch 1977), in which case no downgrade is applied (per Garritty
2024 GRADE-rapid guidance).

## Disclosure

Methods, results, and limitations sections of the final manuscript will
prominently disclose:
- Single-reviewer design (rapid review) and the exact streamlining table.
- Calibration κ, validation-sample κ, and the washout interval used.
- All deviations from a full systematic review.

## References (rapid-review specific)

- Tricco AC et al. A scoping review of rapid review methods. *BMC Med* 2017;15:38.
- Garritty C et al. Cochrane Rapid Reviews Methods Group offers evidence-
  informed guidance to conduct rapid reviews. *J Clin Epidemiol* 2021;130:13–22.
- Stevens A et al. PRISMA-RR: an extension of PRISMA for rapid reviews. *J
  Clin Epidemiol* 2024 (in press).
- Landis JR, Koch GG. The measurement of observer agreement for categorical
  data. *Biometrics* 1977;33:159–74.
