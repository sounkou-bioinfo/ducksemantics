#' List supported HPO extraction harness modes
#'
#' Returns the named ablation modes discussed for hybrid FastHPOCR plus model
#' phenotyping experiments. The package directly implements the deterministic
#' candidate lane and a generic candidates-to-model adjudication wrapper; the
#' other modes can use the same schema and prompt contracts through project
#' specific model/tool runners.
#'
#' @return A data frame with `mode`, `flow`, and `question` columns.
#' @export
#' @examples
#' hpo_harness_modes()
hpo_harness_modes <- function() {
  data.frame(
    mode = c(
      "tool_only",
      "model_only",
      "model_tools_model",
      "model_candidates_tools_model",
      "candidates_model",
      "candidates_tools_model"
    ),
    flow = c(
      "note -> FastHPOCR -> HPO candidates",
      "note -> model -> HPO output",
      "note -> model -> ontology tools -> model final output",
      "note -> model -> candidates -> ontology tools -> model final output",
      "note + FastHPOCR candidates -> model keep/drop adjudication",
      "note + FastHPOCR candidates -> ontology tools -> model adjudication"
    ),
    question = c(
      "What is the deterministic FastHPOCR floor?",
      "Can the model extract and map HPO terms without grounding?",
      "Does ontology grounding fix model mapping errors?",
      "Does model-generated candidate expansion plus grounding improve recall?",
      "Does model cleanup fix FastHPOCR context noise cheaply?",
      "Does ontology validation after candidate generation add useful hygiene?"
    ),
    stringsAsFactors = FALSE
  )
}

#' Convert FastHPOCR annotations to a harness candidate table
#'
#' Standardizes annotations returned by [hpo_annotate()] into the candidate table
#' used by hybrid model-adjudication prompts and comparison harnesses. The HPO
#' identifier and label are preserved from FastHPOCR, while `candidate_id` gives
#' each row a stable handle for model keep/drop decisions.
#'
#' @param annotations A data frame or list returned by [hpo_annotate()].
#' @param case_id Character scalar identifying the source case. `NA` is allowed
#'   for ad hoc use, but real harness runs should pass a stable case id.
#' @param source Source label for the candidates.
#' @param run_id Optional run id to carry forward into joined outputs.
#' @return A data frame with one row per candidate and columns including
#'   `case_id`, `candidate_id`, `candidate_span`, `hpo_id`, `hpo_label`, and
#'   offset metadata.
#' @export
#' @examples
#' ann <- data.frame(
#'   span = "short stature",
#'   id = "HP:0004322",
#'   label = "Short stature",
#'   start = 1L,
#'   end = 13L,
#'   start_offset = 0L,
#'   end_offset = 13L,
#'   stringsAsFactors = FALSE
#' )
#' ann$categories <- I(list(list()))
#' hpo_candidate_table(ann, case_id = "case-1")
hpo_candidate_table <- function(annotations,
                                case_id = NA_character_,
                                source = "FastHPOCR",
                                run_id = NA_character_) {
  case_id <- optional_scalar_character(case_id, "case_id")
  source <- optional_scalar_character(source, "source")
  run_id <- optional_scalar_character(run_id, "run_id")

  records <- annotations_to_records(annotations)
  if (!length(records)) {
    return(empty_candidate_table())
  }

  n <- length(records)
  prefix <- if (is.na(case_id)) "candidate" else case_id
  candidate_id <- paste0(prefix, ":", sprintf("%04d", seq_len(n)))

  out <- data.frame(
    case_id = rep(case_id, n),
    run_id = rep(run_id, n),
    candidate_id = candidate_id,
    source = rep(source, n),
    source_rank = seq_len(n),
    candidate_span = vapply(records, `[[`, character(1), "span"),
    normalized_phrase = vapply(records, `[[`, character(1), "span"),
    hpo_id = vapply(records, `[[`, character(1), "id"),
    hpo_label = vapply(records, `[[`, character(1), "label"),
    start = vapply(records, function(x) {
      if (!is.null(x$start)) as.integer(x$start) else as.integer(x$start_offset) + 1L
    }, integer(1)),
    end = vapply(records, function(x) {
      if (!is.null(x$end)) as.integer(x$end) else as.integer(x$end_offset)
    }, integer(1)),
    start_offset = vapply(records, function(x) as.integer(x$start_offset), integer(1)),
    end_offset = vapply(records, function(x) as.integer(x$end_offset), integer(1)),
    stringsAsFactors = FALSE
  )
  out$categories <- I(lapply(records, `[[`, "categories"))
  out
}

