# ducksemantics 0.1.0

- Added the first release of the DuckDB-native semantic graph, lexical
  grounding, dense retrieval, exact late-interaction, structured judgment, and
  benchmark APIs.
- Validated the complete HPO 2026-06-23 release: 19,836 active nodes, 50,029
  aliases, 24,378 direct edges, and 202,740 materialized `is_a` closure rows.
  Full model runs persisted 19,836 EmbeddingGemma vectors and 182,884 native
  LFM2.5-ColBERT token vectors.
- Corrected OBO qualifier parsing, decoded escaped quoted text, and imported
  alternate identifiers. Full HPO parsing now leaves no dangling qualified
  `is_a` targets.
- Made graph writes transactional and idempotent, restored graph indexes after
  projection and closure replacement, and isolated late-interaction blocks by
  provider, subject kind, subject, and block identifier.
- Deduplicated lexical aliases per span and node while assigning unique IDs to
  ambiguous candidates. Structured judgments now require exact candidate
  coverage, valid confidence values, and replacements grounded in supplied
  candidates or graph context.
- Made embedding caches content- and provider-aware, atomic, resumable, and safe
  to refresh without deleting unrelated files.
- Registered S7 methods during namespace loading and tightened table, vector,
  token metadata, benchmark, and model-provider validation.
- Replaced causal pooled-state retrieval paths with native EmbeddingGemma and
  LFM2.5-ColBERT providers. DuckDB VSS/HNSW remains an optional dense
  candidate-generation layer.
- Removed the reticulate/FastHPOCR and Rfmalloc runtime surfaces. Ontology and
  local graph sources now share one graph schema and durable DuckDB vector
  storage.
