# 02b_ai_screen.R --------------------------------------------------------
# AI second-screener for the rapid-review design. Sends each new record's
# title + abstract to Claude Haiku 4.5 with a structured prompt and writes
# its include / exclude / unsure verdict alongside the screening queue.
#
# No-op (clean exit) if ANTHROPIC_API_KEY is unset.

source(file.path(getwd(), "R", "00_setup.R"))
source(file.path(getwd(), "R", "utils_ai.R"))

if (!nzchar(Sys.getenv("ANTHROPIC_API_KEY", unset = ""))) {
  message("[ai-screen] ANTHROPIC_API_KEY not set; skipping.")
  quit(save = "no", status = 0)
}
ai_required()

queue_files <- fs::dir_ls(cfg$data_dir, regexp = "screening_queue_.*\\.csv$")
queue_files <- queue_files[!grepl("_ai\\.csv$", queue_files)]
if (!length(queue_files)) {
  message("[ai-screen] no screening queue."); quit(save = "no", status = 0)
}
latest <- queue_files[which.max(fs::file_info(queue_files)$modification_time)]
queue  <- readr::read_csv(latest, show_col_types = FALSE)
if (nrow(queue) == 0) { message("[ai-screen] empty queue."); quit(save = "no", status = 0) }

SYSTEM <- "You are an automated second-screener for a PROSPERO-registered rapid systematic review on the association between adult atopic dermatitis (AD; ICD-10 L20, atopic eczema) and three mental-health outcomes: depression, anxiety, suicidality/self-harm.

INCLUDE if ALL plausibly met:
1. Adult humans (>=18) or extractable adult subgroup
2. Atopic dermatitis as exposure (not psoriasis, contact dermatitis, etc.)
3. At least one of: depression, anxiety, suicidal ideation, suicide attempt, completed suicide, self-harm
4. Has comparator (non-AD or within-cohort exposed/unexposed)
5. Empirical research (cohort, case-control, cross-sectional, RCT, registry)

EXCLUDE if any:
- Pediatric only with no adult subgroup
- Not AD-specific
- No mental-health outcome
- Editorial/comment/letter
- Animal study

UNSURE if title+abstract insufficient.

Respond ONLY with one JSON object on one line, no prose:
{\"decision\": \"include\" | \"exclude\" | \"unsure\", \"reason\": \"<one short sentence>\"}"

results <- vector("list", nrow(queue))
for (i in seq_len(nrow(queue))) {
  Sys.sleep(0.1)
  ttl <- if ("title"    %in% names(queue)) as.character(queue$title[i])    else NA
  abs <- if ("abstract" %in% names(queue)) as.character(queue$abstract[i]) else NA
  user <- sprintf("Title: %s\n\nAbstract: %s",
                  ttl %||% "[no title]", abs %||% "[no abstract]")
  txt <- tryCatch(ai_call(SYSTEM, user, max_tokens = 200),
                  error = function(e) "")
  parsed <- ai_extract_json(txt, "object")
  if (is.list(parsed) && !is.null(parsed$decision)) {
    parsed$decision <- tolower(as.character(parsed$decision))
    if (!parsed$decision %in% c("include","exclude","unsure")) parsed$decision <- "unsure"
    results[[i]] <- parsed
  } else {
    results[[i]] <- list(decision = "unsure", reason = "parse error")
  }
  message(sprintf("[ai-screen] %3d/%d  %-7s  %s", i, nrow(queue),
                  results[[i]]$decision, substr(ttl %||% "", 1, 60)))
}

queue$ai_decision <- vapply(results, function(r) as.character(r$decision), character(1))
queue$ai_reason   <- vapply(results, function(r) as.character(r$reason),   character(1))

out <- sub("\\.csv$", "_ai.csv", latest)
readr::write_csv(queue, out)
tally <- table(queue$ai_decision)
message(sprintf("[ai-screen] wrote %s — include=%d exclude=%d unsure=%d (n=%d)",
        basename(out),
        tally["include"] %||% 0L,
        tally["exclude"] %||% 0L,
        tally["unsure"]  %||% 0L,
        nrow(queue)))