#' Extract FastHPOCR candidate tables for one or more cases
#'
#' Loads or reuses a FastHPOCR annotator and runs [hpo_annotate()] once per input
#' text, returning a single comparison-friendly candidate table. This is the
#' package's `tool_only` harness lane.
#'
#' @param annotator A `fast_hpo_cr_annotator` returned by [hpo_annotator()], or
#'   a path to an index file.
#' @param text Character vector of case texts.
#' @param case_id Optional character vector of case identifiers. If omitted,
#'   `names(text)` are used when present, otherwise sequential identifiers are
#'   generated.
#' @param longest_match Passed to [hpo_annotate()].
#' @param source Source label for the candidate table.
#' @param run_id Optional run id to carry forward into candidate rows.
#' @return A candidate table as returned by `hpo_candidate_table()`.
#' @export
#' @examples
#' if (FALSE) {
#'   ann <- hpo_annotator("hp.index.gz")
#'   hpo_extract_candidates(
#'     ann,
#'     c(case1 = "Short stature and seizures were reported."),
#'     longest_match = TRUE
#'   )
#' }
hpo_extract_candidates <- function(annotator,
                                   text,
                                   case_id = NULL,
                                   longest_match = TRUE,
                                   source = "FastHPOCR",
                                   run_id = NA_character_) {
  if (!is.character(text) || anyNA(text)) {
    stop("`text` must be a character vector without missing values.", call. = FALSE)
  }
  check_flag(longest_match, "longest_match")

  if (is.null(case_id)) {
    case_id <- names(text)
    if (is.null(case_id) || any(!nzchar(case_id))) {
      case_id <- paste0("case-", sprintf("%04d", seq_along(text)))
    }
  }
  if (!is.character(case_id) || length(case_id) != length(text) || anyNA(case_id) || any(!nzchar(case_id))) {
    stop("`case_id` must be a non-missing character vector with the same length as `text`.", call. = FALSE)
  }

  rows <- lapply(seq_along(text), function(i) {
    hits <- hpo_annotate(
      annotator = annotator,
      text = text[[i]],
      longest_match = longest_match,
      output = "data.frame"
    )
    hpo_candidate_table(hits, case_id = case_id[[i]], source = source, run_id = run_id)
  })

  bind_rows_base(rows, empty_candidate_table())
}

#' JSON schema for model adjudication of HPO candidates
#'
#' Returns the structured output contract for the hybrid candidate-adjudication
#' step. Token usage and reasoning-token counts belong in run-level metadata;
#' clinical auditability comes from explicit `decision`, `evidence_span`, and
#' `short_reason` fields.
#'
#' @param as_json Return the schema as pretty JSON instead of an R list.
#' @param pretty Pretty-print JSON when `as_json = TRUE`.
#' @return An R list or JSON string containing a JSON Schema object.
#' @export
#' @examples
#' schema <- hpo_adjudication_schema()
#' names(schema)
hpo_adjudication_schema <- function(as_json = FALSE, pretty = TRUE) {
  check_flag(as_json, "as_json")
  check_flag(pretty, "pretty")

  schema <- list(
    "$schema" = "https://json-schema.org/draft/2020-12/schema",
    title = "RfastHPOCR HPO candidate adjudication",
    type = "object",
    additionalProperties = FALSE,
    required = c("case_id", "decisions"),
    properties = list(
      case_id = list(type = "string"),
      decisions = list(
        type = "array",
        items = list(
          type = "object",
          additionalProperties = FALSE,
          required = c(
            "candidate_id",
            "candidate_span",
            "normalized_phrase",
            "hpo_id",
            "hpo_label",
            "decision",
            "support_type",
            "patient_context",
            "evidence_span",
            "short_reason"
          ),
          properties = list(
            candidate_id = list(type = "string"),
            candidate_span = list(type = "string"),
            normalized_phrase = list(type = "string"),
            hpo_id = list(type = "string", pattern = "^HP:[0-9]{7}$"),
            hpo_label = list(type = "string"),
            decision = list(type = "string", enum = c("keep", "drop")),
            support_type = list(type = "string", enum = c("direct", "inferred", "none")),
            patient_context = list(
              type = "string",
              enum = c("patient", "family_history", "negated", "uncertain")
            ),
            evidence_span = list(type = "string"),
            short_reason = list(type = "string"),
            replacement_hpo_id = list(type = c("string", "null"), pattern = "^HP:[0-9]{7}$"),
            replacement_hpo_label = list(type = c("string", "null")),
            confidence = list(type = c("number", "null"), minimum = 0, maximum = 1)
          )
        )
      )
    )
  )

  if (isTRUE(as_json)) {
    require_jsonlite("hpo_adjudication_schema(as_json = TRUE)")
    return(jsonlite::toJSON(schema, auto_unbox = TRUE, pretty = pretty, null = "null"))
  }

  schema
}

