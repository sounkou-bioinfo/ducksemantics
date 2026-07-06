# Embedding index specification

Embedding index specification

## Usage

``` r
DucksemanticsEmbeddingIndexSpec(
  dimensions = integer(0),
  provider = NULL,
  subject_kind = NULL,
  table = NULL,
  hnsw = logical(0),
  metric = character(0),
  load_vss = logical(0)
)
```

## Arguments

- dimensions:

  Embedding dimension.

- provider:

  Optional provider filter.

- subject_kind:

  Optional subject-kind filter.

- table:

  Target table name. Defaults to
  `semantic_embedding_index_<dimensions>`.

- hnsw:

  Create a DuckDB HNSW index on the materialized table?

- metric:

  HNSW metric, usually `"cosine"`, `"l2sq"`, or `"ip"`.

- load_vss:

  Load DuckDB's `vss` extension before creating the HNSW index?

## Value

A `DucksemanticsEmbeddingIndexSpec` object.
