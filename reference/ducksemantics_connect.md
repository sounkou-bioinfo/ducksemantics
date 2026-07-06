# Connect to a DuckDB semantic store

Connect to a DuckDB semantic store

## Usage

``` r
ducksemantics_connect(dbdir = ":memory:", read_only = FALSE)
```

## Arguments

- dbdir:

  DuckDB database path, or `":memory:"`.

- read_only:

  Open read-only?

## Value

A DBI connection.
