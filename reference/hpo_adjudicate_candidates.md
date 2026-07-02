# Run a candidates-to-model adjudication step

Executes a generic model runner on the prompt produced by
[`hpo_adjudication_prompt()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_adjudication_prompt.md),
parses the structured JSON response, and returns run-level metadata
suitable for provider/model comparisons. This function is deliberately
runner-agnostic: pass a function that calls `piknit::pi_run()`, a local
OpenAI-compatible endpoint, Ollama, vLLM, or any other provider.

## Usage

``` r
hpo_adjudicate_candidates(
  note,
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
  ...
)
```

## Arguments

- note:

  Character scalar containing the source clinical text.

- candidates:

  Candidate table from
  [`hpo_candidate_table()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_candidate_table.md)
  or raw annotations from
  [`hpo_annotate()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotate.md).

- runner:

  Function taking a single prompt string and returning a character
  response. It may also return a list with `text` and `usage` fields, or
  a character vector with a `usage` attribute.

- case_id:

  Optional case id.

- provider:

  Provider label for the run log.

- model:

  Model label for the run log.

- mode:

  Harness mode label.

- prompt_version:

  Prompt version label.

- tool_config:

  Tool configuration label or list for the run log.

- run_id:

  Optional run id. Generated when omitted.

- retry_count:

  Retry count to record in the run log.

- estimated_cost_usd:

  Optional cost estimate.

- error_on_failure:

  If `TRUE`, runner or parse errors stop execution. If `FALSE`, errors
  are captured in the returned `run_log`.

- ...:

  Additional arguments passed to
  [`hpo_adjudication_prompt()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_adjudication_prompt.md).

## Value

A list with `prompt`, `raw_response`, `adjudication`, and `run_log`.

## Details

The returned `run_log` treats token counts and reasoning-token counts as
API usage metadata. The useful clinical audit fields remain in the
term-level adjudication table: `decision`, `evidence_span`, and
`short_reason`.

## Examples

``` r
ann <- data.frame(
  span = "seizures",
  id = "HP:0001250",
  label = "Seizure",
  start = 4L,
  end = 11L,
  start_offset = 3L,
  end_offset = 11L,
  stringsAsFactors = FALSE
)
ann$categories <- I(list(list()))
candidates <- hpo_candidate_table(ann, case_id = "case-1")
json <- jsonlite::toJSON(
  list(
    case_id = "case-1",
    decisions = list(list(
      candidate_id = "case-1:0001",
      candidate_span = "seizures",
      normalized_phrase = "seizures",
      hpo_id = "HP:0001250",
      hpo_label = "Seizure",
      decision = "drop",
      support_type = "none",
      patient_context = "negated",
      evidence_span = "No seizures",
      short_reason = "The note explicitly negates seizures."
    ))
  ),
  auto_unbox = TRUE
)
fixture_runner <- function(prompt) json
hpo_adjudicate_candidates("No seizures were reported.", candidates, fixture_runner)$adjudication
#>   case_id candidate_id candidate_span normalized_phrase     hpo_id hpo_label
#> 1  case-1  case-1:0001       seizures          seizures HP:0001250   Seizure
#>   decision support_type patient_context evidence_span
#> 1     drop         none         negated   No seizures
#>                            short_reason replacement_hpo_id
#> 1 The note explicitly negates seizures.               <NA>
#>   replacement_hpo_label confidence    source source_rank start end start_offset
#> 1                  <NA>         NA FastHPOCR           1     3  11            3
#>   end_offset run_id
#> 1         11   <NA>
```
