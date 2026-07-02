FAST_HPO_CR_MIN_VERSION <- "0.1.4"
FAST_HPO_CR_GITHUB <- "https://github.com/tudorgroza/fast_hpo_cr"

#' Python packages required by RfastHPOCR
#'
#' Returns the Python package requirements used by `fast_hpo_cr_install()` and
#' advertised to reticulate via [reticulate::py_require()]. The upstream
#' `FastHPOCR` package currently does not declare all runtime dependencies on
#' PyPI, so `pronto` and `tqdm` are listed explicitly.
#'
#' @param min_version Minimum Python `FastHPOCR` version to require. Use `NULL`
#'   to request an unpinned `FastHPOCR` installation.
#' @return A character vector of Python package requirements.
#' @export
#' @examples
#' fast_hpo_cr_python_packages()
fast_hpo_cr_python_packages <- function(min_version = FAST_HPO_CR_MIN_VERSION) {
  fast_hpo_cr <- if (is.null(min_version) || identical(min_version, "")) {
    "FastHPOCR"
  } else {
    paste0("FastHPOCR>=", min_version)
  }

  c(fast_hpo_cr, "pronto", "tqdm")
}

#' Install the Python FastHPOCR dependency set
#'
#' Installs `FastHPOCR` plus its undeclared Python runtime dependencies into a
#' named reticulate environment. This helper is for users who prefer a persistent
#' managed environment; ordinary package use relies on [reticulate::py_require()]
#' in `.onLoad()` and can use reticulate's ephemeral virtual environment.
#'
#' Set `source = "github"` to install from the upstream GitHub repository
#' subdirectory that contains `setup.py`.
#'
#' If Python has already been initialized in the current R session, restart R
#' after installing and before loading an annotator so that reticulate can bind
#' to the intended environment. To select the named environment explicitly, call
#' `fast_hpo_cr_use_env()` before Python is initialized.
#'
#' @param envname Reticulate environment name passed to [reticulate::py_install()].
#' @param method Environment backend passed to [reticulate::py_install()].
#' @param source Install the released PyPI package or the upstream GitHub source.
#' @param min_version Minimum PyPI version when `source = "pypi"`. Use `NULL`
#'   for unpinned.
#' @param ref Git ref when `source = "github"`.
#' @param ... Additional arguments passed to [reticulate::py_install()].
#' @return Invisibly, the Python package specifications that were requested.
#' @export
#' @examples
#' if (FALSE) {
#'   fast_hpo_cr_install()
#'   fast_hpo_cr_install(source = "github")
#' }
fast_hpo_cr_install <- function(envname = "r-fast-hpo-cr",
                                method = c("auto", "virtualenv", "conda"),
                                source = c("pypi", "github"),
                                min_version = FAST_HPO_CR_MIN_VERSION,
                                ref = "main",
                                ...) {
  method <- match.arg(method)
  source <- match.arg(source)

  packages <- switch(
    source,
    pypi = fast_hpo_cr_python_packages(min_version = min_version),
    github = c(
      sprintf(
        "git+%s.git@%s#subdirectory=pypi/FastHPOCR",
        FAST_HPO_CR_GITHUB,
        ref
      ),
      "pronto",
      "tqdm"
    )
  )

  if (reticulate::py_available(initialize = FALSE)) {
    warning(
      "Python is already initialized in this R session; restart R after ",
      "installing if reticulate is bound to the wrong environment.",
      call. = FALSE
    )
  }

  reticulate::py_install(
    packages = packages,
    envname = envname,
    method = method,
    pip = TRUE,
    ...
  )

  invisible(packages)
}

#' Select a named reticulate environment for FastHPOCR
#'
#' Use this only when you want a persistent Python environment instead of the
#' ephemeral environment created from `py_require()` declarations. It must be
#' called before Python is initialized in the current R session.
#'
#' @param envname Environment name.
#' @param method Environment backend to select.
#' @param required Passed to [reticulate::use_virtualenv()] or
#'   [reticulate::use_condaenv()].
#' @return Invisibly, `envname`.
#' @export
#' @examples
#' if (FALSE) {
#'   fast_hpo_cr_install(method = "virtualenv")
#'   fast_hpo_cr_use_env(method = "virtualenv")
#' }
fast_hpo_cr_use_env <- function(envname = "r-fast-hpo-cr",
                                method = c("virtualenv", "conda"),
                                required = TRUE) {
  method <- match.arg(method)
  check_scalar_character(envname, "envname")
  check_flag(required, "required")

  if (reticulate::py_available(initialize = FALSE)) {
    stop(
      "Python is already initialized in this R session; call ",
      "fast_hpo_cr_use_env() before any reticulate import or restart R.",
      call. = FALSE
    )
  }

  switch(
    method,
    virtualenv = reticulate::use_virtualenv(envname, required = required),
    conda = reticulate::use_condaenv(envname, required = required)
  )

  invisible(envname)
}

#' Test whether the FastHPOCR Python module can be imported
#'
#' @param error If `TRUE`, throw an informative error when the Python dependency
#'   set is unavailable.
#' @return `TRUE` if `FastHPOCR.HPOAnnotator` imports successfully, otherwise
#'   `FALSE`.
#' @export
#' @examplesIf interactive()
#' fast_hpo_cr_available()
fast_hpo_cr_available <- function(error = FALSE) {
  last_error <- NULL
  ok <- tryCatch(
    {
      reticulate::py_module_available("FastHPOCR") &&
        !inherits(
          try(reticulate::import("FastHPOCR.HPOAnnotator", convert = FALSE), silent = TRUE),
          "try-error"
        )
    },
    error = function(e) {
      last_error <<- e
      FALSE
    }
  )

  if (!isTRUE(ok) && isTRUE(error)) {
    if (is.null(last_error)) {
      last_error <- simpleError("Python module 'FastHPOCR.HPOAnnotator' was not importable")
    }
    stop(fast_hpo_cr_import_message("FastHPOCR.HPOAnnotator", last_error), call. = FALSE)
  }

  isTRUE(ok)
}

#' Show reticulate's active Python configuration
#'
#' @return The object returned by [reticulate::py_config()].
#' @export
#' @examplesIf interactive()
#' if (fast_hpo_cr_available()) {
#'   fast_hpo_cr_config()
#' }
fast_hpo_cr_config <- function() {
  reticulate::py_config()
}

fast_hpo_cr_import <- function(module, convert = FALSE) {
  tryCatch(
    reticulate::import(module, convert = convert),
    error = function(e) {
      stop(fast_hpo_cr_import_message(module, e), call. = FALSE)
    }
  )
}

fast_hpo_cr_import_message <- function(module, error) {
  paste0(
    "Could not import Python module '", module, "'.\n",
    "Install the Python dependency set with fast_hpo_cr_install(), or configure ",
    "reticulate to use an environment containing: ",
    paste(fast_hpo_cr_python_packages(), collapse = ", "),
    ".\nUnderlying Python/reticulate error: ", conditionMessage(error)
  )
}
