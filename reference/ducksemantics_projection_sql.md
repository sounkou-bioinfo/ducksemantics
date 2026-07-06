# Project any edge-shaped source relation into graph shape

Mirrors the graph projection profile used in pi-bio-agent: a source
table with caller-named columns becomes a stable graph edge table with
`from_id`, `predicate`, `to_id`, `attrs`, and `trust`.

## Usage

``` r
ducksemantics_projection_sql(
  source_table,
  from,
  predicate,
  to,
  target_table = "semantic_edges",
  attrs = NULL,
  trust = NULL
)
```

## Arguments

- source_table:

  Source table or view name.

- from, predicate, to:

  Source column names.

- target_table:

  Target table name.

- attrs, trust:

  Optional source columns containing JSON.

## Value

A single `CREATE OR REPLACE TABLE ... AS SELECT ...` SQL statement.
