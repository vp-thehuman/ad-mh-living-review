# 07_publication_bias.R ---------------------------------------------------
# Funnel plot, Egger's regression test (k>=10), and trim-and-fill
# sensitivity analysis (protocol §22 + §16 of PRISMA-P).

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

fits <- load_fits(cfg)
egger_rows <- list()

for (o in names(fits)) {
  m <- fits[[o]]

  # Funnel plot
  png_path <- file.path(cfg$fig_dir, sprintf("funnel_%s.png", o))
  png(png_path, width = 900, height = 700, res = 130)
  metafor::funnel(m, atransf = exp,
                  at = log(c(0.5, 1, 2, 4)),
                  xlab = sprintf("Odds ratio — %s", o),
                  main = sprintf("Funnel plot, %s (k = %d)", o, m$k))
  if (cfg$is_seed_data) {
    mtext("SEED DATA — DO NOT CITE", side = 1, line = 4,
          col = "#d62728", font = 2)
  }
  dev.off()
  message("[pubbias] wrote ", png_path)

  # Egger's test (only when k >= 10 per protocol)
  egger <- if (m$k >= 10) {
    e <- metafor::regtest(m, model = "rma", predictor = "sei")
    list(z = e$zval, p = e$pval, run = TRUE)
  } else {
    list(z = NA_real_, p = NA_real_, run = FALSE)
  }

  # Trim-and-fill (sensitivity)
  tnf <- tryCatch(metafor::trimfill(m), error = function(e) NULL)
  tnf_OR <- if (!is.null(tnf)) exp(tnf$b[[1]]) else NA_real_
  tnf_lo <- if (!is.null(tnf)) exp(tnf$ci.lb) else NA_real_
  tnf_hi <- if (!is.null(tnf)) exp(tnf$ci.ub) else NA_real_
  tnf_k0 <- if (!is.null(tnf)) tnf$k0 else NA_integer_

  egger_rows[[o]] <- tibble::tibble(
    outcome = o, k = m$k,
    egger_run = egger$run, egger_z = egger$z, egger_p = egger$p,
    trimfill_imputed = tnf_k0,
    trimfill_OR = tnf_OR,
    trimfill_lo = tnf_lo, trimfill_hi = tnf_hi)
}

bias_tbl <- dplyr::bind_rows(egger_rows)
readr::write_csv(bias_tbl, file.path(cfg$out_dir, "publication_bias.csv"))
print(bias_tbl)
