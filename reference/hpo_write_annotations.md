# Write or print FastHPOCR annotations

Serializes R annotation records using the same tab-separated text format
as upstream `FastHPOCR.HPOAnnotator.serialize()`:
`[start:end] id label span`, where `start` and `end` are the original
Python-style offsets (`start_offset`, `end_offset`).

## Usage

``` r
hpo_write_annotations(annotations, file, include_categories = FALSE)

hpo_print_annotations(annotations, include_categories = FALSE)
```

## Arguments

- annotations:

  An annotation data frame or list as above.

- file:

  Output file path.

- include_categories:

  Include category metadata when present.

## Value

Invisibly, `file`.

Invisibly, `annotations`.

## Examples

``` r
ann <- data.frame(
  span = "short stature",
  id = "HP:0004322",
  label = "Short stature",
  start = 1L,
  end = 13L,
  start_offset = 0L,
  end_offset = 13L,
  stringsAsFactors = FALSE
)
ann$categories <- I(list(list()))
out <- tempfile()
hpo_write_annotations(ann, out)
readLines(out)
#> [1] "[0:13]\tHP:0004322\tShort stature\tshort stature"
```
