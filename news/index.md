# Changelog

## ducksemantics 0.0.0.9000

- Replaced removed causal BebeLM pooled/token-state providers with
  native EmbeddingGemma dense retrieval and LFM2.5-ColBERT
  document/query providers. Stored ColBERT blocks now use the profile’s
  exact MaxSim sum, while DuckDB VSS/HNSW remains the optional dense
  candidate-generation layer.

- Removed all `Rfmalloc` runtime, slab-storage, and clustering paths.
  Token vectors are durable DuckDB `FLOAT[]` rows and clustering uses
  ordinary R matrices.

- Rewrote the README, package direction notes, reference navigation, and
  examples around the native retrieval workflow.

- Renamed the package direction to `ducksemantics`.

- Removed the reticulate/FastHPOCR public API and Python dependency
  surface.

- Added DuckDB-native semantic graph tables, alias indexing, lexical
  mention grounding, graph projection SQL, and transitive closure SQL.

- Added structural S7 provider interfaces with `s7contract` for
  annotators, prompt runners, judgment parsers, and embedding providers.

- Added generic model judgment and benchmark primitives for
  HPO/MONDO-style grounding tasks.
