# Compute benchmark precision and recall

Compute benchmark precision and recall

## Usage

``` r
ducksemantics_benchmark_metrics(predictions, gold, by = c("node", "span"))
```

## Arguments

- predictions:

  Prediction data frame from
  [`ducksemantics_benchmark()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_benchmark.md)
  or
  [`ducksemantics_annotate()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_annotate.md).

- gold:

  Gold data frame with `case_id` and `node_id`.

- by:

  Match on `node` only, or on exact `span` offsets when available.

## Value

A one-row data frame with `tp`, `fp`, `fn`, `precision`, `recall`, and
`f1`.
