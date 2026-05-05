# _drift_check.R ----------------------------------------------------------
# Compare the freshly-pooled summary against the last cached version. Writes
# `material=true|false` to $GITHUB_OUTPUT for the calling step. A material
# update is defined per protocol §22 (cfg$material_delta) as a > 10 %
# relative change in any pooled OR.

new <- read.csv("docs/_generated/pooled_summary.csv")
old_path <- ".github/cache/pooled_summary_prev.csv"

if (file.exists(old_path)) {
  old <- read.csv(old_path)
  j <- merge(new, old, by = "outcome", suffixes = c("_new", "_old"))
  j$pct <- abs(j$pooled_OR_new - j$pooled_OR_old) / j$pooled_OR_old
  material <- isTRUE(any(j$pct > 0.10, na.rm = TRUE))
} else {
  material <- TRUE  # first run — always tag.
}

out <- Sys.getenv("GITHUB_OUTPUT", unset = "drift_output.txt")
cat(sprintf("material=%s\n", tolower(as.character(material))),
    file = out, append = TRUE)

dir.create(".github/cache", showWarnings = FALSE, recursive = TRUE)
file.copy("docs/_generated/pooled_summary.csv", old_path, overwrite = TRUE)

message(sprintf("[drift] material=%s", material))
