# Build a prompt for candidate-to-model HPO adjudication

Creates the prompt for the practical hybrid arm:
`note + FastHPOCR candidates -> model keep/drop adjudication`. The model
is asked for auditable short fields, not hidden chain-of-thought.

## Usage

``` r
hpo_adjudication_prompt(
  note,
  candidates,
  case_id = NULL,
  allow_inferred = FALSE,
  prompt_version = "rfasthpocr-candidates-model-v1",
  extra_instructions = NULL
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

- case_id:

  Optional case id. If omitted, it is inferred from the candidate table
  when possible.

- allow_inferred:

  If `TRUE`, the prompt allows candidate decisions to use
  `support_type = "inferred"` when clearly supported by the note. It
  still asks the model not to invent new HPO IDs.

- prompt_version:

  Version label embedded in the prompt.

- extra_instructions:

  Optional additional instruction text.

## Value

A single prompt string.

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
prompt <- hpo_adjudication_prompt("No seizures were reported.", candidates)
cat(substr(prompt, 1, 200))
#> You are adjudicating candidate Human Phenotype Ontology (HPO) extractions from de-identified clinical text.
#> Return only valid JSON matching the schema. Do not include markdown fences or explanatory pr
```