#' Build a prompt for candidate-to-model HPO adjudication
#'
#' Creates the prompt for the practical hybrid arm:
#' `note + FastHPOCR candidates -> model keep/drop adjudication`. The model is
#' asked for auditable short fields, not hidden chain-of-thought.
#'
#' @param note Character scalar containing the source clinical text.
#' @param candidates Candidate table from `hpo_candidate_table()` or raw
#'   annotations from [hpo_annotate()].
#' @param case_id Optional case id. If omitted, it is inferred from the
#'   candidate table when possible.
#' @param allow_inferred If `TRUE`, the prompt allows candidate decisions to use
#'   `support_type = "inferred"` when clearly supported by the note. It still
#'   asks the model not to invent new HPO IDs.
#' @param prompt_version Version label embedded in the prompt.
#' @param extra_instructions Optional additional instruction text.
#' @return A single prompt string.
#' @export
#' @examples
#' ann <- data.frame(
#'   span = "seizures",
#'   id = "HP:0001250",
#'   label = "Seizure",
#'   start = 4L,
#'   end = 11L,
#'   start_offset = 3L,
#'   end_offset = 11L,
#'   stringsAsFactors = FALSE
#' )
#' ann$categories <- I(list(list()))
#' candidates <- hpo_candidate_table(ann, case_id = "case-1")
#' prompt <- hpo_adjudication_prompt("No seizures were reported.", candidates)
#' cat(substr(prompt, 1, 200))
hpo_adjudication_prompt <- function(note,
                                    candidates,
                                    case_id = NULL,
                                    allow_inferred = FALSE,
                                    prompt_version = "rfasthpocr-candidates-model-v1",
                                    extra_instructions = NULL) {
  check_scalar_character(note, "note")
  check_flag(allow_inferred, "allow_inferred")
  prompt_version <- optional_scalar_character(prompt_version, "prompt_version")
  if (!is.null(extra_instructions)) {
    check_scalar_character(extra_instructions, "extra_instructions")
  }

  case_id <- resolve_case_id(case_id, candidates, default = "case")
  candidates <- as_hpo_candidate_table(candidates, case_id = case_id)
  candidate_json <- candidates_to_prompt_json(candidates)
  schema_json <- hpo_adjudication_schema(as_json = TRUE, pretty = TRUE)

  inferred_instruction <- if (isTRUE(allow_inferred)) {
    paste(
      "You may mark support_type as 'inferred' only when the source text clearly supports the phenotype clinically.",
      "Do not add new HPO IDs; only adjudicate the supplied candidates."
    )
  } else {
    paste(
      "Use support_type = 'direct' for kept candidates directly stated in the note.",
      "Use support_type = 'none' for dropped candidates.",
      "Do not add inferred phenotypes or new HPO IDs in this mode."
    )
  }

  parts <- c(
    "You are adjudicating candidate Human Phenotype Ontology (HPO) extractions from de-identified clinical text.",
    "Return only valid JSON matching the schema. Do not include markdown fences or explanatory prose outside JSON.",
    "Do not provide hidden chain-of-thought. The clinical audit fields are decision, evidence_span, and short_reason.",
    "Reasoning-token counts, if available from the API, are run metadata and are not a clinical audit field.",
    "",
    paste0("Prompt version: ", prompt_version),
    paste0("Case id: ", case_id),
    "",
    "Decision rules:",
    "- Return exactly one decision for each supplied candidate_id.",
    "- decision = 'keep' only if the phenotype is present for the patient in the note.",
    "- decision = 'drop' if the mention is negated, family-history-only, uncertain/not established, not about the patient, too generic, duplicated by a more specific kept candidate, or unsupported.",
    "- patient_context must be one of: patient, family_history, negated, uncertain.",
    "- evidence_span should be the shortest exact quote from the note that supports the decision, including negation or family-history wording when relevant.",
    "- short_reason should be one concise sentence; do not include chain-of-thought.",
    "- If the supplied HPO term is wrong but a better HPO term is obvious from the same evidence, keep decision='drop' and fill replacement_hpo_id/replacement_hpo_label.",
    inferred_instruction,
    if (!is.null(extra_instructions)) paste0("Extra instructions: ", extra_instructions) else NULL,
    "",
    "JSON schema:",
    schema_json,
    "",
    "Source note:",
    note,
    "",
    "Candidate rows as JSON:",
    candidate_json
  )

  paste(parts, collapse = "\n")
}

