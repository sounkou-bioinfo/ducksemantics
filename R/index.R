#' Build a FastHPOCR index configuration list
#'
#' Creates an R list using the exact configuration keys expected by the upstream
#' Python package. The helper keeps the R API snake_case while emitting the
#' `camelCase` names consumed by `FastHPOCR`.
#'
#' @param root_concepts Optional character vector of ontology root concepts to
#'   index. For HPO, these look like `"HP:0000119"`; for SNOMED, these look
#'   like `"SCTID:64572001"` or `"64572001"`.
#' @param allow_3_letter_acronyms Include potentially ambiguous three-letter
#'   acronyms.
#' @param include_top_level_category Include top-level category metadata when
#'   the upstream indexer supports it.
#' @param allow_duplicate_entries Allow duplicate labels or synonyms to be
#'   indexed.
#' @param compress_index Write a gzip-compressed index.
#' @param external_syn_file Optional path to an external synonym file. This is
#'   passed using the upstream key `externalSynFile`.
#' @param ... Additional named configuration entries passed through unchanged.
#' @return A named list suitable for the `index_config` argument of the indexing
#'   functions.
#' @export
#' @examples
#' hpo_index_config(
#'   root_concepts = "HP:0000119",
#'   include_top_level_category = TRUE,
#'   compress_index = TRUE
#' )
hpo_index_config <- function(root_concepts = NULL,
                             allow_3_letter_acronyms = NULL,
                             include_top_level_category = NULL,
                             allow_duplicate_entries = NULL,
                             compress_index = NULL,
                             external_syn_file = NULL,
                             ...) {
  extra <- list(...)
  if (length(extra) && (is.null(names(extra)) || any(!nzchar(names(extra))))) {
    stop("`...` entries must be named.", call. = FALSE)
  }

  cfg <- extra
  if (!is.null(root_concepts)) {
    cfg$rootConcepts <- as.character(root_concepts)
  }
  if (!is.null(allow_3_letter_acronyms)) {
    cfg$allow3LetterAcronyms <- as_nullable_flag(
      allow_3_letter_acronyms,
      "allow_3_letter_acronyms"
    )
  }
  if (!is.null(include_top_level_category)) {
    cfg$includeTopLevelCategory <- as_nullable_flag(
      include_top_level_category,
      "include_top_level_category"
    )
  }
  if (!is.null(allow_duplicate_entries)) {
    cfg$allowDuplicateEntries <- as_nullable_flag(
      allow_duplicate_entries,
      "allow_duplicate_entries"
    )
  }
  if (!is.null(compress_index)) {
    cfg$compressIndex <- as_nullable_flag(compress_index, "compress_index")
  }
  if (!is.null(external_syn_file)) {
    cfg$externalSynFile <- normalize_existing_file(external_syn_file, "external_syn_file")
  }

  cfg
}

#' Build a FastHPOCR HPO index
#'
#' Wraps `FastHPOCR.IndexHPO.IndexHPO` and creates an index file from an `hp.obo`
#' ontology file. The returned path is the expected index location.
#'
#' @param hpo_file Path to `hp.obo`.
#' @param output_dir Directory where `hp.index` or `hp.index.gz` will be written.
#' @param index_config Optional named list of upstream FastHPOCR index options.
#' @param create_output_dir Create `output_dir` if needed.
#' @inheritParams hpo_index_config
#' @return Invisibly, the expected output index path.
#' @export
#' @examples
#' if (FALSE) {
#'   index_hpo("hp.obo", "hpo-index", compress_index = TRUE)
#' }
index_hpo <- function(hpo_file,
                      output_dir,
                      index_config = list(),
                      root_concepts = NULL,
                      allow_3_letter_acronyms = NULL,
                      include_top_level_category = NULL,
                      allow_duplicate_entries = NULL,
                      compress_index = NULL,
                      external_syn_file = NULL,
                      create_output_dir = TRUE) {
  hpo_file <- normalize_existing_file(hpo_file, "hpo_file")
  output_dir <- normalize_output_dir(output_dir, create = create_output_dir, arg = "output_dir")
  cfg <- merge_index_config(
    index_config,
    hpo_index_config(
      root_concepts = root_concepts,
      allow_3_letter_acronyms = allow_3_letter_acronyms,
      include_top_level_category = include_top_level_category,
      allow_duplicate_entries = allow_duplicate_entries,
      compress_index = compress_index,
      external_syn_file = external_syn_file
    )
  )

  mod <- fast_hpo_cr_import("FastHPOCR.IndexHPO", convert = FALSE)
  indexer <- mod$IndexHPO(hpo_file, output_dir, index_config_for_python(cfg))
  indexer$index()

  invisible(resolve_index_output_path(output_dir, "hp.index", isTRUE(cfg$compressIndex)))
}

