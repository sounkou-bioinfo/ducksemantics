# Summarize stored embedding clusters

Summarize stored embedding clusters

## Usage

``` r
ducksemantics_embedding_cluster_summary(
  conn,
  cluster_run_id = NULL,
  prefix = "semantic"
)
```

## Arguments

- conn:

  DBI connection.

- cluster_run_id:

  Optional cluster run filter.

- prefix:

  Prefix used for semantic tables.

## Value

Data frame with cluster sizes and distance summaries.
