# Cache an R value on disk

Cache an R value on disk

## Usage

``` r
ducksemantics_cache_rds(path, compute, refresh = FALSE)
```

## Arguments

- path:

  RDS cache path.

- compute:

  Function called with no arguments when the cache is missing or
  refreshed.

- refresh:

  Recompute even when the cache file already exists?

## Value

The cached R object.
