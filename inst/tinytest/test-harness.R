if (!requireNamespace("jsonlite", quietly = TRUE)) {
  exit_file("jsonlite not available")
}

ann <- data.frame(
  span = c("short stature", "seizures"),
  id = c("HP:0004322", "HP:0001250"),
  label = c("Short stature", "Seizure"),
  start = c(1L, 32L),
  end = c(13L, 39L),
  start_offset = c(0L, 31L),
  end_offset = c(13L, 39L),
  stringsAsFactors = FALSE
)
ann$categories <- I(list(list(), list()))

candidates <- hpo_candidate_table(ann, case_id = "case-1", run_id = "run-1")
expect_equal(nrow(candidates), 2L)
expect_equal(candidates$candidate_id, c("case-1:0001", "case-1:0002"))
expect_equal(candidates$hpo_id, ann$id)
expect_equal(candidates$run_id, c("run-1", "run-1"))

modes <- hpo_harness_modes()
expect_true("candidates_model" %in% modes$mode)
expect_true("tool_only" %in% modes$mode)

schema <- hpo_adjudication_schema()
expect_equal(schema$type, "object")
expect_true("decisions" %in% names(schema$properties))
schema_json <- hpo_adjudication_schema(as_json = TRUE)
expect_true(grepl("reason", schema_json, ignore.case = TRUE))

prompt <- hpo_adjudication_prompt(
  "Short stature was noted. No seizures were reported.",
  candidates
)
expect_true(grepl("Return only valid JSON", prompt, fixed = TRUE))
expect_true(grepl("reasoning-token counts", prompt, ignore.case = TRUE))
expect_true(grepl("case-1:0002", prompt, fixed = TRUE))
expect_true(grepl("No seizures", prompt, fixed = TRUE))

response <- jsonlite::toJSON(
  list(
    case_id = "case-1",
    decisions = list(
      list(
        candidate_id = "case-1:0001",
        candidate_span = "short stature",
        normalized_phrase = "short stature",
        hpo_id = "HP:0004322",
        hpo_label = "Short stature",
        decision = "keep",
        support_type = "direct",
        patient_context = "patient",
        evidence_span = "Short stature was noted",
        short_reason = "The phenotype is directly stated for the patient.",
        replacement_hpo_id = NULL,
        replacement_hpo_label = NULL,
        confidence = 0.95
      ),
      list(
        candidate_id = "case-1:0002",
        candidate_span = "seizures",
        normalized_phrase = "seizures",
        hpo_id = "HP:0001250",
        hpo_label = "Seizure",
        decision = "drop",
        support_type = "none",
        patient_context = "negated",
        evidence_span = "No seizures were reported",
        short_reason = "The note explicitly negates seizures.",
        replacement_hpo_id = NULL,
        replacement_hpo_label = NULL,
        confidence = 0.99
      )
    )
  ),
  auto_unbox = TRUE,
  null = "null"
)

parsed <- hpo_parse_adjudication(paste0("```json\n", response, "\n```"), candidates)
expect_equal(nrow(parsed), 2L)
expect_equal(parsed$decision, c("keep", "drop"))
expect_equal(parsed$patient_context[[2]], "negated")
expect_equal(parsed$start_offset, c(0L, 31L))
expect_equal(parsed$source, c("FastHPOCR", "FastHPOCR"))
expect_error(hpo_parse_adjudication('{"case_id":"case-1","decisions":[{"candidate_id":"x"}]}'))

mock_runner <- function(prompt) {
  out <- response
  attr(out, "usage") <- list(
    input_tokens = 100L,
    output_tokens = 50L,
    total_tokens = 150L,
    reasoning_tokens = 7L,
    tool_call_count = 0L
  )
  out
}

run <- hpo_adjudicate_candidates(
  "Short stature was noted. No seizures were reported.",
  candidates,
  mock_runner,
  provider = "mock-provider",
  model = "mock-model",
  run_id = "run-2"
)
expect_equal(nrow(run$adjudication), 2L)
expect_equal(run$run_log$provider, "mock-provider")
expect_equal(run$run_log$model, "mock-model")
expect_equal(run$run_log$input_tokens, 100)
expect_equal(run$run_log$reasoning_tokens, 7)
expect_true(run$run_log$parse_success)

bad_run <- hpo_adjudicate_candidates(
  "Short stature was noted.",
  candidates,
  runner = function(prompt) "not json",
  error_on_failure = FALSE,
  run_id = "run-3"
)
expect_false(bad_run$run_log$parse_success)
expect_true(nzchar(bad_run$run_log$error_message))