#' Parse model adjudication JSON into a data frame
#'
#' Parses the structured JSON returned by the candidate adjudication prompt and
#' validates the core fields. If the original candidate table is supplied,
#' candidate offsets and source metadata are joined back for audit.
#'
#' @param x Character response, a `piknit`/Pi reply character vector, or a list
#'   with a `text`, `content`, or `reply` field.
#' @param candidates Optional candidate table used to join offsets and source
#'   metadata.
#' @return A data frame with one row per adjudicated candidate.
#' @export
#' @examples
#' json <- jsonlite::toJSON(
#'   list(
#'     case_id = "case-1",
#'     decisions = list(list(
#'       candidate_id = "case-1:0001",
#'       candidate_span = "seizures",
#'       normalized_phrase = "seizures",
#'       hpo_id = "HP:0001250",
#'       hpo_label = "Seizure",
#'       decision = "drop",
#'       support_type = "none",
#'       patient_context = "negated",
#'       evidence_span = "No seizures",
#'       short_reason = "The note explicitly negates seizures."
#'     ))
#'   ),
#'   auto_unbox = TRUE
#' )
#' hpo_parse_adjudication(json)
hpo_parse_adjudication <- function(x, candidates = NULL) {
  require_jsonlite("hpo_parse_adjudication()")
  text <- runner_response_text(x)
  json <- extract_json_object(text)
  parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  out <- parsed_adjudication_to_data_frame(parsed)
  if (!is.null(candidates)) {
    out <- join_candidate_metadata(out, as_hpo_candidate_table(candidates))
  }
  out
}

