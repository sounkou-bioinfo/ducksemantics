# Store an embedding batch in DuckDB

Embeddings are stored in DuckDB as native `FLOAT[]` vectors. Similarity
search casts those vectors to fixed-size `FLOAT[N]` arrays so DuckDB's
vector functions and optional HNSW index can be used directly.

## Usage

``` r
ducksemantics_write_embeddings(
  batch,
  conn,
  prefix = "semantic",
  replace = FALSE
)
```

## Arguments

- batch:

  A
  [DucksemanticsEmbeddingBatch](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingBatch.md)
  object from
  [`ducksemantics_embedding_batch()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_batch.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

- replace:

  Delete existing embeddings for the same subjects and provider before
  inserting?

## Value

Invisibly, the written embedding rows.
