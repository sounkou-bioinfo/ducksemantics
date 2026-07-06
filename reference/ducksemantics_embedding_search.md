# Search embeddings with DuckDB vector functions

Search embeddings with DuckDB vector functions

## Usage

``` r
ducksemantics_embedding_search(query, conn, prefix = "semantic")
```

## Arguments

- query:

  A
  [DucksemanticsEmbeddingQuery](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingQuery.md)
  object from
  [`ducksemantics_embedding_query()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_query.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

## Value

Data frame ordered by best match.
