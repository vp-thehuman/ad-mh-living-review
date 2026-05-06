# 03b_ai_extract.R ------------------------------------------------------
# For each fetched full text, ask Claude Haiku to extract effect estimates
# AND assign a draft ROBINS-E rating, returning structured JSON. Append
# proposed rows to data/extracted.csv (audit copy in data/ai_extracted_<date>.csv).

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(getwd(), "R", "utils_ai.R"))
ai_required()

if (!nzchar(Sys.getenv("ANTHROPIC_API_KEY", unset = ""))) {
  message("[ai-extract] ANTHROPIC_API_KEY not set; skipping.")
  quit(save = "no", status = 0)
}

log_files <- fs::dir_ls(cfg$data_dir, regexp = "fulltext_log_.*\\.csv$")
if (!length(log_files)) { message("[ai-extract] no fetch log."); quit(save="no", status=0) }
latest_log <- log_files[which.max(fs::file_info(log_files)$modification_time)]
fetched <- readr::read_csv(latest_log, show_col_types = FALSE) |>
  dplyr::filter(fetch_status == "fetched")
if (nrow(fetched) == 0) { message("[ai-extract] nothing fetched."); quit(save="no", status=0) }

read_text <- function(path) {
  if (grepl("\\.xml$", path)) {
    doc <- xml2::read_xml(path)
    paste(xml2::xml_text(xml2::xml_find_all(doc, "//body//p")), collapse = "\n")
  } else if (grepl("\\.pdf$", path)) {
    paste(pdftools::pdf_text(path), collapse = "\n")
  } else {
    readr::read_file(path)
  }
}

EXTRACT_SYS <- "You are a data-extraction assistant for a rapid systematic review on adult atopic dermatitis and mental-health outcomes (depression, anxiety, suicidality/self-harm).

For the supplied paper, extract one row per (outcome × effect estimate) reported. Return ONE JSON ARRAY where each element follows this schema EXACTLY:

{
  \"first_author\": \"<surname>\",
  \"year\": <integer>,
  \"country\": \"<country>\",
  \"region\": \"<Europe|Asia|Americas|Africa|Oceania|Mixed>\",
  \"design\": \"<cohort_prospective|cohort_retrospective|case_control|cross_sectional|rct|registry>\",
  \"setting\": \"<registry|primary_care|specialty_clinic|survey|claims|other>\",
  \"n_ad\": <integer or null>,
  \"n_control\": <integer or null>,
  \"mean_age\": <number or null>,
  \"pct_female\": <number or null>,
  \"ad_definition\": \"<ICD10_L20|Hanifin_Rajka|UK_working_party|self_report|clinical|claims_codes|other>\",
  \"ad_severity_mix\": \"<mild|moderate|severe|mild_moderate|moderate_severe|mixed|unspecified>\",
  \"outcome\": \"<depression|anxiety|suicidality>\",
  \"outcome_ascertainment\": \"<registry|PHQ9|BDI|CESD|HADS|GAD7|STAI|CSSRS|self_report|clinical_interview|other>\",
  \"incident_or_prevalent\": \"<incident|prevalent|unclear>\",
  \"effect_type\": \"<OR|RR|HR|SMD>\",
  \"effect_estimate\": <number>,
  \"ci_lower\": <number>,
  \"ci_upper\": <number>,
  \"covariates_adjusted\": \"<plus-separated list, e.g. age+sex+ses+atopy>\",
  \"funding\": \"<public|industry|mixed|none|unclear>\",
  \"rob_overall\": \"<Low|Some_concerns|High|Very_high>\",
  \"rob_rationale\": \"<one sentence per ROBINS-E domain that drove the rating>\",
  \"verbatim_quote\": \"<the exact sentence from the paper containing the effect estimate>\",
  \"confidence\": \"<high|medium|low>\",
  \"notes\": \"<short note on uncertainty if any>\"
}

If you cannot extract any rows, return [].

