# Store token embeddings for late-interaction scoring

Token embeddings are grouped by `block_id`, so a later native scorer can
compare query-token and document-token matrices without changing the
graph schema. The first active embedding path remains pooled vectors in
`semantic_embeddings`.

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
