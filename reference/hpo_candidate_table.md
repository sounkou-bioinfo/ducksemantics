# Convert FastHPOCR annotations to a harness candidate table

Standardizes annotations returned by
[`hpo_annotate()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotate.md)
into the candidate table used by hybrid model-adjudication prompts and
comparison harnesses. The HPO identifier and label are preserved from
FastHPOCR, while `candidate_id` gives each row a stable handle for model
keep/drop decisions.

## Usage

``` r
hpo_candidate_table(
  annotations,
  case_id = NA_character_,
  source = "FastHPOCR",
  run_id = NA_character_
)
```

## Arguments

- annotations:

  A data frame or list returned by
  [`hpo_annotate()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotate.md).

- case_id:

  Character scalar identifying the source case. `NA` is allowed for ad
  hoc use, but real harness runs should pass a stable case id.

- source:

  Source label for the candidates.

- run_id:

  Optional run id to carry forward into joined outputs.

## Value

A data frame with one row per candidate and columns including `case_id`,
`candidate_id`, `candidate_span`, `hpo_id`, `hpo_label`, and offset
metadata.

## Examples

``` r
ann <- data.frame(
  span = "short stature",
  id = "HP:0004322",
  label = "Short stature",
  start = 1L,
  end = 13L,
  start_offset = 0L,
  end_offset = 13L,
  stringsAsFactors = FALSE
)
ann$categories <- I(list(list()))
hpo_candidate_table(ann, case_id = "case-1")
#>   case_id run_id candidate_id    source source_rank candidate_span
#> 1  case-1   <NA>  case-1:0001 FastHPOCR           1  short stature
#>   normalized_phrase     hpo_id     hpo_label start end start_offset end_offset
#> 1     short stature HP:0004322 Short stature     0  13            0         13
#>   categories
#> 1           
```
