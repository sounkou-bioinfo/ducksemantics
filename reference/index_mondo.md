# Build a FastHPOCR MONDO index

Wraps `FastHPOCR.IndexMONDO.IndexMONDO` and creates an index file from a
MONDO `.obo` file.

## Usage

``` r
index_mondo(
  mondo_file,
  output_dir,
  index_config = list(),
  allow_3_letter_acronyms = NULL,
  allow_duplicate_entries = NULL,
  compress_index = NULL,
  external_syn_file = NULL,
  create_output_dir = TRUE
)
```

## Arguments

- mondo_file:

  Path to `mondo.obo`.

- output_dir:

  Directory where `mondo.index` or `mondo.index.gz` will be written.

- index_config:

  Optional named list of upstream FastHPOCR index options.

- allow_3_letter_acronyms:

  Include potentially ambiguous three-letter acronyms.

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
  index_mondo("mondo.obo", "mondo-index", compress_index = TRUE)
}
```
