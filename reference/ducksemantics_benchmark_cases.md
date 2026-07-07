# Define benchmark cases

Define benchmark cases

## Usage

``` r
ducksemantics_benchmark_cases(
  cases,
  gold,
  suite = "semantic",
  task = "grounding",
  source = NULL,
  version = NULL,
  metadata = list()
)
```

## Arguments

- cases:

  Data frame with `case_id` and `text`.

- gold:

  Data frame with `case_id` and `node_id`. Optional span columns are
  `span`, `start_offset`, and `end_offset`.

- suite:

  Benchmark suite label.

- task:

  Benchmark task label.

- source:

  Optional source dataset label.

- version:

  Optional source dataset version.

- metadata:

  Optional named list of benchmark metadata.

## Value

A benchmark object.
