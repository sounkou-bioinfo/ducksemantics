# Embedding batch for the semantic store

Embedding batch for the semantic store

## Usage

``` r
DucksemanticsEmbeddingBatch(
  embeddings = integer(0),
  subject_id = character(0),
  subject_kind = character(0),
  provider = character(0),
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

## Value

A `DucksemanticsEmbeddingBatch` object.
