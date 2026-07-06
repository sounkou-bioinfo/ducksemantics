# Judge mentions with a model runner

Judge mentions with a model runner

## Usage

``` r
ducksemantics_judge(
  text,
  mentions,
  runner,
  conn = NULL,
  prefix = "semantic",
  graph_context = NULL,
  instructions = ducksemantics_default_judgment_instructions(),
  prompt_builder = ducksemantics_judgment_prompt,
  parser = ducksemantics_json_judgment_parser(),
  record = !is.null(conn),
  model = "semantic-runner",
  ...
)
```

## Arguments

- text:

  Source text.

- mentions:

  Mention data frame from
  [`ducksemantics_annotate()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_annotate.md).

- runner:

  Object implementing
  [DucksemanticsPromptRunner](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsPromptRunner.md).

- conn:

  Optional DBI connection. When supplied with `record = TRUE`, judgments
  are appended to the judgment table.

- prefix:

  Prefix used for semantic tables.

- graph_context:

  Optional data frame or list with nearby graph context.

- instructions:

  Character scalar or vector containing the adjudication policy.

- prompt_builder:

  Function that builds the prompt.

- parser:

  Object implementing
  [DucksemanticsJudgmentParser](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsJudgmentParser.md).

- record:

  Append judgments to the judgment table?

- model:

  Model label recorded with judgments.

- ...:

  Extra arguments passed to `prompt_builder`.

## Value

A data frame of judgment rows. The prompt and raw response are stored as
`prompt` and `response` attributes for audit and benchmarking.
