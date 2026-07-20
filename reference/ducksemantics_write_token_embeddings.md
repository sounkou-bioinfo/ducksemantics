# Store token embeddings for late-interaction scoring

Native ColBERT document vectors are grouped by `block_id`, so exact
MaxSim can compare a query-token matrix to a stored candidate matrix
without changing the graph schema. Dense vectors in
`semantic_embeddings` remain the inexpensive broad-retrieval layer.

## Usage

``` r
ducksemantics_write_token_embeddings(
  batch,
  conn,
  prefix = "semantic",
  replace = FALSE
)
```

## Arguments

- batch:

  A `DucksemanticsTokenEmbeddingBatch` object from
  [`ducksemantics_token_embedding_batch()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_token_embedding_batch.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

- replace:

  Delete existing token rows for the same subjects and provider before
  inserting?

## Value

Invisibly, the written token embedding rows.
