# utils.R -----------------------------------------------------------------
# Small helpers shared across the pipeline.

#' Convert a reported effect estimate + CI to logOR + SE.
#'
#' Handles OR, RR, and HR. RR/HR are accepted as approximations of OR per the
#' protocol (item 22) when baseline event rate is low; a sensitivity analysis
#' restricted to OR-native studies is run elsewhere.
to_logOR <- function(estimate, lo, hi, type = c("OR", "RR", "HR")) {
  type <- match.arg(type)
  log_est <- log(estimate)
  log_se  <- (log(hi) - log(lo)) / (2 * stats::qnorm(0.975))
  list(yi = log_est, sei = log_se, type = type)
}

#' Watermark a ggplot when the pipeline is running on synthetic seed data.
seed_watermark <- function(p, is_seed = TRUE) {
  if (!is_seed) return(p)
  p + ggplot2::annotation_custom(
    grid::textGrob("SEED DATA — DO NOT CITE",
                   gp = grid::gpar(col = "#d62728", alpha = 0.20,
                                   cex = 2.4, fontface = "bold"),
                   rot = 30)
  )
}

#' Read the working dataset, lightly clean, attach yi/sei.
read_studies <- function(cfg) {
  path <- file.path(cfg$data_dir, cfg$data_file)
  if (!file.exists(path)) {
    stop(sprintf("[utils] dataset not found: %s", path))
  }
  d <- readr::read_csv(path, show_col_types = FALSE) |>
    dplyr::mutate(
      outcome = tolower(outcome),
      effect_type = toupper(effect_type)
    )
  es <- to_logOR(d$effect_estimate, d$ci_lower, d$ci_upper)
  d$yi  <- es$yi
  d$sei <- es$sei
  d$vi  <- es$sei^2
  d
}

#' Pretty label for a study row in forest plots.
study_label <- function(d) sprintf("%s, %d (%s)", d$first_author, d$year, d$country)

#' Save a list of model fits as RDS for downstream scripts.
save_fits <- function(fits, cfg, name = "rma_fits.rds") {
  saveRDS(fits, file.path(cfg$out_dir, name))
}

load_fits <- function(cfg, name = "rma_fits.rds") {
  readRDS(file.path(cfg$out_dir, name))
}