#' Run a candidates-to-model adjudication step
#'
#' Executes a generic model runner on the prompt produced by
#' `hpo_adjudication_prompt()`, parses the structured JSON response, and returns
#' run-level metadata suitable for provider/model comparisons. This function is
#' deliberately runner-agnostic: pass a function that calls `piknit::pi_run()`, a
#' local OpenAI-compatible endpoint, Ollama, vLLM, or any other provider.
#'
#' The returned `run_log` treats token counts and reasoning-token counts as API
#' usage metadata. The useful clinical audit fields remain in the term-level
#' adjudication table: `decision`, `evidence_span`, and `short_reason`.
#'
#' @param note Character scalar containing the source clinical text.
#' @param candidates Candidate table from `hpo_candidate_table()` or raw
#'   annotations from [hpo_annotate()].
#' @param runner Function taking a single prompt string and returning a character
#'   response. It may also return a list with `text` and `usage` fields, or a
#'   character vector with a `usage` attribute.
#' @param case_id Optional case id.
#' @param provider Provider label for the run log.
#' @param model Model label for the run log.
#' @param mode Harness mode label.
#' @param prompt_version Prompt version label.
#' @param tool_config Tool configuration label or list for the run log.
#' @param run_id Optional run id. Generated when omitted.
#' @param retry_count Retry count to record in the run log.
#' @param estimated_cost_usd Optional cost estimate.
#' @param error_on_failure If `TRUE`, runner or parse errors stop execution. If
#'   `FALSE`, errors are captured in the returned `run_log`.
#' @param ... Additional arguments passed to `hpo_adjudication_prompt()`.
#' @return A list with `prompt`, `raw_response`, `adjudication`, and `run_log`.
#' @export
#' @examples
#' ann <- data.frame(
#'   span = "seizures",
#'   id = "HP:0001250",
#'   label = "Seizure",
#'   start = 4L,
#'   end = 11L,
#'   start_offset = 3L,
#'   end_offset = 11L,
#'   stringsAsFactors = FALSE
#' )
#' ann$categories <- I(list(list()))
#' candidates <- hpo_candidate_table(ann, case_id = "case-1")
#' json <- jsonlite::toJSON(
#'   list(
#'     case_id = "case-1",
#'     decisions = list(list(
#'       candidate_id = "case-1:0001",
#'       candidate_span = "seizures",
#'       normalized_phrase = "seizures",
#'       hpo_id = "HP:0001250",
#'       hpo_label = "Seizure",
#'       decision = "drop",
#'       support_type = "none",
#'       patient_context = "negated",
#'       evidence_span = "No seizures",
#'       short_reason = "The note explicitly negates seizures."
#'     ))
#'   ),
#'   auto_unbox = TRUE
#' )
#' fixture_runner <- function(prompt) json
#' hpo_adjudicate_candidates("No seizures were reported.", candidates, fixture_runner)$adjudication
hpo_adjudicate_candidates <- function(note,
                                      candidates,
                                      runner,
                                      case_id = NULL,
                                      provider = NA_character_,
                                      model = NA_character_,
                                      mode = "candidates_model",
                                      prompt_version = "rfasthpocr-candidates-model-v1",
                                      tool_config = "none",
                                      run_id = NULL,
                                      retry_count = 0L,
                                      estimated_cost_usd = NA_real_,
                                      error_on_failure = TRUE,
                                      ...) {
  check_scalar_character(note, "note")
  if (!is.function(runner)) {
    stop("`runner` must be a function that accepts one prompt string.", call. = FALSE)
  }
  provider <- optional_scalar_character(provider, "provider")
  model <- optional_scalar_character(model, "model")
  mode <- optional_scalar_character(mode, "mode")
  prompt_version <- optional_scalar_character(prompt_version, "prompt_version")
  run_id <- optional_scalar_character(run_id, "run_id", default = new_hpo_run_id())
  if (!is.numeric(estimated_cost_usd) || length(estimated_cost_usd) != 1L) {
    stop("`estimated_cost_usd` must be a numeric scalar.", call. = FALSE)
  }
  check_flag(error_on_failure, "error_on_failure")

  case_id <- resolve_case_id(case_id, candidates, default = "case")
  candidates <- as_hpo_candidate_table(candidates, case_id = case_id)
  prompt <- hpo_adjudication_prompt(
    note = note,
    candidates = candidates,
    case_id = case_id,
    prompt_version = prompt_version,
    ...
  )

  started_at <- Sys.time()
  runner_error <- NULL
  response <- tryCatch(
    runner(prompt),
    error = function(e) {
      runner_error <<- e
      NULL
    }
  )
  ended_at <- Sys.time()
  latency_seconds <- as.numeric(difftime(ended_at, started_at, units = "secs"))

  if (!is.null(runner_error) && isTRUE(error_on_failure)) {
    stop(runner_error)
  }

  raw_response <- if (is.null(runner_error)) runner_response_text(response) else ""
  usage <- if (is.null(runner_error)) runner_response_usage(response) else list()

  parse_error <- NULL
  adjudication <- tryCatch(
    hpo_parse_adjudication(raw_response, candidates = candidates),
    error = function(e) {
      parse_error <<- e
      empty_adjudication_table()
    }
  )

  if (!is.null(parse_error) && isTRUE(error_on_failure)) {
    stop(parse_error)
  }

  run_log <- make_hpo_run_log(
    provider = provider,
    model = model,
    mode = mode,
    case_id = case_id,
    run_id = run_id,
    prompt_version = prompt_version,
    tool_config = tool_config,
    usage = usage,
    latency_seconds = latency_seconds,
    retry_count = retry_count,
    parse_success = is.null(runner_error) && is.null(parse_error),
    estimated_cost_usd = estimated_cost_usd,
    candidate_count = nrow(candidates),
    response_chars = nchar(raw_response, type = "chars"),
    error_message = if (!is.null(runner_error)) conditionMessage(runner_error) else if (!is.null(parse_error)) conditionMessage(parse_error) else NA_character_
  )

  list(
    prompt = prompt,
    raw_response = raw_response,
    adjudication = adjudication,
    run_log = run_log
  )
}

