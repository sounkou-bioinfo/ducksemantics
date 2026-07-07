# Token embedding late-interaction query

Token embedding late-interaction query

## Usage

``` r
DucksemanticsTokenEmbeddingQuery(
  embeddings = integer(0),
  provider = NULL,
  subject_kind = NULL,
  top_k = integer(0),
  table = NULL,
  candidate_subject_id = NULL
)
```

## Arguments

- embeddings:

  Numeric query-token matrix.

- provider:

  Optional provider filter.

- subject_kind:

  Optional subject-kind filter.

- top_k:

  Number of scored blocks to return.

- table:

  Optional table to search. Defaults to `semantic_token_embeddings`.

- candidate_subject_id:

  Optional candidate subject identifiers.

## Value

A `DucksemanticsTokenEmbeddingQuery` object.
