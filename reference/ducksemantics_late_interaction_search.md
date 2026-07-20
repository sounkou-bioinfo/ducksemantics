# Search token embeddings with exact late interaction

Scores stored native ColBERT document blocks with exact MaxSim. For each
query token, the scorer finds the best matching document token and sums
those maxima, matching `Rbebelm::colbert_maxsim()` once both matrices
have been materialized. Use dense EmbeddingGemma/HNSW, aliases, FTS, or
graph context to reduce large corpora before this reranker.

## Usage

``` r
ducksemantics_late_interaction_search(query, conn, prefix = "semantic")
```

## Arguments

- query:

  A `DucksemanticsTokenEmbeddingQuery` object from
  [`ducksemantics_token_embedding_query()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_token_embedding_query.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

## Value

Data frame ordered by descending MaxSim score.
