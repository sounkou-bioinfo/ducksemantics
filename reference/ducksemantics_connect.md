# Connect to a DuckDB semantic store

Connect to a DuckDB semantic store

## Usage

``` r
ducksemantics_connect(dbdir = ":memory:", read_only = FALSE, array = "matrix")
```

## Arguments

- dbdir:

  DuckDB database path, or `":memory:"`.

- read_only:

  Open read-only?

- array:

  DuckDB array conversion mode. The default enables native vector
  columns to round-trip through R matrices.

## Value

A DBI connection.
