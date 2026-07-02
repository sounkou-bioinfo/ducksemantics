# Python packages required by RfastHPOCR

Returns the Python package requirements used by
[`fast_hpo_cr_install()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_install.md)
and advertised to reticulate via
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html).
The upstream `FastHPOCR` package currently does not declare all runtime
dependencies on PyPI, so `pronto` and `tqdm` are listed explicitly.

## Usage

``` r
fast_hpo_cr_python_packages(min_version = FAST_HPO_CR_MIN_VERSION)
```

## Arguments

- min_version:

  Minimum Python `FastHPOCR` version to require. Use `NULL` to request
  an unpinned `FastHPOCR` installation.

## Value

A character vector of Python package requirements.

## Examples

``` r
fast_hpo_cr_python_packages()
#> [1] "FastHPOCR>=0.1.4" "pronto"           "tqdm"            
```
