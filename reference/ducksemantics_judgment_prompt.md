# Build a semantic judgment prompt

Build a semantic judgment prompt

## Usage

``` r
ducksemantics_judgment_prompt(
  text,
  mentions,
  graph_context = NULL,
  instructions = ducksemantics_default_judgment_instructions()
)
```

## Arguments

- text:

  Source text.

- mentions:

  Mention data frame from
  [`ducksemantics_annotate()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_annotate.md).

- graph_context:

  Optional data frame or list with nearby graph context.

- instructions:

  Character scalar or vector containing the adjudication policy. This is
  deliberately explicit so benchmark runs can vary the policy without
  changing candidate generation.

## Value

Prompt text.
