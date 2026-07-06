# Write an OBO ontology into the semantic store

Write an OBO ontology into the semantic store

## Usage

``` r
ducksemantics_write_obo(
  conn,
  path,
  family,
  source = basename(path),
  prefix = "semantic",
  replace = FALSE,
  index = TRUE,
  include_obsolete = FALSE
)
```

## Arguments

- conn:

  DBI connection.

- path:

  OBO file path.

- family:

  Graph family label, for example `"HPO"` or `"MONDO"`.

- source:

  Source label stored on alias rows.

- prefix:

  Prefix used for semantic tables.

- replace:

  Delete existing graph rows before writing?

- index:

  Rebuild the alias index?

- include_obsolete:

  Include terms marked `is_obsolete: true`?

## Value

The parsed graph rows, invisibly.
