# Materialize a fixed-dimension embedding table

DuckDB's HNSW index requires a fixed-size vector type such as
`FLOAT[384]`. This function projects rows from `semantic_embeddings`
into a dimensioned table and can create a native HNSW index on that
table.

## Usage

``` r
ducksemantics_materialize_embedding_index(spec, conn, prefix = "semantic")
```

## Arguments

- spec:

  A
  [DucksemanticsEmbeddingIndexSpec](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingIndexSpec.md)
  object from
  [`ducksemantics_embedding_index_spec()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_index_spec.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

## Value

Target table name.
