# Construct an embedding batch

Construct an embedding batch

## Usage

``` r
ducksemantics_embedding_batch(
  embeddings,
  subject_id,
  subject_kind = "node",
  provider = "embedding",
  text = NULL,
  attrs = NULL
)
```

## Arguments

- embeddings:

  Numeric matrix with one row per subject.

- subject_id:

  Subject identifiers matching embedding rows.

- subject_kind:

  Subject type, e.g. `"node"`, `"alias"`, `"mention"`, or `"document"`.

- provider:

  Embedding provider label.

- text:

  Optional source text for each embedding.

- attrs:

  Optional JSON text or other metadata for each embedding.
