# Cache provider embeddings in durable chunks

This is the embedding cache used for large ontology passes. Each chunk
is written after it finishes, so interrupted runs can resume without
discarding completed BebeLM work.

## Usage

``` r
ducksemantics_embed_cached(
  text,
  provider,
  cache_dir,
  chunk_size = 4096L,
  refresh = FALSE,
  ...
)
```

## Arguments

- text:

  Character vector to embed.

- provider:

  Object implementing
  [DucksemanticsEmbeddingProvider](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingProvider.md).

- cache_dir:

  Directory for chunk RDS files.

- chunk_size:

  Number of texts per persisted chunk.

- refresh:

  Recompute all chunks?

- ...:

  Extra arguments passed to
  [`ducksemantics_embed()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md).

## Value

Numeric embedding matrix with one row per input text.
