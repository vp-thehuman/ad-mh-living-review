# 06_sensitivity.R --------------------------------------------------------
# Leave-one-out, influence diagnostics, and pre-specified subset re-fits
# (protocol §22 sensitivity).

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

d    <- read_studies(cfg)
fits <- load_fits(cfg)

l1o <- purrr::imap(fits, function(m, o) {
  loo <- metafor::leave1out(m)
  tibble::tibble(
    outcome  = o,
    omitted  = m$slab,
    pooled_OR = exp(loo$estimate),
    ci_lo    = exp(loo$ci.lb),
    ci_hi    = exp(loo$ci.ub),
    I2       = loo$I2,
    tau2     = loo$tau2)
}) |> dplyr::bind_rows()

readr::write_csv(l1o, file.path(cfg$out_dir, "leave1out.csv"))

# Influence diagnostics -------------------------------------------------------
infl <- purrr::imap(fits, function(m, o) {
  inf <- influence(m)
  tibble::tibble(
    outcome   = o,
    study     = m$slab,
    cooks_d   = inf$inf$cook.d,
    rstudent  = inf$inf$rstudent,
    dffits    = inf$inf$dffits,
    hat       = inf$inf$hat,
    is_outlier = inf$is.infl)
}) |> dplyr::bind_rows()

readr::write_csv(infl, file.path(cfg$out_dir, "influence.csv"))

# Pre-specified subset re-fits -----------------------------------------------
subset_fits <- list()
mk_subset <- function(slice, label) {
  if (nrow(slice) < 2) return(NULL)
  m <- metafor::rma(yi = slice$yi, vi = slice$vi,
                    method = cfg$tau2_method, test = cfg$ci_method,
                    slab = study_label(slice))
  attr(m, "subset") <- label
  m
}

for (o in cfg$outcomes) {
  slice <- dplyr::filter(d, outcome == o)
  subset_fits[[paste0(o, "::low_RoB")]] <- mk_subset(
    dplyr::filter(slice, rob_overall == "Low"), "low_RoB")
  subset_fits[[paste0(o, "::adjusted_min")]] <- mk_subset(
    dplyr::filter(slice, stringr::str_detect(covariates_adjusted, "age") &
                          stringr::str_detect(covariates_adjusted, "sex")),
    "adj_age_sex")
  subset_fits[[paste0(o, "::incident_only")]] <- mk_subset(
    dplyr::filter(slice, incident_or_prevalent == "incident"),
    "incident_only")
  subset_fits[[paste0(o, "::OR_native")]] <- mk_subset(
    dplyr::filter(slice, effect_type == "OR"), "OR_native")
}

subset_fits <- Filter(Negate(is.null), subset_fits)

subset_tbl <- purrr::imap_dfr(subset_fits, function(m, key) {
  parts <- strsplit(key, "::", fixed = TRUE)[[1]]
  tibble::tibble(
    outcome   = parts[1],
    subset    = parts[2],
    k         = m$k,
    pooled_OR = exp(m$b[[1]]),
    ci_lo     = exp(m$ci.lb),
    ci_hi     = exp(m$ci.ub),
    I2        = m$I2)
})

readr::write_csv(subset_tbl, file.path(cfg$out_dir, "subset_summary.csv"))
saveRDS(subset_fits, file.path(cfg$out_dir, "subset_fits.rds"))
message(sprintf("[sensitivity] leave-one-out: %d rows; subset fits: %d",
                nrow(l1o), length(subset_fits)))
