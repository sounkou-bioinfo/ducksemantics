# Create a BebeLM embedding provider

Create a BebeLM embedding provider

## Usage

``` r
ducksemantics_bebel_embedding_provider(
  model,
  add_bos = TRUE,
  normalize = TRUE,
  pooling = c("mean", "last"),
  token_batch_size = 512L,
  sequence_batch_size = 64L,
  check_interrupt = TRUE
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

- token_batch_size:

  Number of tokens per Rust batched prefill/matmul call.

- sequence_batch_size:

  Number of texts per independent-sequence embedding batch.

- check_interrupt:

  Whether long embedding runs should poll R interrupts between texts and
  token batches.

## Value

An object implementing
[DucksemanticsEmbeddingProvider](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingProvider.md).
