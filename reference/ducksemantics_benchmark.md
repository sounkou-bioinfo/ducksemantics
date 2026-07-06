# Run a grounding benchmark

Run a grounding benchmark

## Usage

``` r
ducksemantics_benchmark(
  benchmark,
  conn,
  prefix = "semantic",
  annotator = ducksemantics_lexical_annotator(),
  longest_match = TRUE,
  record = FALSE,
  collect_index_stats = TRUE
)
```

## Arguments

- benchmark:

  Benchmark object from
  [`ducksemantics_benchmark_cases()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_benchmark_cases.md).

- conn:

  DBI connection.

- prefix:

  Prefix used for semantic tables.

- annotator:

  Object implementing
  [DucksemanticsAnnotator](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsAnnotator.md).

- longest_match:

  Drop matches contained by a longer span.

- record:

  Append predicted mentions to the mentions table?

- collect_index_stats:

  Include index stats in the result?

## Value

A list with predictions, timings, metrics, and optional index stats.
