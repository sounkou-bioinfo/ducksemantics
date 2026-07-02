# Build a FastHPOCR ORPHANET index

Wraps `FastHPOCR.IndexORPHANET.IndexORPHANET` and creates an index file
from an unpacked Orphanet JSON data file such as `en_product1.json`.

## Usage

``` r
index_orphanet(
  orpha_data_file,
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

- orpha_data_file:

  Path to the unpacked Orphanet JSON data file.

- output_dir:

  Directory where `orpha.index` or `orpha.index.gz` will be written.

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
  index_orphanet("en_product1.json", "orpha-index", compress_index = TRUE)
}
```
