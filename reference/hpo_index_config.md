# Build a FastHPOCR index configuration list

Creates an R list using the exact configuration keys expected by the
upstream Python package. The helper keeps the R API snake_case while
emitting the `camelCase` names consumed by `FastHPOCR`.

## Usage

``` r
hpo_index_config(
  root_concepts = NULL,
  allow_3_letter_acronyms = NULL,
  include_top_level_category = NULL,
  allow_duplicate_entries = NULL,
  compress_index = NULL,
  external_syn_file = NULL,
  ...
)
```

## Arguments

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

- ...:

  Additional named configuration entries passed through unchanged.

## Value

A named list suitable for the `index_config` argument of the indexing
functions.

## Examples

``` r
hpo_index_config(
  root_concepts = "HP:0000119",
  include_top_level_category = TRUE,
  compress_index = TRUE
)
#> $rootConcepts
#> [1] "HP:0000119"
#> 
#> $includeTopLevelCategory
#> [1] TRUE
#> 
#> $compressIndex
#> [1] TRUE
#> 
```
