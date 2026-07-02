# Download and build a cached full HPO FastHPOCR index

Downloads the current real `hp.obo` file if needed, builds a FastHPOCR
HPO index if needed, and returns the cached index path. This helper is
intended for real local analyses, README stress tests, and benchmark
harnesses; it is not run during ordinary package tests because full HPO
indexing can take several minutes on a fresh cache.

## Usage

``` r
hpo_real_index(
  cache_dir = default_hpo_real_cache_dir(),
  rebuild = FALSE,
  quiet = TRUE,
  root_concepts = "HP:0000118",
  include_top_level_category = TRUE,
  compress_index = FALSE
)
```

## Arguments

- cache_dir:

  Directory for `hp.obo` and the generated `index/hp.index`. Defaults to
  `RFASTHPOCR_REAL_HPO_DIR`; otherwise it reuses an existing cached
  full-HPO index when found, falling back to an R user cache directory.

- rebuild:

  Re-download/rebuild even when cached files already exist.

- quiet:

  Passed to
  [`download_hpo_obo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_obo.md).

- root_concepts:

  HPO root concepts passed to
  [`index_hpo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_hpo.md).
  The default indexes all phenotypic abnormalities under `HP:0000118`.

- include_top_level_category:

  Passed to
  [`index_hpo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_hpo.md).

- compress_index:

  Passed to
  [`index_hpo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_hpo.md).
  Defaults to `FALSE` because upstream FastHPOCR currently writes the
  full HPO index uncompressed in this path.

## Value

A normalized index path. Attributes include `hpo_file`, `cache_dir`, and
`index_dir`.

## Examples

``` r
if (FALSE) {
  index <- hpo_real_index()
  ann <- hpo_annotator(index)
}
```
