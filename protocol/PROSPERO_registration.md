# PROSPERO Registration — Living Systematic Review

> Draft form aligned to the PROSPERO 2024 fields. Paste each section into the
> corresponding box on https://www.crd.york.ac.uk/prospero/ when submitting.

---

## 1. Review title
A living systematic review and random-effects meta-analysis of the association
between atopic dermatitis and mental-health outcomes (depression, anxiety, and
suicidality / self-harm) in adults.

## 2. Original language title
English.

## 3. Anticipated or actual start date
2026-05-01.

## 4. Anticipated completion date
First version: 2026-09-30. Subsequent updates: monthly via automated pipeline,
with formal annual re-publication.

## 5. Stage of review at time of submission
- Preliminary searches: **Yes — completed.**
- Piloting of the study selection process: **Yes — completed.**
- Formal screening of search results against eligibility criteria: **No — not started.**
- Data extraction: **No.**
- Risk-of-bias (quality) assessment: **No.**
- Data analysis: **No.**

## 6. Named contact / lead reviewer
Vish (vishish123@gmail.com). Replace with full name, ORCID, and affiliation
before submission.

## 7. Review team members and their organisational affiliations
TBD — list each reviewer with role (screener, extractor, RoB rater, statistician,
clinical adviser).

## 8. Funding sources / sponsors
None / self-funded (update if applicable).

## 9. Conflicts of interest
None declared.

## 10. Collaborators
None at registration.

## 11. Review question (PECO)

| | |
|---|---|
| **Population** | Adults (≥18 years) with a clinician-diagnosed or validated self-reported diagnosis of atopic dermatitis (atopic eczema). |
| **Exposure** | Presence of atopic dermatitis (any severity), compared with absence. Severity captured where reported (mild / moderate / severe via IGA, EASI, SCORAD, POEM, or self-rated). |
| **Comparator** | Adults without atopic dermatitis. |
| **Outcomes** | (1) Depression — incident or prevalent, by validated tool (PHQ-9, BDI, CES-D, HADS-D) or registry diagnosis (ICD-10 F32–F33). (2) Anxiety — GAD-7, HADS-A, STAI, or registry diagnosis (F40–F41). (3) Suicidality / self-harm — ideation, attempts, completed suicide, or self-harm presentation, by structured interview, validated scale (C-SSRS), or registry codes (X60–X84, ICD-10). |
| **Study designs** | Cohort (prospective and retrospective), case-control, and cross-sectional studies with an explicit non-AD comparator. RCTs included for any incidental mental-health outcome reporting. |

## 12. Searches
Databases: **PubMed (MEDLINE), Embase (Ovid), PsycINFO (EBSCO), CINAHL,
Cochrane CENTRAL, Web of Science Core Collection.**

Trial registers: **ClinicalTrials.gov, WHO ICTRP.**

Grey literature: **OpenGrey, ProQuest Dissertations & Theses, conference
abstracts (AAD, EADV, ISAD).**

Hand-searches: reference lists of all included studies and recent narrative reviews.

No language restrictions; non-English records translated using DeepL with
manual reviewer verification.

Date range: database inception to the run date of the latest automated pipeline.

Full search strategies are stored in `search/pubmed_query.txt` and
`search/embase_query.txt`. The living-update pipeline re-runs both queries on
the **1st of every month** (UTC) and appends a stamped delta to
`search/update_log.md`.

## 13. URL to search strategy
Will resolve to `https://github.com/USER/REPO/blob/main/search/pubmed_query.txt`
once the repository is public.

## 14. Condition or domain being studied
Atopic dermatitis (atopic eczema) — chronic relapsing inflammatory skin disease;
ICD-10 L20.

## 15. Participants / population
**Inclusion**: human adults aged ≥18 years; AD defined by Hanifin-Rajka,
UK Working Party, physician diagnosis (ICD-10 L20), or validated self-report.

**Exclusion**: pediatric-only cohorts; populations restricted to other dermatoses
(e.g., psoriasis-only, contact dermatitis-only) without a separable AD subgroup;
animal studies.

## 16. Intervention(s) / exposure(s)
Exposure of interest: presence of atopic dermatitis (any severity, any duration).
Severity is recorded as a moderator. Comorbid atopy (asthma, allergic rhinitis)
is recorded but does not exclude.

