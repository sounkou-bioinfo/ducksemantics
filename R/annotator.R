#' Create a FastHPOCR annotator
#'
#' Loads a FastHPOCR concept-recognition index and returns a small R wrapper
#' around the underlying Python `HPOAnnotator` instance. The same upstream class
#' is used for HPO, MONDO, ORPHANET, and SNOMED indexes.
#'
#' @param index_location Path to a FastHPOCR index file, compressed or
#'   uncompressed.
#' @return An object of class `fast_hpo_cr_annotator`.
#' @export
#' @examples
#' if (FALSE) {
#'   ann <- hpo_annotator("hp.index.gz")
#' }
hpo_annotator <- function(index_location) {
  index_location <- normalize_existing_file(index_location, "index_location")
  mod <- fast_hpo_cr_import("FastHPOCR.HPOAnnotator", convert = FALSE)
  py <- mod$HPOAnnotator(index_location)
  structure(
    list(
      py = py,
      index_location = index_location
    ),
    class = "fast_hpo_cr_annotator"
  )
}

#' @export
print.fast_hpo_cr_annotator <- function(x, ...) {
  cat("<fast_hpo_cr_annotator>\n")
  cat("  index: ", x$index_location, "\n", sep = "")
  invisible(x)
}

#' Annotate free text with a FastHPOCR index
#'
#' Runs the upstream `HPOAnnotator$annotate()` method and converts the returned
#' Python annotation objects to an R data frame by default. Set `output =
#' "python"` to keep the raw Python result for advanced reticulate workflows.
#'
#' FastHPOCR reports offsets as Python-style zero-based, end-exclusive spans.
#' The default `offsets = "r"` adds R-style `start` and `end` columns that are
#' one-based and inclusive. The original Python offsets are always preserved as
#' `start_offset` and `end_offset`.
#'
#' @param annotator A `fast_hpo_cr_annotator` returned by `hpo_annotator()`, or
#'   a path to an index file.
#' @param text Character scalar to annotate.
#' @param longest_match If `TRUE`, ask FastHPOCR to keep only the longest match
#'   among overlapping candidates.
#' @param output Return type: an R `data.frame`, an R `list`, or the raw Python
#'   object.
#' @param offsets Coordinate convention for the user-facing `start` and `end`
#'   columns when `output` is not `"python"`.
#' @return A data frame by default, with columns `span`, `id`, `label`, `start`,
#'   `end`, `start_offset`, `end_offset`, and list-column `categories`.
#' @export
#' @examples
#' if (FALSE) {
#'   ann <- hpo_annotator("hp.index.gz")
#'   hpo_annotate(ann, "The patient has short stature and seizures.")
#' }
hpo_annotate <- function(annotator,
                         text,
                         longest_match = FALSE,
                         output = c("data.frame", "list", "python"),
                         offsets = c("r", "python")) {
  output <- match.arg(output)
  offsets <- match.arg(offsets)
  check_scalar_character(text, "text")
  check_flag(longest_match, "longest_match")

  if (is.character(annotator)) {
    annotator <- hpo_annotator(annotator)
  }
  if (!inherits(annotator, "fast_hpo_cr_annotator")) {
    stop("`annotator` must be a fast_hpo_cr_annotator or index path.", call. = FALSE)
  }

  result <- annotator$py$annotate(text, longestMatch = longest_match)
  if (identical(output, "python")) {
    return(result)
  }

  records <- py_annotations_to_records(result, offsets = offsets)
  if (identical(output, "list")) {
    return(records)
  }

  records_to_data_frame(records)
}

#' Write or print FastHPOCR annotations
#'
#' Serializes R annotation records using the same tab-separated text format as
#' upstream `FastHPOCR.HPOAnnotator.serialize()`:
#' `[start:end] id label span`, where `start` and `end` are the original
#' Python-style offsets (`start_offset`, `end_offset`).
#'
#' @param annotations An annotation data frame returned by `hpo_annotate()`, or
#'   the corresponding list output from `hpo_annotate(output = "list")`.
#' @param file Output file path.
#' @param include_categories Include category metadata when present.
#' @return Invisibly, `file`.
#' @export
#' @examples
#' ann <- data.frame(
#'   span = "short stature",
#'   id = "HP:0004322",
#'   label = "Short stature",
#'   start = 1L,
#'   end = 13L,
#'   start_offset = 0L,
#'   end_offset = 13L,
#'   stringsAsFactors = FALSE
#' )
#' ann$categories <- I(list(list()))
#' out <- tempfile()
#' hpo_write_annotations(ann, out)
#' readLines(out)
hpo_write_annotations <- function(annotations, file, include_categories = FALSE) {
  check_scalar_character(file, "file")
  check_flag(include_categories, "include_categories")
  lines <- format_annotation_lines(annotations, include_categories = include_categories)
  writeLines(lines, con = file, useBytes = TRUE)
  invisible(file)
}

#' @rdname hpo_write_annotations
#' @param annotations An annotation data frame or list as above.
#' @return Invisibly, `annotations`.
#' @export
hpo_print_annotations <- function(annotations, include_categories = FALSE) {
  check_flag(include_categories, "include_categories")
  cat(paste(format_annotation_lines(annotations, include_categories), collapse = "\n"))
  if (length(format_annotation_lines(annotations, include_categories))) {
    cat("\n")
  }
  invisible(annotations)
}

