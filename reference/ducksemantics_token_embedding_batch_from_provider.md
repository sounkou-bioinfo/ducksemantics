# Construct a token embedding batch from a provider

Construct a token embedding batch from a provider

## Usage

``` r
ducksemantics_token_embedding_batch_from_provider(
  text,
  provider,
  subject_id = text,
  subject_kind = "node",
  provider_label = NULL,
  block_id = NULL,
  attrs = NULL,
  ...
)
```

## Arguments

- text:

  Character vector to embed.

- provider:

  Object implementing `DucksemanticsTokenEmbeddingProvider`.

- subject_id:

  Subject identifiers for input texts. Defaults to `text`.

- subject_kind:

  Subject type for stored token rows.

- provider_label:

  Stored provider label. Defaults to the provider label when available.

- block_id:

  Optional block id per input text.

- attrs:

  Optional attrs value per input text.

- ...:

  Extra arguments passed to
  [`ducksemantics_token_embed()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md).

## Value

A `DucksemanticsTokenEmbeddingBatch` object.