empty_candidate_table <- function() {
  out <- data.frame(
    case_id = character(),
    run_id = character(),
    candidate_id = character(),
    source = character(),
    source_rank = integer(),
    candidate_span = character(),
    normalized_phrase = character(),
    hpo_id = character(),
    hpo_label = character(),
    start = integer(),
    end = integer(),
    start_offset = integer(),
    end_offset = integer(),
    stringsAsFactors = FALSE
  )
  out$categories <- I(list())
  out
}

empty_adjudication_table <- function() {
  data.frame(
    case_id = character(),
    candidate_id = character(),
    candidate_span = character(),
    normalized_phrase = character(),
    hpo_id = character(),
    hpo_label = character(),
    decision = character(),
    support_type = character(),
    patient_context = character(),
    evidence_span = character(),
    short_reason = character(),
    replacement_hpo_id = character(),
    replacement_hpo_label = character(),
    confidence = numeric(),
    stringsAsFactors = FALSE
  )
}

optional_scalar_character <- function(x, arg, default = NA_character_) {
  if (is.null(x)) {
    return(default)
  }
  if (!is.character(x) || length(x) != 1L) {
    stop("`", arg, "` must be a character scalar.", call. = FALSE)
  }
  if (!is.na(x) && !nzchar(x)) {
    stop("`", arg, "` must not be empty.", call. = FALSE)
  }
  x
}

resolve_case_id <- function(case_id, candidates, default = "case") {
  case_id <- optional_scalar_character(case_id, "case_id", default = NA_character_)
  if (!is.na(case_id)) {
    return(case_id)
  }
  if (is.data.frame(candidates) && "case_id" %in% names(candidates)) {
    ids <- unique(stats::na.omit(as.character(candidates$case_id)))
    ids <- ids[nzchar(ids)]
    if (length(ids) == 1L) {
      return(ids[[1]])
    }
  }
  default
}

as_hpo_candidate_table <- function(candidates, case_id = NULL) {
  required <- c("candidate_id", "candidate_span", "hpo_id", "hpo_label")
  if (is.data.frame(candidates) && all(required %in% names(candidates))) {
    out <- candidates
    if (!"normalized_phrase" %in% names(out)) {
      out$normalized_phrase <- out$candidate_span
    }
    return(out)
  }
  hpo_candidate_table(candidates, case_id = optional_scalar_character(case_id, "case_id"))
}

candidates_to_prompt_json <- function(candidates) {
  require_jsonlite("hpo_adjudication_prompt()")
  cols <- c(
    "case_id",
    "candidate_id",
    "candidate_span",
    "normalized_phrase",
    "hpo_id",
    "hpo_label",
    "start_offset",
    "end_offset",
    "source"
  )
  cols <- intersect(cols, names(candidates))
  jsonlite::toJSON(
    candidates[, cols, drop = FALSE],
    dataframe = "rows",
    auto_unbox = TRUE,
    na = "null",
    pretty = TRUE
  )
}

require_jsonlite <- function(where) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(where, " requires the 'jsonlite' package.", call. = FALSE)
  }
  invisible(TRUE)
}

runner_response_text <- function(x) {
  if (is.null(x)) {
    return("")
  }
  if (is.list(x) && !is.data.frame(x)) {
    for (field in c("text", "content", "reply", "response")) {
      if (!is.null(x[[field]])) {
        return(runner_response_text(x[[field]]))
      }
    }
  }
  paste(as.character(x), collapse = "\n")
}

runner_response_usage <- function(x) {
  usage <- attr(x, "usage", exact = TRUE)
  if (is.null(usage) && is.list(x) && !is.data.frame(x)) {
    usage <- x$usage
  }
  if (is.null(usage)) {
    return(list())
  }
  usage
}

extract_json_object <- function(text) {
  check_scalar_character(text, "text")
  text <- trimws(text)
  text <- sub("^```[[:alpha:]]*\\s*", "", text)
  text <- sub("\\s*```$", "", text)
  start <- regexpr("\\{", text)[[1]]
  ends <- gregexpr("\\}", text)[[1]]
  if (start < 0L || identical(ends, -1L)) {
    stop("No JSON object found in model response.", call. = FALSE)
  }
  end <- utils::tail(ends, 1L)
  substr(text, start, end)
}

