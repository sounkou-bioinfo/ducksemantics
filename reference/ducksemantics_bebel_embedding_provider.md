# Create a BebeLM embedding provider

Create a BebeLM embedding provider

## Usage

``` r
ducksemantics_bebel_embedding_provider(
  model,
  add_bos = TRUE,
  normalize = TRUE,
  pooling = c("mean", "last")
)
```

## Arguments

- model:

  A `Rbebelm` `BebelModel` object.

- add_bos:

  Include BOS in tokenization?

- normalize:

  L2-normalize embeddings?

- pooling:

  Hidden-state pooling strategy: `mean` or `last`.

## Value

An object implementing
[DucksemanticsEmbeddingProvider](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingProvider.md).
