# Construct a token embedding batch

Construct a token embedding batch

## Usage

``` r
ducksemantics_token_embedding_batch(
  embeddings,
  subject_id,
  subject_kind = "node",
  provider = "embedding",
  token_index = NULL,
  block_id = NULL,
  token = NULL,
  start_offset = NULL,
  end_offset = NULL,
  storage = c("duckdb_float_array", "rfmalloc_slab"),
  storage_ref = NULL,
  attrs = NULL
)
```

## Arguments

- embeddings:

  Numeric matrix with one row per token.

- subject_id:

  Subject identifier for each token row.

- subject_kind:

  Subject type, e.g. `"node"`, `"alias"`, `"mention"`, or `"document"`.

- provider:

  Embedding provider label.

- token_index:

  Token index within each subject block. Defaults to zero-based order
  within `subject_id`.

- block_id:

  Matrix/block identifier. Defaults to one block per `provider`,
  `subject_kind`, and `subject_id`.

- token:

  Optional token text for each row.

- start_offset, end_offset:

  Optional zero-based source offsets.

- storage:

  Storage label. `"duckdb_float_array"` means `embedding` stores each
  token row directly in DuckDB. `"rfmalloc_slab"` is reserved for native
  slabs addressed by `storage_ref`.

- storage_ref:

  Optional native storage reference.

- attrs:

  Optional JSON text or other metadata for each token row.
