# Changelog

## ducksemantics 0.0.0.9000

- Renamed the package direction to `ducksemantics`.
- Removed the reticulate/FastHPOCR public API and Python dependency
  surface.
- Added DuckDB-native semantic graph tables, alias indexing, lexical
  mention grounding, graph projection SQL, and transitive closure SQL.
- Added structural S7 provider interfaces with `s7contract` for
  annotators, prompt runners, judgment parsers, and embedding providers.
- Added generic model judgment and benchmark primitives for
  HPO/MONDO-style grounding tasks.
