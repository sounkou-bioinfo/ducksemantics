# Test whether the FastHPOCR Python module can be imported

Test whether the FastHPOCR Python module can be imported

## Usage

``` r
fast_hpo_cr_available(error = FALSE)
```

## Arguments

- error:

  If `TRUE`, throw an informative error when the Python dependency set
  is unavailable.

## Value

`TRUE` if `FastHPOCR.HPOAnnotator` imports successfully, otherwise
`FALSE`.

## Examples

``` r
if (FALSE) { # interactive()
fast_hpo_cr_available()
}
```
