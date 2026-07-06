# Annotate text against the semantic alias index

Annotate text against the semantic alias index

## Usage

``` r
ducksemantics_annotate(
  conn,
  text,
  document_id = NULL,
  prefix = "semantic",
  longest_match = TRUE,
  record = FALSE
)
```

## Arguments

- conn:

  DBI connection.

- text:

  Character scalar.

- document_id:

  Optional document id.

- prefix:

  Prefix used for semantic tables.

- longest_match:

  Drop matches contained by a longer span.

- record:

  Append returned mentions to the mentions table?

## Value

A data frame of grounded mentions.
