# Create an EmbeddingGemma dense retrieval provider

Create an EmbeddingGemma dense retrieval provider

## Usage

``` r
ducksemantics_embeddinggemma_provider(
  model,
  label = "Rbebelm EmbeddingGemma",
  task = "semantic_similarity",
  title = NULL,
  dimensions = 768L,
  normalize = TRUE,
  truncate = TRUE,
  check_interrupt = TRUE
)
```

## Arguments

- model:

  A `Rbebelm` `EmbeddingGemmaModel` object.

- label:

  Provider label for stored dense vectors.

- task:

  EmbeddingGemma task prompt. Use the same task for vectors that will be
  compared; use the dedicated query/document tasks only as a matched
  retrieval pair.

- title:

  Optional document title, valid only for `retrieval_document`.

- dimensions:

  Matryoshka dimension: 768, 512, 256, or 128.

- normalize:

  L2-normalize output rows.

- truncate:

  Truncate inputs longer than EmbeddingGemma's context.

- check_interrupt:

  Poll for R interrupts between bounded native batches.

## Value

An object implementing
[DucksemanticsEmbeddingProvider](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingProvider.md).