py_annotations_to_records <- function(x, offsets = c("r", "python")) {
  offsets <- match.arg(offsets)
  objs <- reticulate::py_to_r(x)
  if (length(objs) == 0L) {
    return(list())
  }

  lapply(objs, py_annotation_to_record, offsets = offsets)
}

py_annotation_to_record <- function(obj, offsets = c("r", "python")) {
  offsets <- match.arg(offsets)
  start_offset <- as.integer(reticulate::py_to_r(obj$getStartOffset()))
  end_offset <- as.integer(reticulate::py_to_r(obj$getEndOffset()))
  if (identical(offsets, "r")) {
    start <- start_offset + 1L
    end <- end_offset
  } else {
    start <- start_offset
    end <- end_offset
  }

  list(
    span = as.character(reticulate::py_to_r(obj$getTextSpan())),
    id = as.character(reticulate::py_to_r(obj$getHPOUri())),
    label = as.character(reticulate::py_to_r(obj$getHPOLabel())),
    start = start,
    end = end,
    start_offset = start_offset,
    end_offset = end_offset,
    categories = normalize_categories(reticulate::py_to_r(obj$getCategories()))
  )
}

records_to_data_frame <- function(records) {
  if (length(records) == 0L) {
    out <- data.frame(
      span = character(),
      id = character(),
      label = character(),
      start = integer(),
      end = integer(),
      start_offset = integer(),
      end_offset = integer(),
      stringsAsFactors = FALSE
    )
    out$categories <- I(list())
    return(out)
  }

  out <- data.frame(
    span = vapply(records, `[[`, character(1), "span"),
    id = vapply(records, `[[`, character(1), "id"),
    label = vapply(records, `[[`, character(1), "label"),
    start = vapply(records, `[[`, integer(1), "start"),
    end = vapply(records, `[[`, integer(1), "end"),
    start_offset = vapply(records, `[[`, integer(1), "start_offset"),
    end_offset = vapply(records, `[[`, integer(1), "end_offset"),
    stringsAsFactors = FALSE
  )
  out$categories <- I(lapply(records, `[[`, "categories"))
  out
}

annotations_to_records <- function(annotations) {
  if (is.data.frame(annotations)) {
    required <- c("span", "id", "label", "start_offset", "end_offset")
    missing <- setdiff(required, names(annotations))
    if (length(missing)) {
      stop(
        "`annotations` is missing required column(s): ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
    categories <- if ("categories" %in% names(annotations)) {
      annotations$categories
    } else {
      vector("list", nrow(annotations))
    }
    return(lapply(seq_len(nrow(annotations)), function(i) {
      list(
        span = as.character(annotations$span[[i]]),
        id = as.character(annotations$id[[i]]),
        label = as.character(annotations$label[[i]]),
        start_offset = as.integer(annotations$start_offset[[i]]),
        end_offset = as.integer(annotations$end_offset[[i]]),
        categories = normalize_categories(categories[[i]])
      )
    }))
  }

  if (is.list(annotations)) {
    return(lapply(annotations, function(x) {
      required <- c("span", "id", "label", "start_offset", "end_offset")
      missing <- setdiff(required, names(x))
      if (length(missing)) {
        stop(
          "annotation record is missing required field(s): ",
          paste(missing, collapse = ", "),
          call. = FALSE
        )
      }
      x$categories <- normalize_categories(x$categories)
      x
    }))
  }

  stop("`annotations` must be a data frame or list of annotation records.", call. = FALSE)
}

format_annotation_lines <- function(annotations, include_categories = FALSE) {
  records <- annotations_to_records(annotations)
  vapply(records, format_annotation_line, character(1), include_categories = include_categories)
}

format_annotation_line <- function(record, include_categories = FALSE) {
  line <- paste0(
    "[", record$start_offset, ":", record$end_offset, "]\t",
    record$id, "\t",
    record$label, "\t",
    record$span
  )

  if (isTRUE(include_categories) && length(record$categories)) {
    cat_text <- format_categories(record$categories)
    if (nzchar(cat_text)) {
      line <- paste0(line, "\t", cat_text)
    }
  }

  line
}

normalize_categories <- function(categories) {
  if (is.null(categories) || length(categories) == 0L) {
    return(list())
  }
  if (is.data.frame(categories)) {
    categories <- split(categories, seq_len(nrow(categories)))
  }
  lapply(categories, function(category) {
    if (is.null(category) || length(category) == 0L) {
      return(list())
    }
    if (is.data.frame(category)) {
      category <- as.list(category[1L, , drop = TRUE])
    }
    as.list(category)
  })
}

format_categories <- function(categories) {
  categories <- normalize_categories(categories)
  pieces <- vapply(categories, function(category) {
    uri <- category$uri %||% category$id %||% ""
    label <- category$label %||% ""
    if (!nzchar(uri) && !nzchar(label)) {
      return("")
    }
    paste0(uri, " (", label, ")")
  }, character(1))
  pieces <- pieces[nzchar(pieces)]
  if (!length(pieces)) {
    return("")
  }
  paste0("[", paste(pieces, collapse = " | "), "]")
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    y
  } else {
    as.character(x[[1L]])
  }
}
