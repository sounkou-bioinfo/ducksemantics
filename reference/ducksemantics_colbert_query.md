# Construct a ColBERT late-interaction query

Encodes text with the profile's query contract and returns a query
object directly consumable by
[`ducksemantics_late_interaction_search()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_late_interaction_search.md).
Candidate blocks must have been stored from a ColBERT document provider
with the same `label`.

## Usage

``` r
ducksemantics_colbert_query(
  model,
  text,
  provider = "Rbebelm ColBERT",
  subject_kind = NULL,
  top_k = 10L,
  table = NULL,
  candidate_subject_id = NULL
)
```

## Arguments

- model:

  A `Rbebelm` `ColbertModel` object.

- text:

  Non-empty query text.

- provider:

  Stored document provider label.

- subject_kind:

  Optional candidate subject-kind filter.

- top_k:

  Number of candidate blocks to return.

- table:

  Optional token-embedding table.

- candidate_subject_id:

  Optional candidate subject identifiers.

## Value

A
[DucksemanticsTokenEmbeddingQuery](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsTokenEmbeddingQuery.md).
