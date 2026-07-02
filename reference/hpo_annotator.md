# Create a FastHPOCR annotator

Loads a FastHPOCR concept-recognition index and returns a small R
wrapper around the underlying Python `HPOAnnotator` instance. The same
upstream class is used for HPO, MONDO, ORPHANET, and SNOMED indexes.

## Usage

``` r
hpo_annotator(index_location)
```

## Arguments

- index_location:

  Path to a FastHPOCR index file, compressed or uncompressed.

## Value

An object of class `fast_hpo_cr_annotator`.

## Examples

``` r
if (FALSE) {
  ann <- hpo_annotator("hp.index.gz")
}
```
