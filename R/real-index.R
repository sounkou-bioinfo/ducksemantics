#' Download and build a cached full HPO FastHPOCR index
#'
#' Downloads the current real `hp.obo` file if needed, builds a FastHPOCR HPO
#' index if needed, and returns the cached index path. This helper is intended
#' for real local analyses, README stress tests, and benchmark harnesses; it is
#' not run during ordinary package tests because full HPO indexing can take
#' several minutes on a fresh cache.
#'
#' @param cache_dir Directory for `hp.obo` and the generated `index/hp.index`.
#'   Defaults to `RFASTHPOCR_REAL_HPO_DIR`; otherwise it reuses an existing
#'   cached full-HPO index when found, falling back to an R user cache directory.
#' @param rebuild Re-download/rebuild even when cached files already exist.
#' @param quiet Passed to [download_hpo_obo()].
#' @param root_concepts HPO root concepts passed to [index_hpo()]. The default
#'   indexes all phenotypic abnormalities under `HP:0000118`.
#' @param include_top_level_category Passed to [index_hpo()].
#' @param compress_index Passed to [index_hpo()]. Defaults to `FALSE` because
#'   upstream FastHPOCR currently writes the full HPO index uncompressed in this
#'   path.
#' @return A normalized index path. Attributes include `hpo_file`, `cache_dir`,
#'   and `index_dir`.
#' @export
#' @examples
#' if (FALSE) {
#'   index <- hpo_real_index()
#'   ann <- hpo_annotator(index)
#' }
hpo_real_index <- function(cache_dir = default_hpo_real_cache_dir(),
                           rebuild = FALSE,
                           quiet = TRUE,
                           root_concepts = "HP:0000118",
                           include_top_level_category = TRUE,
                           compress_index = FALSE) {
  check_scalar_character(cache_dir, "cache_dir")
  check_flag(rebuild, "rebuild")
  check_flag(quiet, "quiet")
  check_flag(include_top_level_category, "include_top_level_category")
  check_flag(compress_index, "compress_index")

  cache_dir <- normalize_output_dir(cache_dir, create = TRUE, arg = "cache_dir")
  hpo_file <- file.path(cache_dir, "hp.obo")
  index_dir <- normalize_output_dir(file.path(cache_dir, "index"), create = TRUE, arg = "index_dir")
  index_file <- hpo_real_index_path(index_dir, compress_index = compress_index)

  if (isTRUE(rebuild)) {
    unlink(c(hpo_file, index_file), force = TRUE)
    index_file <- file.path(index_dir, paste0("hp.index", if (isTRUE(compress_index)) ".gz" else ""))
  }

  if (!file.exists(hpo_file)) {
    hpo_file <- download_hpo_obo(cache_dir, quiet = quiet)
  } else {
    hpo_file <- normalize_existing_file(hpo_file, "hpo_file")
  }

  if (!file.exists(index_file)) {
    index_file <- index_hpo(
      hpo_file,
      index_dir,
      root_concepts = root_concepts,
      include_top_level_category = include_top_level_category,
      compress_index = compress_index
    )
  } else {
    index_file <- normalize_existing_file(index_file, "index_file")
  }

  structure(
    index_file,
    hpo_file = hpo_file,
    cache_dir = cache_dir,
    index_dir = index_dir,
    class = c("hpo_real_index_path", "character")
  )
}

default_hpo_real_cache_dir <- function() {
  env <- Sys.getenv("RFASTHPOCR_REAL_HPO_DIR", unset = NA_character_)
  if (!is.na(env) && nzchar(env)) {
    return(env)
  }

  legacy_cache <- file.path(path.expand("~"), ".cache", "RfastHPOCR-real-hpo")
  user_cache <- file.path(tools::R_user_dir("RfastHPOCR", "cache"), "real-hpo")
  candidates <- c(legacy_cache, user_cache)
  has_index <- vapply(candidates, function(x) {
    file.exists(file.path(x, "index", "hp.index")) ||
      file.exists(file.path(x, "index", "hp.index.gz"))
  }, logical(1))

  if (any(has_index)) {
    return(candidates[which(has_index)[[1]]])
  }

  user_cache
}

hpo_real_index_path <- function(index_dir, compress_index = FALSE) {
  preferred <- file.path(index_dir, paste0("hp.index", if (isTRUE(compress_index)) ".gz" else ""))
  fallback <- file.path(index_dir, paste0("hp.index", if (isTRUE(compress_index)) "" else ".gz"))
  if (file.exists(preferred)) {
    return(preferred)
  }
  if (file.exists(fallback)) {
    return(fallback)
  }
  preferred
}
