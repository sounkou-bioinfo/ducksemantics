check_scalar_character <- function(x, arg = deparse(substitute(x))) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop("`", arg, "` must be a non-empty character scalar.", call. = FALSE)
  }
  invisible(x)
}

check_flag <- function(x, arg = deparse(substitute(x))) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", arg, "` must be TRUE or FALSE.", call. = FALSE)
  }
  invisible(x)
}

normalize_existing_file <- function(path, arg = deparse(substitute(path))) {
  check_scalar_character(path, arg = arg)
  path <- path.expand(path)
  if (!file.exists(path) || !is_file(path)) {
    stop("`", arg, "` does not exist or is not a file: ", path, call. = FALSE)
  }
  normalizePath(path, mustWork = TRUE)
}

normalize_output_dir <- function(path, create = TRUE, arg = deparse(substitute(path))) {
  check_scalar_character(path, arg = arg)
  check_flag(create, arg = "create")
  path <- path.expand(path)
  if (!dir.exists(path)) {
    if (isTRUE(create)) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
    }
    if (!dir.exists(path)) {
      stop("`", arg, "` does not exist and could not be created: ", path, call. = FALSE)
    }
  }
  normalizePath(path, mustWork = TRUE)
}

is_file <- function(path) {
  !dir.exists(path)
}

compact_null <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

merge_index_config <- function(base, override) {
  if (is.null(base)) {
    base <- list()
  }
  if (!is.list(base)) {
    stop("`index_config` must be a named list.", call. = FALSE)
  }
  if (length(base) && (is.null(names(base)) || any(!nzchar(names(base))))) {
    stop("`index_config` must be a named list.", call. = FALSE)
  }
  utils::modifyList(base, compact_null(override))
}

index_config_for_python <- function(cfg) {
  if (is.null(cfg)) {
    return(list())
  }
  out <- cfg
  if (!is.null(out$rootConcepts)) {
    out$rootConcepts <- as.list(as.character(out$rootConcepts))
  }
  out
}

as_nullable_flag <- function(x, arg) {
  if (is.null(x)) {
    return(NULL)
  }
  check_flag(x, arg = arg)
  x
}

index_output_path <- function(output_dir, stem, compress_index) {
  file.path(output_dir, paste0(stem, if (isTRUE(compress_index)) ".gz" else ""))
}

resolve_index_output_path <- function(output_dir, stem, compress_index) {
  expected <- index_output_path(output_dir, stem, compress_index)
  if (file.exists(expected)) {
    return(normalizePath(expected, mustWork = TRUE))
  }

  fallback <- index_output_path(output_dir, stem, FALSE)
  if (!identical(fallback, expected) && file.exists(fallback)) {
    warning(
      "FastHPOCR wrote an uncompressed index even though `compress_index` ",
      "was requested; returning ", fallback,
      call. = FALSE
    )
    return(normalizePath(fallback, mustWork = TRUE))
  }

  expected
}
