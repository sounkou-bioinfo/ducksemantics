# Cache provider embeddings in durable chunks

This cache is used for large ontology passes. Each chunk is written
after it finishes, so interrupted runs can resume without discarding
completed native retrieval-encoder work.

## Usage

``` r
ducksemantics_embed_cached(
  text,
  provider,
  cache_dir,
  chunk_size = 4096L,
  refresh = FALSE,
  cache_key = NULL,
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

- cache_key:

  Optional stable identifier for provider weights or other state that is
  not represented by the provider object. Changing it invalidates
  existing chunks.

- ...:

  Extra arguments passed to
  [`ducksemantics_embed()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md).
  These arguments are included in the cache identity.

## Value

Numeric embedding matrix with one row per input text.
