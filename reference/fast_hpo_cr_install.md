# Install the Python FastHPOCR dependency set

Installs `FastHPOCR` plus its undeclared Python runtime dependencies
into a named reticulate environment. This helper is for users who prefer
a persistent managed environment; ordinary package use relies on
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html)
in `.onLoad()` and can use reticulate's ephemeral virtual environment.

## Usage

``` r
fast_hpo_cr_install(
  envname = "r-fast-hpo-cr",
  method = c("auto", "virtualenv", "conda"),
  source = c("pypi", "github"),
  min_version = FAST_HPO_CR_MIN_VERSION,
  ref = "main",
  ...
)
```

## Arguments

- envname:

  Reticulate environment name passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

- method:

  Environment backend passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

- source:

  Install the released PyPI package or the upstream GitHub source.

- min_version:

  Minimum PyPI version when `source = "pypi"`. Use `NULL` for unpinned.

- ref:

  Git ref when `source = "github"`.

- ...:

  Additional arguments passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

## Value

Invisibly, the Python package specifications that were requested.

## Details

Set `source = "github"` to install from the upstream GitHub repository
subdirectory that contains `setup.py`.

If Python has already been initialized in the current R session, restart
R after installing and before loading an annotator so that reticulate
can bind to the intended environment. To select the named environment
explicitly, call
[`fast_hpo_cr_use_env()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_use_env.md)
before Python is initialized.

## Examples

``` r
if (FALSE) {
  fast_hpo_cr_install()
  fast_hpo_cr_install(source = "github")
}
```
