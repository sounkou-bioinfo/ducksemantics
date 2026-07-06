# Embedding search query

Embedding search query

## Usage

``` r
DucksemanticsEmbeddingQuery(
  embedding = integer(0),
  provider = NULL,
  subject_kind = NULL,
  top_k = integer(0),
  metric = character(0),
  table = NULL
)
```

## Arguments

- embedding:

  Numeric query embedding.

- provider:

  Optional provider filter.

- subject_kind:

  Optional subject-kind filter.

- top_k:

  Number of nearest rows to return.

- metric:

  One of `"cosine"`, `"cosine_distance"`, `"l2"`, or `"inner_product"`.

- table:

  Optional table to search. Defaults to `semantic_embeddings`. Pass a
  table created by
  [`ducksemantics_materialize_embedding_index()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_materialize_embedding_index.md)
  to use a dimensioned, HNSW-indexable table.

## Value

A `DucksemanticsEmbeddingQuery` object.
