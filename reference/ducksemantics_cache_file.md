# Cache a source file

Cache a source file

## Usage

``` r
ducksemantics_cache_file(
  url,
  filename = basename(url),
  cache_dir = tools::R_user_dir("ducksemantics", "cache"),
  refresh = FALSE
)
```

## Arguments

- url:

  Source URL.

- filename:

  Cache filename.

- cache_dir:

  Cache directory.

- refresh:

  Download even when the cache file already exists?

## Value

Normalized path to the cached file.