#' Build a FastHPOCR MONDO index
#'
#' Wraps `FastHPOCR.IndexMONDO.IndexMONDO` and creates an index file from a
#' MONDO `.obo` file.
#'
#' @param mondo_file Path to `mondo.obo`.
#' @param output_dir Directory where `mondo.index` or `mondo.index.gz` will be written.
#' @param index_config Optional named list of upstream FastHPOCR index options.
#' @param create_output_dir Create `output_dir` if needed.
#' @inheritParams hpo_index_config
#' @return Invisibly, the expected output index path.
#' @export
#' @examples
#' if (FALSE) {
#'   index_mondo("mondo.obo", "mondo-index", compress_index = TRUE)
#' }
index_mondo <- function(mondo_file,
                        output_dir,
                        index_config = list(),
                        allow_3_letter_acronyms = NULL,
                        allow_duplicate_entries = NULL,
                        compress_index = NULL,
                        external_syn_file = NULL,
                        create_output_dir = TRUE) {
  mondo_file <- normalize_existing_file(mondo_file, "mondo_file")
  output_dir <- normalize_output_dir(output_dir, create = create_output_dir, arg = "output_dir")
  cfg <- merge_index_config(
    index_config,
    hpo_index_config(
      allow_3_letter_acronyms = allow_3_letter_acronyms,
      allow_duplicate_entries = allow_duplicate_entries,
      compress_index = compress_index,
      external_syn_file = external_syn_file
    )
  )

  mod <- fast_hpo_cr_import("FastHPOCR.IndexMONDO", convert = FALSE)
  indexer <- mod$IndexMONDO(mondo_file, output_dir, index_config_for_python(cfg))
  indexer$index()

  invisible(resolve_index_output_path(output_dir, "mondo.index", isTRUE(cfg$compressIndex)))
}

#' Build a FastHPOCR ORPHANET index
#'
#' Wraps `FastHPOCR.IndexORPHANET.IndexORPHANET` and creates an index file from
#' an unpacked Orphanet JSON data file such as `en_product1.json`.
#'
#' @param orpha_data_file Path to the unpacked Orphanet JSON data file.
#' @param output_dir Directory where `orpha.index` or `orpha.index.gz` will be written.
#' @param index_config Optional named list of upstream FastHPOCR index options.
#' @param create_output_dir Create `output_dir` if needed.
#' @inheritParams hpo_index_config
#' @return Invisibly, the expected output index path.
#' @export
#' @examples
#' if (FALSE) {
#'   index_orphanet("en_product1.json", "orpha-index", compress_index = TRUE)
#' }
index_orphanet <- function(orpha_data_file,
                           output_dir,
                           index_config = list(),
                           allow_3_letter_acronyms = NULL,
                           allow_duplicate_entries = NULL,
                           compress_index = NULL,
                           external_syn_file = NULL,
                           create_output_dir = TRUE) {
  orpha_data_file <- normalize_existing_file(orpha_data_file, "orpha_data_file")
  output_dir <- normalize_output_dir(output_dir, create = create_output_dir, arg = "output_dir")
  cfg <- merge_index_config(
    index_config,
    hpo_index_config(
      allow_3_letter_acronyms = allow_3_letter_acronyms,
      allow_duplicate_entries = allow_duplicate_entries,
      compress_index = compress_index,
      external_syn_file = external_syn_file
    )
  )

  mod <- fast_hpo_cr_import("FastHPOCR.IndexORPHANET", convert = FALSE)
  indexer <- mod$IndexORPHANET(orpha_data_file, output_dir, index_config_for_python(cfg))
  indexer$index()

  invisible(resolve_index_output_path(output_dir, "orpha.index", isTRUE(cfg$compressIndex)))
}

#' Build a FastHPOCR SNOMED index
#'
#' Wraps `FastHPOCR.IndexSNOMED.IndexSNOMED` and creates an index file from
#' SNOMED description and relationship tables. Upstream FastHPOCR requires one
#' or more `root_concepts` for SNOMED indexing.
#'
#' @param description_file Path to the SNOMED description file, for example
#'   `sct2_Description_Full-en_INT_20230630.txt`.
#' @param relations_file Path to the SNOMED relationship file, for example
#'   `sct2_Relationship_Full_INT_20230630.txt`.
#' @param output_dir Directory where `snomed.index` or `snomed.index.gz` will be written.
#' @param index_config Optional named list of upstream FastHPOCR index options.
#' @param root_concepts Character vector of SNOMED root concepts. Required.
#' @param create_output_dir Create `output_dir` if needed.
#' @inheritParams hpo_index_config
#' @return Invisibly, the expected output index path.
#' @export
#' @examples
#' if (FALSE) {
#'   index_snomed(
#'     "sct2_Description_Full-en_INT_20230630.txt",
#'     "sct2_Relationship_Full_INT_20230630.txt",
#'     "snomed-index",
#'     root_concepts = "SCTID:64572001"
#'   )
#' }
index_snomed <- function(description_file,
                         relations_file,
                         output_dir,
                         root_concepts,
                         index_config = list(),
                         allow_3_letter_acronyms = NULL,
                         include_top_level_category = NULL,
                         allow_duplicate_entries = NULL,
                         compress_index = NULL,
                         external_syn_file = NULL,
                         create_output_dir = TRUE) {
  if (missing(root_concepts) || length(root_concepts) == 0L) {
    stop("`root_concepts` is required for SNOMED indexing.", call. = FALSE)
  }
  description_file <- normalize_existing_file(description_file, "description_file")
  relations_file <- normalize_existing_file(relations_file, "relations_file")
  output_dir <- normalize_output_dir(output_dir, create = create_output_dir, arg = "output_dir")
  cfg <- merge_index_config(
    index_config,
    hpo_index_config(
      root_concepts = root_concepts,
      allow_3_letter_acronyms = allow_3_letter_acronyms,
      include_top_level_category = include_top_level_category,
      allow_duplicate_entries = allow_duplicate_entries,
      compress_index = compress_index,
      external_syn_file = external_syn_file
    )
  )

  mod <- fast_hpo_cr_import("FastHPOCR.IndexSNOMED", convert = FALSE)
  indexer <- mod$IndexSNOMED(
    description_file,
    relations_file,
    output_dir,
    index_config_for_python(cfg)
  )
  indexer$index()

  invisible(resolve_index_output_path(output_dir, "snomed.index", isTRUE(cfg$compressIndex)))
}
