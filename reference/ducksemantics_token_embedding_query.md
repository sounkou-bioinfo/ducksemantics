# Construct a token embedding late-interaction query

Construct a token embedding late-interaction query

## Usage

``` r
ducksemantics_token_embedding_query(
  embeddings,
  provider = NULL,
  subject_kind = NULL,
  top_k = 10L,
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
