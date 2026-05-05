# 01_search.R -------------------------------------------------------------
# Re-execute the PubMed and Embase queries.  PubMed runs natively here via
# the NCBI E-utilities (no auth needed for low-volume use; an NCBI_API_KEY is
# honoured if present).  Embase requires institutional credentials, so this
# script stages the Ovid query for human dispatch and reads back the
# resulting .ris export from `data/raw_embase_<run>.ris`.
#
# Run from the repository root:  Rscript R/01_search.R

`%||%` <- function(a, b) if (is.null(a) || !nzchar(a)) b else a

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(cfg$repo_root, "R", "utils.R"))

if (!requireNamespace("rentrez", quietly = TRUE)) {
  install.packages("rentrez", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("xml2", quietly = TRUE)) {
  install.packages("xml2", repos = "https://cloud.r-project.org")
}

# Tiny PubMed XML parser (defined before its first call below) ----------------
parse_pubmed_xml <- function(xml_text) {
  doc <- xml2::read_xml(xml_text)
  arts <- xml2::xml_find_all(doc, ".//PubmedArticle")
  data.frame(
    pmid     = xml2::xml_text(xml2::xml_find_first(arts, ".//PMID")),
    title    = xml2::xml_text(xml2::xml_find_first(arts, ".//ArticleTitle")),
    abstract = xml2::xml_text(xml2::xml_find_first(arts, ".//Abstract")),
    journal  = xml2::xml_text(xml2::xml_find_first(arts, ".//Journal/Title")),
    year     = xml2::xml_text(xml2::xml_find_first(arts, ".//PubDate/Year")),
    doi      = xml2::xml_text(xml2::xml_find_first(arts,
                  ".//ArticleId[@IdType='doi']")),
    stringsAsFactors = FALSE
  )
}

run_date <- format(Sys.Date(), "%Y-%m-%d")
api_key  <- Sys.getenv("NCBI_API_KEY", unset = "")

pubmed_query <- readr::read_file(file.path(cfg$search_dir, "pubmed_query.txt"))
# Pull the final combined statement (the line beginning with "#5\n")
final_block  <- stringr::str_extract(
  pubmed_query, "(?ms)^#5\\s*\\n.*?(?=\\n#|\\Z)") |>
  stringr::str_remove("^#5\\s*\\n") |>
  stringr::str_replace_all("\\s+", " ") |>
  stringr::str_trim()

# Resolve the #1..#4 references inline (PubMed's history is session-scoped, so
# we expand them by walking back through the file).
expand_refs <- function(query, full) {
  for (n in 4:1) {
    block <- stringr::str_extract(
      full, sprintf("(?ms)^#%d\\s*\\n.*?(?=\\n#|\\Z)", n)) |>
      stringr::str_remove(sprintf("^#%d\\s*\\n", n)) |>
      stringr::str_replace_all("\\s+", " ") |>
      stringr::str_trim()
    query <- stringr::str_replace_all(
      query, sprintf("#%d", n), sprintf("(%s)", block))
  }
  query
}
expanded <- expand_refs(final_block, pubmed_query)

message("[search] PubMed query length: ", nchar(expanded), " chars")

if (nzchar(api_key)) rentrez::set_entrez_key(api_key)

pubmed_search <- tryCatch({
  rentrez::entrez_search(
    db = "pubmed", term = expanded, use_history = TRUE, retmax = 0)
}, error = function(e) {
  message("[search] PubMed call failed: ", conditionMessage(e))
  NULL
})

records <- if (!is.null(pubmed_search) && pubmed_search$count > 0) {
  total <- pubmed_search$count
  message(sprintf("[search] PubMed hits: %d", total))
  # Fetch in chunks of 500 to stay under E-utility limits.
  chunks <- split(seq_len(total), ceiling(seq_len(total) / 500))
  Reduce(rbind, lapply(chunks, function(idx) {
    xml <- rentrez::entrez_fetch(
      db = "pubmed", web_history = pubmed_search$web_history,
      rettype = "xml", retmode = "xml",
      retstart = min(idx) - 1, retmax = length(idx))
    parse_pubmed_xml(xml)
  }))
} else {
  data.frame()
}

# Embase staging --------------------------------------------------------------
embase_export <- file.path(cfg$data_dir, sprintf("raw_embase_%s.ris", run_date))
if (file.exists(embase_export)) {
  message("[search] Found Embase export: ", basename(embase_export))
  embase_records <- if (requireNamespace("revtools", quietly = TRUE)) {
    revtools::read_bibliography(embase_export) |> as.data.frame()
  } else {
    install.packages("revtools", repos = "https://cloud.r-project.org")
    revtools::read_bibliography(embase_export) |> as.data.frame()
  }
} else {
  message("[search] No Embase export staged for this run.")
  embase_records <- data.frame()
}

# Combine + write -------------------------------------------------------------
all_records <- dplyr::bind_rows(
  records  |> dplyr::mutate(source = "pubmed"),
  embase_records |> dplyr::mutate(source = "embase")
)

out_path <- file.path(cfg$data_dir, sprintf("raw_records_%s.csv", run_date))
readr::write_csv(all_records, out_path)
message("[search] wrote ", out_path, " (", nrow(all_records), " rows)")

# Append to update log --------------------------------------------------------
log_line <- sprintf(
  "| %s | %d | %d | %d | %d | (TBD) |\n",
  run_date,
  nrow(records),
  nrow(embase_records),
  nrow(all_records),  # dedup happens in 02_screen.R; placeholder for now
  nrow(all_records)
)
log_path <- file.path(cfg$search_dir, "update_log.md")
cat(log_line, file = log_path, append = TRUE)
message("[search] appended row to update_log.md")
