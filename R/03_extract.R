# 03_extract.R ------------------------------------------------------------
# Validate the extracted dataset against the protocol's schema, build the
# RoB summary, and emit a tidy long file the meta-analysis scripts consume.

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

required_cols <- names(readr::read_csv(
  file.path(cfg$data_dir, "extraction_template.csv"),
  show_col_types = FALSE))

d <- read_studies(cfg)

missing <- setdiff(required_cols, names(d))
if (length(missing)) {
  stop("[extract] missing required columns: ",
       paste(missing, collapse = ", "))
}

# Outcome-level sanity checks ------------------------------------------------
bad_outcomes <- setdiff(unique(d$outcome), cfg$outcomes)
if (length(bad_outcomes)) {
  warning("[extract] unknown outcomes present (will be dropped): ",
          paste(bad_outcomes, collapse = ", "))
  d <- dplyr::filter(d, outcome %in% cfg$outcomes)
}

stopifnot("All effect sizes must be positive (OR/RR/HR)" =
            all(d$effect_estimate > 0))
stopifnot("CI must contain the point estimate" =
            all(d$ci_lower <= d$effect_estimate &
                d$effect_estimate <= d$ci_upper))

# Build a tidy RoB summary if rob.csv exists; otherwise derive a placeholder
# from rob_overall in the extraction file.
rob_path <- file.path(cfg$data_dir, "rob.csv")
rob <- if (file.exists(rob_path)) {
  readr::read_csv(rob_path, show_col_types = FALSE)
} else {
  d |>
    dplyr::transmute(study_id, outcome,
                     domain = "overall",
                     rating = rob_overall)
}

readr::write_csv(rob, file.path(cfg$out_dir, "rob_long.csv"))
readr::write_csv(d,   file.path(cfg$out_dir, "studies_clean.csv"))
message(sprintf("[extract] %d studies × %d outcomes validated.",
                dplyr::n_distinct(d$study_id),
                dplyr::n_distinct(d$outcome)))
