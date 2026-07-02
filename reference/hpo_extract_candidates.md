# Extract FastHPOCR candidate tables for one or more cases

Loads or reuses a FastHPOCR annotator and runs
[`hpo_annotate()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotate.md)
once per input text, returning a single comparison-friendly candidate
table. This is the package's `tool_only` harness lane.

## Usage

``` r
hpo_extract_candidates(
  annotator,
  text,
  case_id = NULL,
  longest_match = TRUE,
  source = "FastHPOCR",
  run_id = NA_character_
)
```

## Arguments

- annotator:

  A `fast_hpo_cr_annotator` returned by
  [`hpo_annotator()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotator.md),
  or a path to an index file.

- text:

  Character vector of case texts.

- case_id:

  Optional character vector of case identifiers. If omitted,
  `names(text)` are used when present, otherwise sequential identifiers
  are generated.

- longest_match:

  Passed to
  [`hpo_annotate()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotate.md).

- source:

  Source label for the candidate table.

- run_id:

  Optional run id to carry forward into candidate rows.

## Value

A candidate table as returned by
[`hpo_candidate_table()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_candidate_table.md).

## Examples

``` r
if (FALSE) {
  ann <- hpo_annotator("hp.index.gz")
  hpo_extract_candidates(
    ann,
    c(case1 = "Short stature and seizures were reported."),
    longest_match = TRUE
  )
}
```
