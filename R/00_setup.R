# 00_setup.R --------------------------------------------------------------
# Boots the analysis environment and creates a single shared `cfg` list used
# by every downstream script.  Sourcing this script is idempotent.

suppressPackageStartupMessages({
  required <- c("metafor", "dplyr", "tidyr", "readr", "stringr", "purrr",
                "ggplot2", "yaml", "jsonlite", "fs")
  missing  <- setdiff(required, rownames(installed.packages()))
  if (length(missing)) {
    install.packages(missing, repos = "https://cloud.r-project.org")
  }
  invisible(lapply(required, library, character.only = TRUE))
})

# Repository root resolution --------------------------------------------------
# Works whether the script is sourced from the repo root, the `R/` directory,
# or a GitHub Action runner — no reliance on the `here` package.
repo_root <- (function() {
  cands <- c(getwd(), normalizePath(file.path(getwd(), ".."),
                                    mustWork = FALSE))
  for (c in cands) if (file.exists(file.path(c, "DESCRIPTION"))) return(c)
  getwd()
})()

cfg <- list(
  repo_root      = repo_root,
  data_dir       = file.path(repo_root, "data"),
  fig_dir        = file.path(repo_root, "docs", "figures"),
  out_dir        = file.path(repo_root, "docs", "_generated"),
  search_dir     = file.path(repo_root, "search"),
  protocol_dir   = file.path(repo_root, "protocol"),
  # Which dataset to pool. Override with env var REVIEW_DATA=extracted.csv
  # in CI once real extraction begins.
  data_file      = Sys.getenv("REVIEW_DATA", "seed_studies.csv"),
  outcomes       = c("depression", "anxiety", "suicidality"),
  # Random-effects estimator and CI method.
  tau2_method    = "REML",
  ci_method      = "knha",
  alpha          = 0.05,
  # Threshold (relative change in pooled OR) for tagging a "material update"
  # release in the living-update workflow.
  material_delta = 0.10
)

dir.create(cfg$fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(cfg$out_dir, showWarnings = FALSE, recursive = TRUE)

is_seed_data <- identical(cfg$data_file, "seed_studies.csv")
if (is_seed_data) {
  message("[setup] Using SYNTHETIC seed dataset — figures will be watermarked.")
}

cfg$is_seed_data <- is_seed_data

invisible(cfg)
