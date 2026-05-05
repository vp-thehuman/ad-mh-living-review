# 08_grade.R --------------------------------------------------------------
# Mechanically derive a GRADE rating per outcome from the upstream artefacts.
# The reviewer team makes the final call — this script writes a *draft* that
# encodes the protocol's pre-specified rules so the human review starts from
# a defensible baseline rather than a blank page.

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

pooled  <- readr::read_csv(file.path(cfg$out_dir, "pooled_summary.csv"),
                           show_col_types = FALSE)
bias    <- readr::read_csv(file.path(cfg$out_dir, "publication_bias.csv"),
                           show_col_types = FALSE)
rob     <- readr::read_csv(file.path(cfg$out_dir, "rob_long.csv"),
                           show_col_types = FALSE)

start_grade <- function(design_mix) {
  # Observational evidence starts at LOW per GRADE (Schünemann 2013 §5.1).
  # If the body is dominated by RCTs, start at HIGH.
  if (any(stringr::str_detect(design_mix, "rct|randomi"))) "high" else "low"
}

# Look up the dominant design per outcome (from the cleaned studies file).
studies <- readr::read_csv(file.path(cfg$out_dir, "studies_clean.csv"),
                           show_col_types = FALSE)

draft <- pooled |>
  dplyr::rowwise() |>
  dplyr::mutate(
    starting = start_grade(
      paste(dplyr::filter(studies, outcome == .env$outcome)$design,
            collapse = "|")),
    rob_downgrade = {
      slice <- dplyr::filter(rob, outcome == .env$outcome,
                             domain == "overall")
      pct_high <- mean(slice$rating %in% c("High", "Very high"))
      if (pct_high >= 0.5) -1 else 0
    },
    inconsistency_downgrade = if (I2 > 75) -1 else 0,
    imprecision_downgrade   = if ((ci_hi / ci_lo) > 3) -1 else 0,
    pubbias_downgrade = {
      brow <- dplyr::filter(bias, outcome == .env$outcome)
      if (nrow(brow) && isTRUE(brow$egger_run) &&
          !is.na(brow$egger_p) && brow$egger_p < 0.10) -1 else 0
    },
    upgrade_large_effect = if (pooled_OR >= 2 || pooled_OR <= 0.5) +1 else 0
  ) |>
  dplyr::mutate(
    raw_score = dplyr::case_when(
      starting == "high" ~ 4,
      starting == "low"  ~ 2,
      TRUE               ~ 2),
    final_score = pmax(1, pmin(4,
      raw_score + rob_downgrade + inconsistency_downgrade +
      imprecision_downgrade + pubbias_downgrade + upgrade_large_effect)),
    certainty = c("very low", "low", "moderate", "high")[final_score]) |>
  dplyr::ungroup()

readr::write_csv(draft, file.path(cfg$out_dir, "grade_draft.csv"))
message("[grade] draft GRADE table written.")
print(dplyr::select(draft, outcome, starting, rob_downgrade,
                    inconsistency_downgrade, imprecision_downgrade,
                    pubbias_downgrade, upgrade_large_effect, certainty))
