# Select a named reticulate environment for FastHPOCR

Use this only when you want a persistent Python environment instead of
the ephemeral environment created from `py_require()` declarations. It
must be called before Python is initialized in the current R session.

## Usage

``` r
fast_hpo_cr_use_env(
  envname = "r-fast-hpo-cr",
  method = c("virtualenv", "conda"),
  required = TRUE
)
```

## Arguments

- envname:

  Environment name.

- method:

  Environment backend to select.

- required:

  Passed to
  [`reticulate::use_virtualenv()`](https://rstudio.github.io/reticulate/reference/use_python.html)
  or
  [`reticulate::use_condaenv()`](https://rstudio.github.io/reticulate/reference/use_python.html).

## Value

Invisibly, `envname`.

## Examples

``` r
if (FALSE) {
  fast_hpo_cr_install(method = "virtualenv")
  fast_hpo_cr_use_env(method = "virtualenv")
}
```
