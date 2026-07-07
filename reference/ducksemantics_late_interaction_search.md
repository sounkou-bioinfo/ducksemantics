# Search token embeddings with exact late interaction

Scores stored token-embedding blocks with ColBERT-style MaxSim. For each
query token, the scorer finds the best matching token in a candidate
block and averages those maxima. This is the exact reranking primitive
for candidate sets produced by lexical aliases, FTS, graph
neighborhoods, or pooled-vector search.

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
