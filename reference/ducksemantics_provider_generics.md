# Provider interface generics

These S7 generics are the behavior required by the structural
interfaces. Provider packages should define concrete S7 classes and
methods for these generics, then consuming code can assert the
corresponding `Ducksemantics*` interface.

## Usage

``` r
ducksemantics_run(provider, prompt, ...)

ducksemantics_embed(provider, text, ...)

ducksemantics_parse(parser, response, ...)

ducksemantics_ground(
  annotator,
  conn,
  text,
  document_id = NULL,
  prefix = "semantic",
  longest_match = TRUE,
  record = FALSE,
  ...
)
```

## Arguments

- provider:

  Prompt or embedding provider.

- prompt:

  Prompt text.

- ...:

  Provider-specific arguments.

- text:

  Source text.

- parser:

  Judgment parser.

- response:

  Raw model response text.

- annotator:

  Text-grounding provider.

- conn:

  DBI connection.

- document_id:

  Optional document id.

- prefix:

  Semantic table prefix.

- longest_match:

  Drop matches contained by a longer span.

- record:

  Append returned rows to the semantic store?

## Value

Provider-specific output: response text, embedding matrix, parsed
judgment data frame, or grounded mention data frame.
