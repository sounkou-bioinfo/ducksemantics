# Create a BebeLM token embedding provider

Create a BebeLM token embedding provider

## Usage

``` r
ducksemantics_bebel_token_embedding_provider(
  model,
  label = "Rbebelm token",
  add_bos = FALSE,
  normalize = TRUE,
  token_batch_size = 512L,
  check_interrupt = TRUE
)
```

## Arguments

- model:

  A `Rbebelm` `BebelModel` object.

- label:

  Provider label for stored token rows.

- add_bos:

  Include BOS in tokenization? Defaults to `FALSE` for late-interaction
  scoring.

- normalize:

  L2-normalize token embeddings?

- token_batch_size:

  Number of tokens per Rust batched prefill/matmul call.

- check_interrupt:

  Whether long token embedding runs should poll R interrupts between
  token batches.

## Value

An object implementing `DucksemanticsTokenEmbeddingProvider`.
