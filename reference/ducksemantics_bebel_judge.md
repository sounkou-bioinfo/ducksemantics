# Judge mentions with a BebeLM/Rbebelm agent

Judge mentions with a BebeLM/Rbebelm agent

## Usage

``` r
ducksemantics_bebel_judge(
  agent,
  text,
  mentions,
  conn = NULL,
  prefix = "semantic",
  graph_context = NULL,
  instructions = ducksemantics_default_judgment_instructions(),
  parser = ducksemantics_json_judgment_parser(),
  on_event = NULL,
  record = !is.null(conn),
  model = "Rbebelm"
)
```

## Arguments

- agent:

  A `Rbebelm` agent object.

- text:

  Source text.

- mentions:

  Mention data frame from
  [`ducksemantics_annotate()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_annotate.md).

- conn:

  Optional DBI connection. When supplied with `record = TRUE`, judgments
  are appended to the judgment table.

- prefix:

  Prefix used for semantic tables.

- graph_context:

  Optional data frame or list with nearby graph context.

- instructions:

  Character scalar or vector containing the adjudication policy.

- parser:

  Object implementing
  [DucksemanticsJudgmentParser](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsJudgmentParser.md).

- on_event:

  Optional Rbebelm event callback.

- record:

  Append judgments to the judgment table?

- model:

  Model label recorded with judgments.

## Value

A data frame of judgment rows.
