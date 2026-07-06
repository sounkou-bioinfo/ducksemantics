# Compare embedding clusters with graph edges

This measures whether clustered node embeddings respect direct ontology
relations such as `is_a` and `part_of`. It is a coarse diagnostic: high
agreement does not prove semantic quality, but low agreement is
actionable evidence for the embedding, text source, or clustering setup.

## Usage

``` r
ducksemantics_embedding_cluster_graph_agreement(
  conn,
  cluster_run_id,
  predicates = c("is_a", "part_of"),
  prefix = "semantic"
)
```

## Arguments

- conn:

  DBI connection.

- cluster_run_id:

  Cluster run id written by
  [`ducksemantics_cluster_embeddings()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_cluster_embeddings.md).

- predicates:

  Edge predicates to evaluate.

- prefix:

  Prefix used for semantic tables.

## Value

One-row data frame with edge counts and same-cluster rate.
