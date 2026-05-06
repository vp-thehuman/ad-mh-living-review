# 03a_fetch_fulltext.R --------------------------------------------------
# Try Europe PMC (XML) → Unpaywall (PDF) for every AI-include or AI-unsure
# record. Saves to data/fulltext/<pmid>.{xml,pdf} and writes a fetch log.

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(getwd(), "R", "utils_ai.R"))
ai_required()

email <- Sys.getenv("UNPAYWALL_EMAIL", unset = "")

ai_files <- fs::dir_ls(cfg$data_dir, regexp = "screening_queue_.*_ai\\.csv$")
if (!length(ai_files)) { message("[fetch] no AI queue."); quit(save="no", status=0) }
latest <- ai_files[which.max(fs::file_info(ai_files)$modification_time)]
queue  <- readr::read_csv(latest, show_col_types = FALSE)
to_fetch <- dplyr::filter(queue, ai_decision %in% c("include", "unsure"))
if (nrow(to_fetch) == 0) { message("[fetch] nothing to fetch."); quit(save="no", status=0) }

ft_dir <- file.path(cfg$data_dir, "fulltext")
dir.create(ft_dir, showWarnings = FALSE, recursive = TRUE)

fetch_pmcid <- function(pmid) {
  if (is.na(pmid) || !nzchar(pmid)) return(NULL)
  url <- sprintf("https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:%s+AND+SRC:MED&format=json&resultType=core", pmid)
  r <- tryCatch(httr2::req_perform(httr2::request(url)),
                error = function(e) NULL)
  if (is.null(r)) return(NULL)
  body <- httr2::resp_body_json(r)
  if (length(body$resultList$result) == 0) return(NULL)
  body$resultList$result[[1]]$pmcid %||% NULL
}

fetch_pmc_xml <- function(pmcid) {
  url <- sprintf("https://www.ebi.ac.uk/europepmc/webservices/rest/%s/fullTextXML", pmcid)
  r <- tryCatch(httr2::req_perform(httr2::request(url)),
                error = function(e) NULL)
  if (is.null(r) || httr2::resp_status(r) != 200) return(NULL)
  httr2::resp_body_string(r)
}

fetch_unpaywall <- function(doi) {
  if (!nzchar(email) || is.na(doi) || !nzchar(doi)) return(NULL)
  url <- sprintf("https://api.unpaywall.org/v2/%s?email=%s",
                 utils::URLencode(doi, reserved = TRUE), email)
  r <- tryCatch(httr2::req_perform(httr2::request(url)),
                error = function(e) NULL)
  if (is.null(r) || httr2::resp_status(r) != 200) return(NULL)
  body <- httr2::resp_body_json(r)
  loc  <- body$best_oa_location
  if (is.null(loc)) return(NULL)
  loc$url_for_pdf %||% loc$url
}

download_file <- function(url, dest) {
  r <- tryCatch(httr2::req_perform(httr2::request(url) |> httr2::req_timeout(60)),
                error = function(e) NULL)
  if (is.null(r) || httr2::resp_status(r) != 200) return(FALSE)
  writeBin(httr2::resp_body_raw(r), dest)
  TRUE
}

log_rows <- vector("list", nrow(to_fetch))
for (i in seq_len(nrow(to_fetch))) {
  rec <- to_fetch[i, ]
  pmid <- as.character(rec$pmid)
  doi  <- as.character(rec$doi)
  status <- "not_fetched"; src <- NA_character_; path <- NA_character_

  if (!is.na(pmid) && nzchar(pmid)) {
    pmcid <- fetch_pmcid(pmid)
    if (!is.null(pmcid) && nzchar(pmcid)) {
      xml <- fetch_pmc_xml(pmcid)
      if (!is.null(xml)) {
        path <- file.path(ft_dir, sprintf("%s.xml", pmid))
        writeLines(xml, path)
        status <- "fetched"; src <- "europe_pmc"
      }
    }
  }
  if (status == "not_fetched") {
    pdf_url <- fetch_unpaywall(doi)
    if (!is.null(pdf_url)) {
      stem <- if (!is.na(pmid) && nzchar(pmid)) pmid
              else gsub("[^A-Za-z0-9]", "_", doi)
      path <- file.path(ft_dir, sprintf("%s.pdf", stem))
      if (download_file(pdf_url, path)) {
        status <- "fetched"; src <- "unpaywall"
      } else {
        path <- NA_character_
      }
    }
  }

  log_rows[[i]] <- tibble::tibble(
    record_id = rec$record_id, pmid = pmid, doi = doi,
    title = rec$title, ai_decision = rec$ai_decision,
    fetch_status = status, fetch_source = src, fetch_path = path
  )
  message(sprintf("[fetch] %3d/%d %-12s %s", i, nrow(to_fetch), status,
                  substr(rec$title, 1, 60)))
}

log_df <- dplyr::bind_rows(log_rows)
log_path <- file.path(cfg$data_dir, sprintf("fulltext_log_%s.csv", Sys.Date()))
readr::write_csv(log_df, log_path)
n_fetched <- sum(log_df$fetch_status == "fetched")
message(sprintf("[fetch] %d/%d fetched, log: %s",
                n_fetched, nrow(log_df), basename(log_path)))
