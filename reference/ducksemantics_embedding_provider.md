# Wrap an embedding function as a typed embedding provider

Wrap an embedding function as a typed embedding provider

## Usage

``` r
ducksemantics_embedding_provider(fun, label = "function")
```

## Arguments

- fun:

  Function accepting a character vector and returning a numeric matrix
  with one row per input text.

- label:

  Provider label for reports.

## Value

An object implementing
[DucksemanticsEmbeddingProvider](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingProvider.md).
