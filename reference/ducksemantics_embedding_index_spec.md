# Construct an embedding index specification

Construct an embedding index specification

## Usage

``` r
ducksemantics_embedding_index_spec(
  dimensions,
  provider = NULL,
  subject_kind = NULL,
  table = NULL,
  hnsw = TRUE,
  metric = "cosine",
  load_vss = TRUE
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
