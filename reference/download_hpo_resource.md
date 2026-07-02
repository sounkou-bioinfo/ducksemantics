# Download HPO ontology and annotation resources

Downloads HPO resources documented from the HPO ontology data page. Use
`resource = "obo"` for FastHPOCR indexing; the JSON, OWL, and HPOA/text
resources are included for downstream validation, annotation audit, and
gene/phenotype lookups.

## Usage

``` r
download_hpo_resource(
  resource = c("obo", "json", "owl", "phenotype_hpoa", "genes_to_phenotype",
    "phenotype_to_genes", "genes_to_disease"),
  dest_dir = ".",
  overwrite = FALSE,
  quiet = FALSE
)

download_hpo_json(dest_dir = ".", overwrite = FALSE, quiet = FALSE)

download_hpo_owl(dest_dir = ".", overwrite = FALSE, quiet = FALSE)

download_hpo_phenotype_hpoa(dest_dir = ".", overwrite = FALSE, quiet = FALSE)

download_hpo_genes_to_phenotype(
  dest_dir = ".",
  overwrite = FALSE,
  quiet = FALSE
)

download_hpo_phenotype_to_genes(
  dest_dir = ".",
  overwrite = FALSE,
  quiet = FALSE
)

download_hpo_genes_to_disease(dest_dir = ".", overwrite = FALSE, quiet = FALSE)
```

## Arguments

- resource:

  HPO resource to download.

- dest_dir:

  Directory where the file should be written.

- overwrite:

  Replace an existing file.

- quiet:

  Passed to
  [`utils::download.file()`](https://rdrr.io/r/utils/download.file.html).

## Value

The normalized path to the downloaded file.

## Examples

``` r
if (FALSE) {
  hp_obo <- download_hpo_resource("obo", "ontologies")
  hpoa <- download_hpo_phenotype_hpoa("ontologies")
}
```
