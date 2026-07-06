# Read an OBO ontology into semantic graph rows

Read an OBO ontology into semantic graph rows

## Usage

``` r
ducksemantics_read_obo(
  path,
  family,
  source = basename(path),
  include_obsolete = FALSE
)
```

## Arguments

- path:

  OBO file path.

- family:

  Graph family label, for example `"HPO"` or `"MONDO"`.

- source:

  Source label stored on alias rows.

- include_obsolete:

  Include terms marked `is_obsolete: true`?

## Value

A list with `nodes`, `aliases`, and `edges` data frames.
