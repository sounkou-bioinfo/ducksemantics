# Embedding clustering specification

Embedding clustering specification

## Usage

``` r
DucksemanticsEmbeddingClusterSpec(
  k = integer(0),
  provider = NULL,
  subject_kind = NULL,
  dimensions = NULL,
  table = NULL,
  run_id = character(0),
  seed = integer(0),
  nstart = integer(0),
  max_iter = integer(0),
  storage = character(0)
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

- storage:

  Matrix storage for the clustering pass. `"r"` uses an ordinary R
  matrix. `"rfmalloc"` allocates the working matrix through Rfmalloc.

## Value

A `DucksemanticsEmbeddingClusterSpec` object.
