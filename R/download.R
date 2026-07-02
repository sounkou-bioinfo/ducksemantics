HPO_OBO_URL <- "https://purl.obolibrary.org/obo/hp.obo"
HPO_JSON_URL <- "https://purl.obolibrary.org/obo/hp.json"
HPO_OWL_URL <- "https://purl.obolibrary.org/obo/hp.owl"
HPO_PHENOTYPE_HPOA_URL <- "https://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa"
HPO_GENES_TO_PHENOTYPE_URL <- "https://purl.obolibrary.org/obo/hp/hpoa/genes_to_phenotype.txt"
HPO_PHENOTYPE_TO_GENES_URL <- "https://purl.obolibrary.org/obo/hp/hpoa/phenotype_to_genes.txt"
HPO_GENES_TO_DISEASE_URL <- "https://purl.obolibrary.org/obo/hp/hpoa/genes_to_disease.txt"
MONDO_OBO_URL <- "https://purl.obolibrary.org/obo/mondo.obo"
ORPHANET_PRODUCT1_XML_URL <- "https://www.orphadata.com/data/xml/en_product1.xml"
HPO_ONTOLOGY_DATA_PAGE <- "https://github.com/obophenotype/human-phenotype-ontology/releases"

#' Official ontology download URLs used by RfastHPOCR
#'
#' Returns the default source URLs used by the convenience download helpers. HPO
#' release assets are published at
#' <https://github.com/obophenotype/human-phenotype-ontology/releases>; the OBO
#' helper uses the stable OBO PURL for `hp.obo`.
#'
#' @return A named character vector of URLs.
#' @export
#' @examples
#' fast_hpo_cr_ontology_urls()
fast_hpo_cr_ontology_urls <- function() {
  c(
    hpo_obo = HPO_OBO_URL,
    hpo_json = HPO_JSON_URL,
    hpo_owl = HPO_OWL_URL,
    hpo_phenotype_hpoa = HPO_PHENOTYPE_HPOA_URL,
    hpo_genes_to_phenotype = HPO_GENES_TO_PHENOTYPE_URL,
    hpo_phenotype_to_genes = HPO_PHENOTYPE_TO_GENES_URL,
    hpo_genes_to_disease = HPO_GENES_TO_DISEASE_URL,
    hpo_data_page = HPO_ONTOLOGY_DATA_PAGE,
    mondo_obo = MONDO_OBO_URL,
    orphanet_product1_xml = ORPHANET_PRODUCT1_XML_URL
  )
}

#' Download ontology source files for FastHPOCR indexing
#'
#' These helpers download commonly used ontology source files into a local
#' directory and return the resulting path. `download_hpo_obo()` downloads
#' `hp.obo`, `download_mondo_obo()` downloads `mondo.obo`, and
#' `download_orphanet_product1_xml()` downloads Orphanet `en_product1.xml`.
#'
#' FastHPOCR's ORPHANET indexer expects a small JSON shape rather than the XML
#' served by Orphadata, so `download_orphanet_product1_json()` downloads the XML
#' and converts the fields used by FastHPOCR.
#'
#' @param dest_dir Directory where the file should be written.
#' @param filename Output filename within `dest_dir`.
#' @param overwrite Replace an existing file.
#' @param url Source URL. This is mainly exposed for mirrors and tests.
#' @param quiet Passed to [utils::download.file()].
#' @return The normalized path to the downloaded file.
#' @export
#' @examples
#' if (FALSE) {
#'   hp <- download_hpo_obo("ontologies")
#'   mondo <- download_mondo_obo("ontologies")
#' }
download_hpo_obo <- function(dest_dir = ".",
                             filename = "hp.obo",
                             overwrite = FALSE,
                             url = HPO_OBO_URL,
                             quiet = FALSE) {
  download_ontology_file(url, dest_dir, filename, overwrite, quiet)
}

#' Download HPO ontology and annotation resources
#'
#' Downloads HPO resources documented from the HPO ontology data page. Use
#' `resource = "obo"` for FastHPOCR indexing; the JSON, OWL, and HPOA/text
#' resources are included for downstream validation, annotation audit, and
#' gene/phenotype lookups.
#'
#' @param resource HPO resource to download.
#' @inheritParams download_hpo_obo
#' @return The normalized path to the downloaded file.
#' @export
#' @examples
#' if (FALSE) {
#'   hp_obo <- download_hpo_resource("obo", "ontologies")
#'   hpoa <- download_hpo_phenotype_hpoa("ontologies")
#' }
download_hpo_resource <- function(resource = c(
                                    "obo",
                                    "json",
                                    "owl",
                                    "phenotype_hpoa",
                                    "genes_to_phenotype",
                                    "phenotype_to_genes",
                                    "genes_to_disease"
                                  ),
                                  dest_dir = ".",
                                  overwrite = FALSE,
                                  quiet = FALSE) {
  resource <- match.arg(resource)
  meta <- hpo_resource_meta()[[resource]]
  download_ontology_file(meta$url, dest_dir, meta$filename, overwrite, quiet)
}

