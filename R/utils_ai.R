# utils_ai.R --------------------------------------------------------------
# Shared helpers for Anthropic API calls (Claude Haiku 4.5).

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.na(a[[1]])) return(b)
  if (is.character(a) && !nzchar(a[[1]])) return(b)
  a
}

ai_required <- function() {
  for (pkg in c("httr2", "jsonlite", "pdftools", "xml2")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  }
}

ai_call <- function(system_prompt, user_msg, max_tokens = 1500,
                    model = "claude-haiku-4-5-20251001") {
  api_key <- Sys.getenv("ANTHROPIC_API_KEY", unset = "")
  if (!nzchar(api_key)) stop("ANTHROPIC_API_KEY not set")
  body <- list(
    model      = model,
    max_tokens = max_tokens,
    system     = system_prompt,
    messages   = list(list(role = "user", content = user_msg))
  )
  resp <- httr2::request("https://api.anthropic.com/v1/messages") |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      `x-api-key`         = api_key,
      `anthropic-version` = "2023-06-01",
      `content-type`      = "application/json"
    ) |>
    httr2::req_body_json(body) |>
    httr2::req_retry(max_tries = 3, backoff = function(n) 2 ^ n) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  parsed <- httr2::resp_body_json(resp)
  parsed$content[[1]]$text
}

# Extract first complete JSON object or array from a string.
ai_extract_json <- function(txt, kind = c("object", "array")) {
  kind <- match.arg(kind)
  open_ch  <- if (kind == "object") "{" else "["
  close_ch <- if (kind == "object") "}" else "]"
  start <- regexpr(if (kind == "object") "\\{" else "\\[", txt)
  if (start <= 0) return(NULL)
  depth <- 0
  for (i in seq.int(start, nchar(txt))) {
    ch <- substr(txt, i, i)
    if (ch == open_ch)  depth <- depth + 1
    if (ch == close_ch) {
      depth <- depth - 1
      if (depth == 0) {
        json_str <- substr(txt, start, i)
        return(tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE),
                        error = function(e) NULL))
      }
    }
  }
  NULL
}
