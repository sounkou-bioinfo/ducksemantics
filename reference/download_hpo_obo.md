# Download ontology source files for FastHPOCR indexing

These helpers download commonly used ontology source files into a local
directory and return the resulting path. `download_hpo_obo()` downloads
`hp.obo`, `download_mondo_obo()` downloads `mondo.obo`, and
`download_orphanet_product1_xml()` downloads Orphanet `en_product1.xml`.

## Usage

``` r
download_hpo_obo(
  dest_dir = ".",
  filename = "hp.obo",
  overwrite = FALSE,
  url = HPO_OBO_URL,
  quiet = FALSE
)

download_mondo_obo(
  dest_dir = ".",
  filename = "mondo.obo",
  overwrite = FALSE,
  url = MONDO_OBO_URL,
  quiet = FALSE
)

download_orphanet_product1_xml(
  dest_dir = ".",
  filename = "en_product1.xml",
  overwrite = FALSE,
  url = ORPHANET_PRODUCT1_XML_URL,
  quiet = FALSE
)

download_orphanet_product1_json(
  dest_dir = ".",
  xml_file = NULL,
  json_filename = "en_product1.json",
  overwrite = FALSE,
  url = ORPHANET_PRODUCT1_XML_URL,
  quiet = FALSE
)
```

## Arguments

- dest_dir:

  Directory where the file should be written.

- filename:

  Output filename within `dest_dir`.

- overwrite:

  Replace an existing file.

- url:

  Source URL. This is mainly exposed for mirrors and tests.

- quiet:

  Passed to
  [`utils::download.file()`](https://rdrr.io/r/utils/download.file.html).

- xml_file:

  Existing Orphanet XML file. If `NULL`, the XML is downloaded first
  with `download_orphanet_product1_xml()`.

- json_filename:

  Output JSON filename within `dest_dir`.

## Value

The normalized path to the downloaded file.

## Details

FastHPOCR's ORPHANET indexer expects a small JSON shape rather than the
XML served by Orphadata, so `download_orphanet_product1_json()`
downloads the XML and converts the fields used by FastHPOCR.

## Examples

``` r
if (FALSE) {
  hp <- download_hpo_obo("ontologies")
  mondo <- download_mondo_obo("ontologies")
}
if (FALSE) {
  orpha_json <- download_orphanet_product1_json("ontologies")
}
```