#' @rdname download_hpo_resource
#' @export
download_hpo_json <- function(dest_dir = ".", overwrite = FALSE, quiet = FALSE) {
  download_hpo_resource("json", dest_dir, overwrite, quiet)
}

#' @rdname download_hpo_resource
#' @export
download_hpo_owl <- function(dest_dir = ".", overwrite = FALSE, quiet = FALSE) {
  download_hpo_resource("owl", dest_dir, overwrite, quiet)
}

#' @rdname download_hpo_resource
#' @export
download_hpo_phenotype_hpoa <- function(dest_dir = ".", overwrite = FALSE, quiet = FALSE) {
  download_hpo_resource("phenotype_hpoa", dest_dir, overwrite, quiet)
}

#' @rdname download_hpo_resource
#' @export
download_hpo_genes_to_phenotype <- function(dest_dir = ".", overwrite = FALSE, quiet = FALSE) {
  download_hpo_resource("genes_to_phenotype", dest_dir, overwrite, quiet)
}

#' @rdname download_hpo_resource
#' @export
download_hpo_phenotype_to_genes <- function(dest_dir = ".", overwrite = FALSE, quiet = FALSE) {
  download_hpo_resource("phenotype_to_genes", dest_dir, overwrite, quiet)
}

#' @rdname download_hpo_resource
#' @export
download_hpo_genes_to_disease <- function(dest_dir = ".", overwrite = FALSE, quiet = FALSE) {
  download_hpo_resource("genes_to_disease", dest_dir, overwrite, quiet)
}

hpo_resource_meta <- function() {
  list(
    obo = list(url = HPO_OBO_URL, filename = "hp.obo"),
    json = list(url = HPO_JSON_URL, filename = "hp.json"),
    owl = list(url = HPO_OWL_URL, filename = "hp.owl"),
    phenotype_hpoa = list(url = HPO_PHENOTYPE_HPOA_URL, filename = "phenotype.hpoa"),
    genes_to_phenotype = list(url = HPO_GENES_TO_PHENOTYPE_URL, filename = "genes_to_phenotype.txt"),
    phenotype_to_genes = list(url = HPO_PHENOTYPE_TO_GENES_URL, filename = "phenotype_to_genes.txt"),
    genes_to_disease = list(url = HPO_GENES_TO_DISEASE_URL, filename = "genes_to_disease.txt")
  )
}

#' @rdname download_hpo_obo
#' @export
download_mondo_obo <- function(dest_dir = ".",
                               filename = "mondo.obo",
                               overwrite = FALSE,
                               url = MONDO_OBO_URL,
                               quiet = FALSE) {
  download_ontology_file(url, dest_dir, filename, overwrite, quiet)
}

#' @rdname download_hpo_obo
#' @export
download_orphanet_product1_xml <- function(dest_dir = ".",
                                           filename = "en_product1.xml",
                                           overwrite = FALSE,
                                           url = ORPHANET_PRODUCT1_XML_URL,
                                           quiet = FALSE) {
  download_ontology_file(url, dest_dir, filename, overwrite, quiet)
}

#' @rdname download_hpo_obo
#' @param xml_file Existing Orphanet XML file. If `NULL`, the XML is downloaded
#'   first with `download_orphanet_product1_xml()`.
#' @param json_filename Output JSON filename within `dest_dir`.
#' @export
#' @examples
#' if (FALSE) {
#'   orpha_json <- download_orphanet_product1_json("ontologies")
#' }
download_orphanet_product1_json <- function(dest_dir = ".",
                                            xml_file = NULL,
                                            json_filename = "en_product1.json",
                                            overwrite = FALSE,
                                            url = ORPHANET_PRODUCT1_XML_URL,
                                            quiet = FALSE) {
  dest_dir <- normalize_output_dir(dest_dir, create = TRUE, arg = "dest_dir")
  if (is.null(xml_file)) {
    xml_file <- download_orphanet_product1_xml(
      dest_dir = dest_dir,
      overwrite = overwrite,
      url = url,
      quiet = quiet
    )
  } else {
    xml_file <- normalize_existing_file(xml_file, "xml_file")
  }

  json_file <- file.path(dest_dir, json_filename)
  orphanet_product1_xml_to_json(xml_file, json_file, overwrite = overwrite)
}

