# 05_subgroups.R ----------------------------------------------------------
# Pre-specified subgroup meta-analyses + meta-regression (protocol §22).
# Subgroups: age stratum, AD severity, sex (where possible), region,
# outcome ascertainment, study design.

`%||%` <- function(a, b) if (is.null(a)) b else a

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

d <- read_studies(cfg)

age_band <- function(x) dplyr::case_when(
  x < 40 ~ "18-39",
  x < 65 ~ "40-64",
  TRUE   ~ ">=65")
d$age_band <- age_band(d$mean_age)

subgroup_vars <- c("age_band", "ad_severity_mix", "region",
                   "outcome_ascertainment", "design")

run_subgroup <- function(slice, mod) {
  slice <- dplyr::filter(slice, !is.na(.data[[mod]]))
  k_per_level <- table(slice[[mod]])
  if (any(k_per_level < 2)) {
    return(NULL)  # not enough studies in some level for stable estimate
  }
  metafor::rma(
    yi = slice$yi, vi = slice$vi,
    mods = stats::as.formula(sprintf("~ factor(%s)", mod)),
    method = cfg$tau2_method, test = cfg$ci_method,
    slab = study_label(slice))
}

results <- list()
for (o in cfg$outcomes) {
  slice <- dplyr::filter(d, outcome == o)
  if (nrow(slice) < 4) next
  for (m in subgroup_vars) {
    fit <- tryCatch(run_subgroup(slice, m), error = function(e) NULL)
    if (is.null(fit)) next
    results[[paste(o, m, sep = "::")]] <- fit
  }
}

# Tidy table -----------------------------------------------------------------
tidy_subgroup <- function(fit, key) {
  parts <- strsplit(key, "::", fixed = TRUE)[[1]]
  outcome <- parts[1]; modname <- parts[2]
  coef <- coef(fit)
  ci   <- confint(fit)$fixed
  tibble::tibble(
    outcome     = outcome,
    moderator   = modname,
    Q_moderator = fit$QM,
    Q_p         = fit$QMp,
    R2          = fit$R2 %||% NA_real_,
    k           = fit$k
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a

if (length(results)) {
  tbl <- purrr::imap_dfr(results, tidy_subgroup)
  readr::write_csv(tbl, file.path(cfg$out_dir, "subgroup_summary.csv"))
  message(sprintf("[subgroups] %d subgroup models fit.", nrow(tbl)))
} else {
  message("[subgroups] no subgroup model had enough studies in each level.")
  # Write an empty file so downstream readers don't crash.
  readr::write_csv(
    tibble::tibble(outcome = character(), moderator = character(),
                   Q_moderator = double(), Q_p = double(),
                   R2 = double(), k = integer()),
    file.path(cfg$out_dir, "subgroup_summary.csv"))
}

# Continuous meta-regression: mean age, % female -----------------------------
metareg <- list()
for (o in cfg$outcomes) {
  slice <- dplyr::filter(d, outcome == o, !is.na(mean_age), !is.na(pct_female))
  if (nrow(slice) >= 10) {
    metareg[[o]] <- metafor::rma(
      yi = slice$yi, vi = slice$vi,
      mods = ~ mean_age + pct_female,
      method = cfg$tau2_method, test = cfg$ci_method,
      slab = study_label(slice))
  }
}
saveRDS(metareg, file.path(cfg$out_dir, "metareg_fits.rds"))
saveRDS(results, file.path(cfg$out_dir, "subgroup_fits.rds"))
