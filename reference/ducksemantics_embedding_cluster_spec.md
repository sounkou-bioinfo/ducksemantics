# Construct an embedding clustering specification

Construct an embedding clustering specification

## Usage

``` r
ducksemantics_embedding_cluster_spec(
  k,
  provider = NULL,
  subject_kind = NULL,
  dimensions = NULL,
  table = NULL,
  run_id = NULL,
  seed = 1L,
  nstart = 10L,
  max_iter = 100L
)
```

## Arguments

- k:

  Number of clusters.

- provider:

  Optional provider filter.

- subject_kind:

  Optional subject-kind filter.

- dimensions:

  Optional embedding dimension filter.

- table:

  Optional embedding table. Defaults to `semantic_embeddings`.

- run_id:

  Identifier written to cluster tables.

- seed:

  Random seed used by
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html).

- nstart:

  Number of starts used by
  [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html).

- max_iter:

  Maximum k-means iterations.
