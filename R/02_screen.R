# 02_screen.R -------------------------------------------------------------
# Deduplicate raw records against the running corpus and emit a screening
# queue.  Manual screening still happens in Rayyan; this script just packages
# the new candidates and updates `data/screening_log.csv`.

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

if (!requireNamespace("revtools", quietly = TRUE)) {
  install.packages("revtools", repos = "https://cloud.r-project.org")
}

# Load latest raw export ------------------------------------------------------
raw_files <- fs::dir_ls(cfg$data_dir, regexp = "raw_records_.*\\.csv$")
if (!length(raw_files)) {
  message("[screen] no raw records found — nothing to do.")
  quit(save = "no", status = 0)
}
latest_raw <- raw_files[which.max(fs::file_info(raw_files)$modification_time)]
new_records <- readr::read_csv(latest_raw, show_col_types = FALSE)

# Load the running screening log ---------------------------------------------
log_path <- file.path(cfg$data_dir, "screening_log.csv")
log_cols <- c("record_id", "pmid", "doi", "title", "decision",
              "decision_stage", "decision_date", "reviewer1", "reviewer2",
              "exclusion_reason")

corpus <- if (file.exists(log_path)) {
  readr::read_csv(log_path, show_col_types = FALSE)
} else {
  tibble::tibble(!!!setNames(rep(list(character()), length(log_cols)), log_cols))
}

# Dedup ----------------------------------------------------------------------
to_match <- new_records |>
  dplyr::transmute(
    record_id = dplyr::coalesce(pmid, doi, paste0("rec_",
                                                  dplyr::row_number())),
    pmid, doi, title)

new_only <- dplyr::anti_join(to_match, corpus, by = "record_id")
message(sprintf("[screen] %d new records (after dedup against %d in corpus)",
                nrow(new_only), nrow(corpus)))

# Append as 'pending' to the log ---------------------------------------------
queued <- new_only |>
  dplyr::mutate(
    decision = "pending",
    decision_stage = "title_abstract",
    decision_date = NA_character_,
    reviewer1 = NA_character_, reviewer2 = NA_character_,
    exclusion_reason = NA_character_)

readr::write_csv(
  dplyr::bind_rows(corpus, queued),
  log_path)

# Stage Rayyan-friendly export -----------------------------------------------
out_path <- file.path(cfg$data_dir,
                      sprintf("screening_queue_%s.csv", Sys.Date()))
readr::write_csv(new_only, out_path)
message("[screen] wrote ", out_path)
