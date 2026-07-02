# Build a FastHPOCR HPO index

Wraps `FastHPOCR.IndexHPO.IndexHPO` and creates an index file from an
`hp.obo` ontology file. The returned path is the expected index
location.

## Usage

``` r
index_hpo(
  hpo_file,
  output_dir,
  index_config = list(),
  root_concepts = NULL,
  allow_3_letter_acronyms = NULL,
  include_top_level_category = NULL,
  allow_duplicate_entries = NULL,
  compress_index = NULL,
  external_syn_file = NULL,
  create_output_dir = TRUE
)
```

## Arguments

- hpo_file:

  Path to `hp.obo`.

- output_dir:

  Directory where `hp.index` or `hp.index.gz` will be written.

- index_config:

  Optional named list of upstream FastHPOCR index options.

- root_concepts:

  Optional character vector of ontology root concepts to index. For HPO,
  these look like `"HP:0000119"`; for SNOMED, these look like
  `"SCTID:64572001"` or `"64572001"`.

- allow_3_letter_acronyms:

  Include potentially ambiguous three-letter acronyms.

- include_top_level_category:

  Include top-level category metadata when the upstream indexer supports
  it.

- allow_duplicate_entries:

  Allow duplicate labels or synonyms to be indexed.

- compress_index:

  Write a gzip-compressed index.

- external_syn_file:

  Optional path to an external synonym file. This is passed using the
  upstream key `externalSynFile`.

- create_output_dir:

  Create `output_dir` if needed.

## Value

Invisibly, the expected output index path.

## Examples

``` r
if (FALSE) {
  index_hpo("hp.obo", "hpo-index", compress_index = TRUE)
}
```