Critical rules:
- Use the FULLY ADJUSTED estimate when both unadjusted and adjusted are reported
- Use INCIDENT estimates over PREVALENT when both reported
- One row per (outcome × estimate)
- effect_estimate must be POSITIVE
- ci_lower < effect_estimate < ci_upper; if not, set confidence='low'
- Set confidence='low' if you had to infer values
- For ROBINS-E rob_overall, use the worst single-domain rating
- verbatim_quote must be an exact substring of the paper text"

extract_one <- function(pmid, title, full_text) {
  if (nchar(full_text) > 80000) full_text <- substr(full_text, 1, 80000)
  user <- sprintf("PMID: %s\nTitle: %s\n\nFull text:\n%s",
                  pmid %||% "?", title %||% "?", full_text)
  txt <- tryCatch(ai_call(EXTRACT_SYS, user, max_tokens = 4000),
                  error = function(e) "")
  parsed <- ai_extract_json(txt, "array")
  if (is.null(parsed)) return(list())
  parsed
}

template_cols <- names(readr::read_csv(
  file.path(cfg$data_dir, "extraction_template.csv"),
  show_col_types = FALSE))
extra_cols <- c("ai_verbatim_quote", "ai_confidence",
                "ai_rob_rationale",  "ai_pmid", "ai_extracted_date")
all_cols   <- c(template_cols, extra_cols)

new_rows <- list()
for (i in seq_len(nrow(fetched))) {
  rec  <- fetched[i, ]
  text <- tryCatch(read_text(rec$fetch_path), error = function(e) "")
  if (!nzchar(text)) {
    message(sprintf("[ai-extract] %3d/%d FAILED to read %s",
                    i, nrow(fetched), basename(rec$fetch_path))); next
  }
  rows <- extract_one(rec$pmid, rec$title, text)
  if (length(rows) == 0) {
    message(sprintf("[ai-extract] %3d/%d %s — no rows extracted",
                    i, nrow(fetched), substr(rec$title, 1, 50))); next
  }
  for (j in seq_along(rows)) {
    r <- rows[[j]]
    r$study_id <- sprintf("AI_%s_%d", as.character(rec$pmid) %||% sprintf("rec%d", i), j)
    r$notes    <- paste0("AI-extracted from ", rec$fetch_source %||% "?",
                         "; ", as.character(r$notes %||% ""))
    r$ai_verbatim_quote  <- as.character(r$verbatim_quote %||% NA)
    r$ai_confidence      <- as.character(r$confidence %||% NA)
    r$ai_rob_rationale   <- as.character(r$rob_rationale %||% NA)
    r$ai_pmid            <- as.character(rec$pmid %||% NA)
    r$ai_extracted_date  <- as.character(Sys.Date())
    r$verbatim_quote <- NULL; r$confidence <- NULL; r$rob_rationale <- NULL
    new_rows[[length(new_rows) + 1L]] <- r
  }
  message(sprintf("[ai-extract] %3d/%d %s — extracted %d row(s)",
                  i, nrow(fetched), substr(rec$title, 1, 50), length(rows)))
}

if (length(new_rows) == 0) {
  message("[ai-extract] no extractions to add."); quit(save="no", status=0)
}

to_df <- function(r) {
  out <- as.list(setNames(rep(NA, length(all_cols)), all_cols))
  for (k in names(r)) if (k %in% all_cols) out[[k]] <- r[[k]]
  as.data.frame(out, stringsAsFactors = FALSE)
}
extracted <- do.call(rbind, lapply(new_rows, to_df))

# Append to extracted.csv (or seed it if empty)
ex_path <- file.path(cfg$data_dir, "extracted.csv")
if (file.exists(ex_path)) {
  existing <- readr::read_csv(ex_path, show_col_types = FALSE)
  combined <- dplyr::bind_rows(existing, extracted)
} else {
  combined <- extracted
}
readr::write_csv(combined, ex_path)
audit <- file.path(cfg$data_dir, sprintf("ai_extracted_%s.csv", Sys.Date()))
readr::write_csv(extracted, audit)
message(sprintf("[ai-extract] appended %d row(s) to extracted.csv (total %d); audit: %s",
                nrow(extracted), nrow(combined), basename(audit)))
