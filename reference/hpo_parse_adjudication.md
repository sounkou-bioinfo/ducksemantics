# Parse model adjudication JSON into a data frame

Parses the structured JSON returned by the candidate adjudication prompt
and validates the core fields. If the original candidate table is
supplied, candidate offsets and source metadata are joined back for
audit.

## Usage

``` r
hpo_parse_adjudication(x, candidates = NULL)
```

## Arguments

- x:

  Character response, a `piknit`/Pi reply character vector, or a list
  with a `text`, `content`, or `reply` field.

- candidates:

  Optional candidate table used to join offsets and source metadata.

## Value

A data frame with one row per adjudicated candidate.

## Examples

``` r
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
hpo_parse_adjudication(json)
#>   case_id candidate_id candidate_span normalized_phrase     hpo_id hpo_label
#> 1  case-1  case-1:0001       seizures          seizures HP:0001250   Seizure
#>   decision support_type patient_context evidence_span
#> 1     drop         none         negated   No seizures
#>                            short_reason replacement_hpo_id
#> 1 The note explicitly negates seizures.               <NA>
#>   replacement_hpo_label confidence
#> 1                  <NA>         NA
```
