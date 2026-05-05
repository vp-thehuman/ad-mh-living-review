# 04_meta_analysis.R ------------------------------------------------------
# Random-effects meta-analysis per outcome.
# REML τ² + Hartung-Knapp-Sidik-Jonkman CI per protocol §22.

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

d <- read_studies(cfg)

fit_outcome <- function(slice, label) {
  stopifnot(nrow(slice) >= 2)
  m <- metafor::rma(
    yi    = slice$yi,
    vi    = slice$vi,
    method = cfg$tau2_method,
    test   = cfg$ci_method,
    slab   = study_label(slice))
  attr(m, "outcome")  <- label
  attr(m, "n_studies") <- nrow(slice)
  m
}

fits <- lapply(cfg$outcomes, function(o) {
  slice <- dplyr::filter(d, outcome == o)
  if (nrow(slice) < 2) {
    message(sprintf("[meta] %s — k = %d, skipping pooled fit.",
                    o, nrow(slice)))
    return(NULL)
  }
  fit_outcome(slice, o)
})
names(fits) <- cfg$outcomes
fits <- Filter(Negate(is.null), fits)

# Tidy summary -----------------------------------------------------------------
summary_tbl <- purrr::imap_dfr(fits, function(m, o) {
  pi <- predict(m)  # prediction interval on log scale
  tibble::tibble(
    outcome   = o,
    k         = m$k,
    pooled_OR = exp(m$b[[1]]),
    ci_lo     = exp(m$ci.lb),
    ci_hi     = exp(m$ci.ub),
    pi_lo     = exp(pi$pi.lb),
    pi_hi     = exp(pi$pi.ub),
    tau2      = m$tau2,
    I2        = m$I2,
    H2        = m$H2,
    Q         = m$QE,
    Q_p       = m$QEp
  )
})

readr::write_csv(summary_tbl, file.path(cfg$out_dir, "pooled_summary.csv"))
save_fits(fits, cfg)

# Forest plots ----------------------------------------------------------------
for (o in names(fits)) {
  png_path <- file.path(cfg$fig_dir, sprintf("forest_%s.png", o))
  png(png_path, width = 1100, height = 600, res = 130)
  on.exit(dev.off(), add = TRUE)
  metafor::forest(
    fits[[o]],
    atransf = exp,
    at      = log(c(0.5, 1, 2, 4)),
    refline = 0,
    header  = c("Study, year (country)",
                sprintf("OR [95%% CI] — %s", o)),
    xlab    = sprintf("Odds ratio (AD vs non-AD), %s", o),
    mlab    = sprintf("RE pooled OR (REML, HKSJ; k = %d)", fits[[o]]$k))
  if (cfg$is_seed_data) {
    mtext("SEED DATA — DO NOT CITE", side = 1, line = 3,
          col = "#d62728", font = 2, cex = 1.1)
  }
  dev.off()
  message("[meta] wrote ", png_path)
}

print(summary_tbl)