parsed_adjudication_to_data_frame <- function(parsed) {
  if (!is.list(parsed) || is.null(parsed$case_id) || is.null(parsed$decisions)) {
    stop("Adjudication JSON must contain `case_id` and `decisions`.", call. = FALSE)
  }
  case_id <- as.character(parsed$case_id)
  decisions <- parsed$decisions
  if (!length(decisions)) {
    return(empty_adjudication_table())
  }
  if (is.data.frame(decisions)) {
    decisions <- split(decisions, seq_len(nrow(decisions)))
  }

  required <- c(
    "candidate_id",
    "candidate_span",
    "normalized_phrase",
    "hpo_id",
    "hpo_label",
    "decision",
    "support_type",
    "patient_context",
    "evidence_span",
    "short_reason"
  )

  rows <- lapply(seq_along(decisions), function(i) {
    d <- decisions[[i]]
    missing <- setdiff(required, names(d))
    if (length(missing)) {
      stop(
        "Decision ", i, " is missing required field(s): ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
    list(
      case_id = case_id,
      candidate_id = field_chr(d, "candidate_id"),
      candidate_span = field_chr(d, "candidate_span"),
      normalized_phrase = field_chr(d, "normalized_phrase"),
      hpo_id = field_chr(d, "hpo_id"),
      hpo_label = field_chr(d, "hpo_label"),
      decision = field_chr(d, "decision"),
      support_type = field_chr(d, "support_type"),
      patient_context = field_chr(d, "patient_context"),
      evidence_span = field_chr(d, "evidence_span"),
      short_reason = field_chr(d, "short_reason"),
      replacement_hpo_id = field_chr(d, "replacement_hpo_id", NA_character_),
      replacement_hpo_label = field_chr(d, "replacement_hpo_label", NA_character_),
      confidence = field_num(d, "confidence", NA_real_)
    )
  })

  out <- data.frame(
    case_id = vapply(rows, `[[`, character(1), "case_id"),
    candidate_id = vapply(rows, `[[`, character(1), "candidate_id"),
    candidate_span = vapply(rows, `[[`, character(1), "candidate_span"),
    normalized_phrase = vapply(rows, `[[`, character(1), "normalized_phrase"),
    hpo_id = vapply(rows, `[[`, character(1), "hpo_id"),
    hpo_label = vapply(rows, `[[`, character(1), "hpo_label"),
    decision = vapply(rows, `[[`, character(1), "decision"),
    support_type = vapply(rows, `[[`, character(1), "support_type"),
    patient_context = vapply(rows, `[[`, character(1), "patient_context"),
    evidence_span = vapply(rows, `[[`, character(1), "evidence_span"),
    short_reason = vapply(rows, `[[`, character(1), "short_reason"),
    replacement_hpo_id = vapply(rows, `[[`, character(1), "replacement_hpo_id"),
    replacement_hpo_label = vapply(rows, `[[`, character(1), "replacement_hpo_label"),
    confidence = vapply(rows, `[[`, numeric(1), "confidence"),
    stringsAsFactors = FALSE
  )

  validate_adjudication_values(out)
  out
}

field_chr <- function(x, field, default = NULL) {
  value <- x[[field]]
  if (is.null(value) || length(value) == 0L) {
    if (is.null(default)) {
      stop("Missing field `", field, "`.", call. = FALSE)
    }
    return(default)
  }
  if (length(value) != 1L || is.na(value)) {
    if (is.null(default)) {
      stop("Field `", field, "` must be a non-missing scalar.", call. = FALSE)
    }
    return(default)
  }
  as.character(value)
}

field_num <- function(x, field, default = NA_real_) {
  value <- x[[field]]
  if (is.null(value) || length(value) == 0L || is.na(value)) {
    return(default)
  }
  if (length(value) != 1L) {
    stop("Field `", field, "` must be a scalar.", call. = FALSE)
  }
  as.numeric(value)
}

validate_adjudication_values <- function(out) {
  assert_enum(out$decision, c("keep", "drop"), "decision")
  assert_enum(out$support_type, c("direct", "inferred", "none"), "support_type")
  assert_enum(out$patient_context, c("patient", "family_history", "negated", "uncertain"), "patient_context")
  bad_hpo <- !grepl("^HP:[0-9]{7}$", out$hpo_id)
  if (any(bad_hpo)) {
    stop("Invalid HPO id(s): ", paste(unique(out$hpo_id[bad_hpo]), collapse = ", "), call. = FALSE)
  }
  invisible(out)
}

assert_enum <- function(x, allowed, field) {
  bad <- setdiff(unique(x), allowed)
  if (length(bad)) {
    stop("Invalid `", field, "` value(s): ", paste(bad, collapse = ", "), call. = FALSE)
  }
}

join_candidate_metadata <- function(out, candidates) {
  if (!nrow(out) || !nrow(candidates) || !"candidate_id" %in% names(candidates)) {
    return(out)
  }
  idx <- match(out$candidate_id, candidates$candidate_id)
  for (col in c("source", "source_rank", "start", "end", "start_offset", "end_offset", "run_id")) {
    if (col %in% names(candidates) && !col %in% names(out)) {
      out[[col]] <- candidates[[col]][idx]
    }
  }
  out
}

make_hpo_run_log <- function(provider,
                             model,
                             mode,
                             case_id,
                             run_id,
                             prompt_version,
                             tool_config,
                             usage,
                             latency_seconds,
                             retry_count,
                             parse_success,
                             estimated_cost_usd,
                             candidate_count,
                             response_chars,
                             error_message) {
  data.frame(
    provider = provider,
    model = model,
    mode = mode,
    case_id = case_id,
    run_id = run_id,
    prompt_version = prompt_version,
    tool_config = tool_config_to_string(tool_config),
    input_tokens = usage_number(usage, c("input_tokens", "prompt_tokens", "input")),
    output_tokens = usage_number(usage, c("output_tokens", "completion_tokens", "output")),
    total_tokens = usage_number(usage, c("total_tokens", "totalTokens", "total")),
    reasoning_tokens = usage_reasoning_tokens(usage),
    latency_seconds = latency_seconds,
    tool_call_count = usage_number(usage, c("tool_call_count")),
    tool_names_used = usage_character(usage, c("tool_names_used", "tool_names")),
    retry_count = as.integer(retry_count),
    parse_success = parse_success,
    estimated_cost_usd = if (is.na(estimated_cost_usd)) usage_cost_total(usage) else estimated_cost_usd,
    candidate_count = as.integer(candidate_count),
    response_chars = as.integer(response_chars),
    error_message = error_message,
    stringsAsFactors = FALSE
  )
}

tool_config_to_string <- function(x) {
  if (is.character(x) && length(x) == 1L) {
    return(x)
  }
  require_jsonlite("tool_config serialization")
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
}

usage_number <- function(usage, fields) {
  value <- usage_value(usage, fields)
  if (is.null(value) || length(value) == 0L || is.na(value)) {
    return(NA_real_)
  }
  as.numeric(value[[1]])
}

usage_character <- function(usage, fields) {
  value <- usage_value(usage, fields)
  if (is.null(value) || length(value) == 0L) {
    return(NA_character_)
  }
  if (length(value) > 1L) {
    return(paste(as.character(value), collapse = ","))
  }
  if (is.na(value)) NA_character_ else as.character(value)
}

usage_value <- function(usage, fields) {
  if (is.null(usage)) {
    return(NULL)
  }
  for (field in fields) {
    if (!is.null(usage[[field]])) {
      return(usage[[field]])
    }
  }
  NULL
}

usage_reasoning_tokens <- function(usage) {
  direct <- usage_number(usage, c("reasoning_tokens", "reasoning"))
  if (!is.na(direct)) {
    return(direct)
  }
  details <- usage$completion_tokens_details
  if (is.list(details) && !is.null(details$reasoning_tokens)) {
    return(as.numeric(details$reasoning_tokens[[1]]))
  }
  NA_real_
}

usage_cost_total <- function(usage) {
  if (is.list(usage$cost) && !is.null(usage$cost$total)) {
    return(as.numeric(usage$cost$total[[1]]))
  }
  usage_number(usage, c("estimated_cost_usd", "cost_total"))
}

new_hpo_run_id <- function() {
  paste0(
    "hpo-run-",
    format(Sys.time(), "%Y%m%d%H%M%S"),
    "-",
    sprintf("%06d", sample.int(1e6, 1L))
  )
}

bind_rows_base <- function(rows, empty) {
  rows <- rows[vapply(rows, nrow, integer(1)) > 0L]
  if (!length(rows)) {
    return(empty)
  }
  do.call(rbind, rows)
}