## 17. Comparator(s) / control
Adults without atopic dermatitis. Studies using general-population or
healthy-control comparators are eligible. Studies with only within-AD severity
comparisons (no AD-vs-non-AD contrast) contribute to severity meta-regression
only.

## 18. Main outcome(s)
(a) Depression — pooled OR/RR/HR for AD vs non-AD.
(b) Anxiety — pooled OR/RR/HR.
(c) Suicidality / self-harm — pooled OR/RR/HR for ideation, attempt, and
completed suicide reported separately.

For continuous symptom scores (e.g., PHQ-9 mean), pooled standardised mean
difference (SMD).

## 19. Additional outcome(s)
- Effect-size variation by AD severity (mild vs moderate vs severe).
- Sex-stratified effect sizes where reported.
- Interaction with comorbid atopic disease.
- Quality-of-life impact (DLQI, SF-36 mental component) — descriptive synthesis.

## 20. Data extraction (selection and coding)
Two reviewers screen titles/abstracts independently in **Rayyan**; disagreements
resolved by a third reviewer. Full-text screening uses the same dual-review
process. Data extracted in duplicate into `data/extracted.csv` per the template
in `data/extraction_template.csv`. Discrepancies reconciled by consensus.

## 21. Risk of bias (quality) assessment
**ROBINS-E** for non-randomised studies of exposures (cohort, case-control,
cross-sectional). **RoB 2** for any RCT contributing outcome data. Two
reviewers, independent. Domain-level and overall judgements stored in
`data/rob.csv`.

## 22. Strategy for data synthesis
Random-effects meta-analysis with restricted-maximum-likelihood (REML)
between-study variance estimation and **Hartung-Knapp-Sidik-Jonkman**
adjustment for confidence intervals. Implemented with `metafor::rma()` in R.
Pooled effects expressed as OR with 95 % CI; HRs and RRs harmonised to OR via
study-level baseline risk where appropriate, with a sensitivity analysis
restricted to studies reporting OR natively.

Heterogeneity quantified via τ², I², and 95 % prediction intervals.

Subgroup analyses (pre-specified):
1. Age stratum (18–39, 40–64, ≥65).
2. AD severity (mild / moderate / severe).
3. Sex.
4. World region (proxy for ethnicity / health-system context).
5. Outcome ascertainment (self-report scale vs registry diagnosis).
6. Study design (cohort vs cross-sectional vs case-control).

Meta-regression for continuous moderators (mean age, % female, mean AD duration).

Sensitivity analyses:
- **Leave-one-out** (`metafor::leave1out`).
- Restriction to low risk-of-bias studies.
- Restriction to studies with adjusted estimates (≥ age + sex).
- Restriction to incident (not prevalent) outcomes for depression and anxiety.

Publication bias assessed by funnel plot, **Egger's regression test** (when
≥ 10 studies per outcome), and trim-and-fill as a sensitivity check.

Certainty of evidence per outcome rated using **GRADE** with the `gradepro`
domain-level rationale stored in `data/grade.csv`.

## 23. Analysis of subgroups or subsets
See item 22.

## 24. Type and method of review
Systematic review with meta-analysis; **living** updating model with monthly
search re-execution and conditional re-analysis (re-pool when ≥ 1 newly
eligible study is admitted to any outcome).

## 25. Anticipated or actual start date
2026-05-01.

## 26. Anticipated completion date
First publication: 2026-09-30; living updates monthly thereafter.

## 27. Language
English.

## 28. Country
[To complete.]

## 29. Other registration details
None.

## 30. Reference / URL for published protocol
PRISMA-P protocol in `protocol/PRISMA-P_protocol.md`; will be deposited on OSF
on PROSPERO acceptance.

## 31. Dissemination plans
Open-access journal publication; Quarto site auto-deployed to GitHub Pages;
plain-language summary; data and code archived on Zenodo with DOI per release.

## 32. Keywords
atopic dermatitis; eczema; depression; anxiety; suicide; self-harm; meta-analysis;
living systematic review; mental health.

## 33. Details of any existing review of the same topic by the same authors
None.

## 34. Current review status
Ongoing.
