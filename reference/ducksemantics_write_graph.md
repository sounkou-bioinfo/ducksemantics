# Write graph rows into the semantic store

Write graph rows into the semantic store

## Usage

``` r
ducksemantics_write_graph(
  conn,
  nodes = NULL,
  aliases = NULL,
  edges = NULL,
  prefix = "semantic",
  replace = FALSE,
  index = TRUE
)
```

## Arguments

- conn:

  DBI connection.

- nodes:

  Data frame with `node_id`, `family`, and optional `label`,
  `description`, `attrs`, `trust`.

- aliases:

  Data frame with `node_id`, `alias`, and optional `alias_kind`,
  `source`, `weight`, `attrs`.

- edges:

  Data frame with `from_id`, `predicate`, `to_id`, and optional `attrs`,
  `trust`.

- prefix:

  Prefix used for semantic tables.

- replace:

  Delete existing rows from populated target tables before writing?

- index:

  Rebuild the alias index after writing aliases?

## Value

Invisibly, the semantic table names.
