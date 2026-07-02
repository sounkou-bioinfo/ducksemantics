# Build a FastHPOCR SNOMED index

Wraps `FastHPOCR.IndexSNOMED.IndexSNOMED` and creates an index file from
SNOMED description and relationship tables. Upstream FastHPOCR requires
one or more `root_concepts` for SNOMED indexing.

## Usage

``` r
index_snomed(
  description_file,
  relations_file,
  output_dir,
  root_concepts,
  index_config = list(),
  allow_3_letter_acronyms = NULL,
  include_top_level_category = NULL,
  allow_duplicate_entries = NULL,
  compress_index = NULL,
  external_syn_file = NULL,
  create_output_dir = TRUE
)
```

## Arguments

- description_file:

  Path to the SNOMED description file, for example
  `sct2_Description_Full-en_INT_20230630.txt`.

- relations_file:

  Path to the SNOMED relationship file, for example
  `sct2_Relationship_Full_INT_20230630.txt`.

- output_dir:

  Directory where `snomed.index` or `snomed.index.gz` will be written.

- root_concepts:

  Character vector of SNOMED root concepts. Required.

- index_config:

  Optional named list of upstream FastHPOCR index options.

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
  index_snomed(
    "sct2_Description_Full-en_INT_20230630.txt",
    "sct2_Relationship_Full_INT_20230630.txt",
    "snomed-index",
    root_concepts = "SCTID:64572001"
  )
}
```
