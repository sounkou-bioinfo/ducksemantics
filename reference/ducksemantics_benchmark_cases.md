# Define benchmark cases

Define benchmark cases

## Usage

``` r
ducksemantics_benchmark_cases(cases, gold, suite = "semantic")
```

## Arguments

- cases:

  Data frame with `case_id` and `text`.

- gold:

  Data frame with `case_id` and `node_id`. Optional span columns are
  `span`, `start_offset`, and `end_offset`.

- suite:

  Benchmark suite label.

## Value

A benchmark object.