#' Convert Orphanet product1 XML to FastHPOCR-compatible JSON
#'
#' Converts the `OrphaCode`, English disorder `Name`, and `SynonymList` fields
#' from Orphadata's `en_product1.xml` into the JSON shape consumed by upstream
#' `FastHPOCR.IndexORPHANET`.
#'
#' @param xml_file Path to `en_product1.xml`.
#' @param json_file Output JSON path. Defaults to replacing `.xml` with `.json`.
#' @param overwrite Replace an existing JSON file.
#' @return The normalized output JSON path.
#' @export
#' @examples
#' xml <- tempfile(fileext = ".xml")
#' writeLines(c(
#'   '<JDBOR><DisorderList><Disorder>',
#'   '<OrphaCode>1</OrphaCode><Name lang="en">Demo</Name>',
#'   '<SynonymList><Synonym lang="en">Demo synonym</Synonym></SynonymList>',
#'   '</Disorder></DisorderList></JDBOR>'
#' ), xml)
#' orphanet_product1_xml_to_json(xml, tempfile(fileext = ".json"))
orphanet_product1_xml_to_json <- function(xml_file,
                                          json_file = sub("\\.xml$", ".json", xml_file),
                                          overwrite = FALSE) {
  xml_file <- normalize_existing_file(xml_file, "xml_file")
  check_scalar_character(json_file, "json_file")
  check_flag(overwrite, "overwrite")

  if (file.exists(json_file) && !isTRUE(overwrite)) {
    return(normalizePath(json_file, mustWork = TRUE))
  }
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("Package 'xml2' is required to convert Orphanet XML to JSON.", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required to convert Orphanet XML to JSON.", call. = FALSE)
  }

  doc <- xml2::read_xml(xml_file)
  disorder_nodes <- xml2::xml_find_all(doc, ".//DisorderList/Disorder")
  disorders <- lapply(disorder_nodes, orphanet_disorder_to_fast_hpo_json)

  data <- list(
    JDBOR = list(
      list(
        DisorderList = list(
          list(Disorder = disorders)
        )
      )
    )
  )

  dest_dir <- dirname(path.expand(json_file))
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  }
  jsonlite::write_json(data, json_file, auto_unbox = TRUE, pretty = TRUE)
  normalizePath(json_file, mustWork = TRUE)
}

orphanet_disorder_to_fast_hpo_json <- function(node) {
  text_or_empty <- function(xpath) {
    value <- xml2::xml_text(xml2::xml_find_first(node, xpath), trim = TRUE)
    if (is.na(value)) "" else value
  }

  syn_nodes <- xml2::xml_find_all(node, "./SynonymList/Synonym")
  synonyms <- lapply(xml2::xml_text(syn_nodes, trim = TRUE), function(label) {
    list(label = label)
  })

  list(
    OrphaCode = text_or_empty("./OrphaCode"),
    Name = list(list(label = text_or_empty("./Name"))),
    SynonymList = list(list(Synonym = synonyms))
  )
}

download_ontology_file <- function(url, dest_dir, filename, overwrite, quiet) {
  check_scalar_character(url, "url")
  check_scalar_character(filename, "filename")
  check_flag(overwrite, "overwrite")
  check_flag(quiet, "quiet")
  dest_dir <- normalize_output_dir(dest_dir, create = TRUE, arg = "dest_dir")
  dest <- file.path(dest_dir, filename)

  if (file.exists(dest) && !isTRUE(overwrite)) {
    return(normalizePath(dest, mustWork = TRUE))
  }

  tmp <- tempfile(pattern = paste0(filename, "-"), tmpdir = dest_dir)
  on.exit(unlink(tmp), add = TRUE)

  local_source <- local_download_source(url)
  if (!is.null(local_source)) {
    ok <- file.copy(local_source, tmp, overwrite = TRUE)
    if (!isTRUE(ok)) {
      stop("Failed to copy local source file: ", local_source, call. = FALSE)
    }
  } else {
    status <- tryCatch(
      utils::download.file(url, tmp, mode = "wb", quiet = quiet),
      error = function(e) {
        stop("Failed to download ", url, ": ", conditionMessage(e), call. = FALSE)
      }
    )
    if (!identical(status, 0L)) {
      stop("Download failed for ", url, " with status ", status, call. = FALSE)
    }
  }

  if (file.exists(dest)) {
    unlink(dest)
  }
  if (!file.rename(tmp, dest)) {
    ok <- file.copy(tmp, dest, overwrite = TRUE)
    if (!isTRUE(ok)) {
      stop("Failed to move downloaded file into place: ", dest, call. = FALSE)
    }
  }

  normalizePath(dest, mustWork = TRUE)
}

local_download_source <- function(url) {
  path <- if (grepl("^file://", url)) {
    utils::URLdecode(sub("^file://", "", url))
  } else {
    url
  }
  if (file.exists(path) && !dir.exists(path)) {
    normalizePath(path, mustWork = TRUE)
  } else {
    NULL
  }
}
