# Annotate free text with a FastHPOCR index

Runs the upstream `HPOAnnotator$annotate()` method and converts the
returned Python annotation objects to an R data frame by default. Set
`output = "python"` to keep the raw Python result for advanced
reticulate workflows.

## Usage

``` r
hpo_annotate(
  annotator,
  text,
  longest_match = FALSE,
  output = c("data.frame", "list", "python"),
  offsets = c("r", "python")
)
```

## Arguments

- annotator:

  A `fast_hpo_cr_annotator` returned by
  [`hpo_annotator()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotator.md),
  or a path to an index file.

- text:

  Character scalar to annotate.

- longest_match:

  If `TRUE`, ask FastHPOCR to keep only the longest match among
  overlapping candidates.

- output:

  Return type: an R `data.frame`, an R `list`, or the raw Python object.

- offsets:

  Coordinate convention for the user-facing `start` and `end` columns
  when `output` is not `"python"`.

## Value

A data frame by default, with columns `span`, `id`, `label`, `start`,
`end`, `start_offset`, `end_offset`, and list-column `categories`.

## Details

FastHPOCR reports offsets as Python-style zero-based, end-exclusive
spans. The default `offsets = "r"` adds R-style `start` and `end`
columns that are one-based and inclusive. The original Python offsets
are always preserved as `start_offset` and `end_offset`.

## Examples

``` r
if (FALSE) {
  ann <- hpo_annotator("hp.index.gz")
  hpo_annotate(ann, "The patient has short stature and seizures.")
}
```
