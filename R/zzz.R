.onLoad <- function(libname, pkgname) {
  reticulate::py_require(fast_hpo_cr_python_packages())
}
