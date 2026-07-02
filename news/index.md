# Changelog

## RfastHPOCR 0.0.0.9000

- Initial reticulate-backed R bindings to the upstream `FastHPOCR`
  Python package.
- Added helpers for Python dependency installation, ontology indexing,
  annotation, and R-friendly annotation serialization.
- Added hybrid harness primitives for candidate tables, structured
  adjudication prompts, JSON parsing, provider/model run logs, and
  token/reasoning-token usage metadata.
- Added a real-HPO README stress test with a live `piknit` / Pi
  adjudication call plus an `index-real-hpo` Make target for cached
  full-HPO indexing.
