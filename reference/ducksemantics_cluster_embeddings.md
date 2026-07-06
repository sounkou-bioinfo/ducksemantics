# Cluster embedding rows

Clustering writes assignments and centroids back to DuckDB. It is
intended as a first measurement surface for whether a provider's
embeddings recover ontology structure before adding graph-aware or
late-interaction scoring.

## Usage

``` r
ducksemantics_cluster_embeddings(
  spec,
  conn,
  prefix = "semantic",
  replace = TRUE,
  rfmalloc_runtime = NULL
)
```

## Arguments

- spec:

  A `DucksemanticsEmbeddingClusterSpec` object from
  [`ducksemantics_embedding_cluster_spec()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_cluster_spec.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

- replace:

  Delete rows for `spec$run_id` before writing?

- rfmalloc_runtime:

  Optional Rfmalloc runtime used when `storage = "rfmalloc"`.

## Value

A list with assignments, centroids, summary, and the `kmeans` object.
