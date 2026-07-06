ducksemantics_text_property <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) {
      "must be a non-empty character scalar"
    }
  }
)

ducksemantics_optional_text_property <- S7::new_property(
  S7::new_union(NULL, S7::class_character),
  validator = function(value) {
    if (!is.null(value) && anyNA(value)) {
      "must not contain missing values"
    }
  }
)

ducksemantics_flag_property <- S7::new_property(
  S7::class_logical,
  validator = function(value) {
    if (length(value) != 1L || is.na(value)) {
      "must be TRUE or FALSE"
    }
  }
)

ducksemantics_positive_integer_property <- S7::new_property(
  S7::class_numeric,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || value < 1 || value != as.integer(value)) {
      "must be a positive integer scalar"
    }
  }
)

ducksemantics_vector_property <- S7::new_property(
  S7::class_numeric,
  validator = function(value) {
    if (!length(value) || anyNA(value) || any(!is.finite(value))) {
      "must be a finite numeric vector"
    }
  }
)

ducksemantics_matrix_property <- S7::new_property(
  S7::class_numeric,
  validator = function(value) {
    if (!is.matrix(value)) {
      "must be a numeric matrix"
    } else if (!nrow(value) || !ncol(value)) {
      "must have at least one row and one column"
    } else if (anyNA(value) || any(!is.finite(value))) {
      "must contain only finite non-missing values"
    }
  }
)

ducksemantics_table_property <- S7::new_property(
  S7::class_data.frame,
  validator = function(value) {
    if (!nrow(value)) {
      "must contain at least one row"
    }
  }
)

#' Non-empty scalar text
#'
#' S7 value object for a required non-empty character scalar.
#'
#' @param value Character scalar.
#' @return A `DucksemanticsScalarText` object.
#' @export
DucksemanticsScalarText <- S7::new_class(
  "DucksemanticsScalarText",
  package = "ducksemantics",
  properties = list(value = ducksemantics_text_property)
)

DucksemanticsFlag <- S7::new_class(
  "DucksemanticsFlag",
  package = "ducksemantics",
  properties = list(value = ducksemantics_flag_property)
)

#' SQL identifier
#'
#' S7 value object for table and column identifiers used when constructing
#' DuckDB SQL.
#'
#' @param value Identifier text.
#' @param qualified Whether `value` may contain schema/table qualification.
#' @return A `DucksemanticsSqlIdentifier` object.
#' @export
DucksemanticsSqlIdentifier <- S7::new_class(
  "DucksemanticsSqlIdentifier",
  package = "ducksemantics",
  properties = list(
    value = ducksemantics_text_property,
    qualified = ducksemantics_flag_property
  ),
  validator = function(self) {
    value <- S7::prop(self, "value")
    qualified <- S7::prop(self, "qualified")
    pattern <- if (isTRUE(qualified)) {
      "^[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*){0,2}$"
    } else {
      "^[A-Za-z_][A-Za-z0-9_]*$"
    }
    if (!grepl(pattern, value, perl = TRUE)) {
      "must be a valid SQL identifier"
    }
  }
)

#' DBI connection reference
#'
#' S7 value object for a valid DBI connection.
#'
#' @param value DBI connection.
#' @return A `DucksemanticsDbConnection` object.
#' @export
DucksemanticsDbConnection <- S7::new_class(
  "DucksemanticsDbConnection",
  package = "ducksemantics",
  properties = list(value = S7::class_any),
  validator = function(self) {
    value <- S7::prop(self, "value")
    if (!DBI::dbIsValid(value)) {
      "must be a valid DBI connection"
    }
  }
)

#' Data frame contract
#'
#' S7 value object for a data frame with required columns.
#'
#' @param value Data frame.
#' @param required Required column names.
#' @param allow_empty Whether zero-row input is allowed.
#' @return A `DucksemanticsTable` object.
#' @usage NULL
#' @export
DucksemanticsTable <- S7::new_class(
  "DucksemanticsTable",
  package = "ducksemantics",
  properties = list(
    value = S7::class_data.frame,
    required = S7::class_character,
    allow_empty = ducksemantics_flag_property
  ),
  validator = function(self) {
    value <- S7::prop(self, "value")
    required <- S7::prop(self, "required")
    allow_empty <- S7::prop(self, "allow_empty")
    missing <- setdiff(required, names(value))
    if (length(missing)) {
      return(paste0("missing required column(s): ", paste(missing, collapse = ", ")))
    }
    if (!isTRUE(allow_empty) && !nrow(value)) {
      return("must contain at least one row")
    }
    NULL
  }
)

#' Embedding matrix contract
#'
#' S7 value object for a finite numeric embedding matrix with an expected row
#' count.
#'
#' @param embeddings Numeric matrix.
#' @param rows Expected number of matrix rows.
#' @return A `DucksemanticsEmbeddingMatrix` object.
#' @export
DucksemanticsEmbeddingMatrix <- S7::new_class(
  "DucksemanticsEmbeddingMatrix",
  package = "ducksemantics",
  properties = list(
    embeddings = ducksemantics_matrix_property,
    rows = S7::class_numeric
  ),
  validator = function(self) {
    embeddings <- S7::prop(self, "embeddings")
    rows <- S7::prop(self, "rows")
    if (length(rows) != 1L || is.na(rows) || rows < 0 || rows != as.integer(rows)) {
      return("@rows must be a non-negative integer scalar")
    }
    if (nrow(embeddings) != as.integer(rows)) {
      return("@embeddings must have one row per input text")
    }
    NULL
  }
)

#' Embedding batch for the semantic store
#'
#' @param embeddings Numeric matrix with one row per subject.
#' @param subject_id Subject identifiers matching embedding rows.
#' @param subject_kind Subject type, e.g. `"node"`, `"alias"`, `"mention"`, or
#'   `"document"`.
#' @param provider Embedding provider label.
#' @param text Optional source text for each embedding.
#' @param attrs Optional JSON text or other metadata for each embedding.
#' @return A `DucksemanticsEmbeddingBatch` object.
#' @export
DucksemanticsEmbeddingBatch <- S7::new_class(
  "DucksemanticsEmbeddingBatch",
  package = "ducksemantics",
  properties = list(
    embeddings = ducksemantics_matrix_property,
    subject_id = S7::class_character,
    subject_kind = ducksemantics_text_property,
    provider = ducksemantics_text_property,
    text = ducksemantics_optional_text_property,
    attrs = ducksemantics_optional_text_property
  ),
  validator = function(self) {
    embeddings <- S7::prop(self, "embeddings")
    subject_id <- S7::prop(self, "subject_id")
    n <- nrow(embeddings)
    if (length(subject_id) != n || anyNA(subject_id) || any(!nzchar(subject_id))) {
      return("@subject_id must contain one non-empty value per embedding row")
    }
    for (field in c("text", "attrs")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && !(length(value) %in% c(1L, n))) {
        return(paste0("@", field, " must be NULL, length 1, or one value per embedding row"))
      }
    }
    NULL
  }
)

#' Construct an embedding batch
#'
#' @inheritParams DucksemanticsEmbeddingBatch
#' @export
ducksemantics_embedding_batch <- function(embeddings,
                                          subject_id,
                                          subject_kind = "node",
                                          provider = "embedding",
                                          text = NULL,
                                          attrs = NULL) {
  embeddings <- as.matrix(embeddings)
  storage.mode(embeddings) <- "double"
  DucksemanticsEmbeddingBatch(
    embeddings = embeddings,
    subject_id = as.character(subject_id),
    subject_kind = subject_kind,
    provider = provider,
    text = if (is.null(text)) NULL else as.character(text),
    attrs = if (is.null(attrs)) NULL else as.character(attrs)
  )
}

#' Token embedding batch for late-interaction storage
#'
#' @param embeddings Numeric matrix with one row per token.
#' @param subject_id Subject identifier for each token row.
#' @param subject_kind Subject type, e.g. `"node"`, `"alias"`, `"mention"`, or
#'   `"document"`.
#' @param provider Embedding provider label.
#' @param token_index Token index within each subject block. Defaults to
#'   zero-based order within `subject_id`.
#' @param block_id Matrix/block identifier. Defaults to one block per
#'   `provider`, `subject_kind`, and `subject_id`.
#' @param token Optional token text for each row.
#' @param start_offset,end_offset Optional zero-based source offsets.
#' @param storage Storage label. `"duckdb_float_array"` means `embedding`
#'   stores each token row directly in DuckDB. `"rfmalloc_slab"` is reserved for
#'   native slabs addressed by `storage_ref`.
#' @param storage_ref Optional native storage reference.
#' @param attrs Optional JSON text or other metadata for each token row.
#' @return A `DucksemanticsTokenEmbeddingBatch` object.
#' @export
DucksemanticsTokenEmbeddingBatch <- S7::new_class(
  "DucksemanticsTokenEmbeddingBatch",
  package = "ducksemantics",
  properties = list(
    embeddings = ducksemantics_matrix_property,
    subject_id = S7::class_character,
    subject_kind = ducksemantics_text_property,
    provider = ducksemantics_text_property,
    token_index = S7::class_numeric,
    block_id = S7::class_character,
    token = ducksemantics_optional_text_property,
    start_offset = S7::new_union(NULL, S7::class_numeric),
    end_offset = S7::new_union(NULL, S7::class_numeric),
    storage = ducksemantics_text_property,
    storage_ref = ducksemantics_optional_text_property,
    attrs = ducksemantics_optional_text_property
  ),
  validator = function(self) {
    embeddings <- S7::prop(self, "embeddings")
    n <- nrow(embeddings)
    subject_id <- S7::prop(self, "subject_id")
    token_index <- S7::prop(self, "token_index")
    block_id <- S7::prop(self, "block_id")
    if (length(subject_id) != n || anyNA(subject_id) || any(!nzchar(subject_id))) {
      return("@subject_id must contain one non-empty value per token row")
    }
    if (length(block_id) != n || anyNA(block_id) || any(!nzchar(block_id))) {
      return("@block_id must contain one non-empty value per token row")
    }
    if (length(token_index) != n || anyNA(token_index) || any(token_index < 0) ||
      any(token_index != as.integer(token_index))) {
      return("@token_index must contain one non-negative integer value per token row")
    }
    storage <- S7::prop(self, "storage")
    if (!storage %in% c("duckdb_float_array", "rfmalloc_slab")) {
      return('@storage must be "duckdb_float_array" or "rfmalloc_slab"')
    }
    for (field in c("token", "storage_ref", "attrs")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && !(length(value) %in% c(1L, n))) {
        return(paste0("@", field, " must be NULL, length 1, or one value per token row"))
      }
    }
    for (field in c("start_offset", "end_offset")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && !(length(value) %in% c(1L, n))) {
        return(paste0("@", field, " must be NULL, length 1, or one value per token row"))
      }
      if (!is.null(value) && any(!is.na(value) & value != as.integer(value))) {
        return(paste0("@", field, " must contain integer offsets or NA"))
      }
    }
    NULL
  }
)

#' Construct a token embedding batch
#'
#' @inheritParams DucksemanticsTokenEmbeddingBatch
#' @export
ducksemantics_token_embedding_batch <- function(embeddings,
                                                subject_id,
                                                subject_kind = "node",
                                                provider = "embedding",
                                                token_index = NULL,
                                                block_id = NULL,
                                                token = NULL,
                                                start_offset = NULL,
                                                end_offset = NULL,
                                                storage = c("duckdb_float_array", "rfmalloc_slab"),
                                                storage_ref = NULL,
                                                attrs = NULL) {
  embeddings <- as.matrix(embeddings)
  storage.mode(embeddings) <- "double"
  subject_id <- as.character(subject_id)
  if (is.null(token_index)) {
    counts <- integer()
    names(counts) <- character()
    token_index <- integer(length(subject_id))
    for (i in seq_along(subject_id)) {
      key <- subject_id[[i]]
      current <- if (key %in% names(counts)) counts[[key]] else 0L
      token_index[[i]] <- current
      counts[[key]] <- current + 1L
    }
  }
  if (is.null(block_id)) {
    block_id <- paste(provider, subject_kind, subject_id, sep = "::")
  }
  DucksemanticsTokenEmbeddingBatch(
    embeddings = embeddings,
    subject_id = subject_id,
    subject_kind = subject_kind,
    provider = provider,
    token_index = as.integer(token_index),
    block_id = as.character(block_id),
    token = if (is.null(token)) NULL else as.character(token),
    start_offset = if (is.null(start_offset)) NULL else as.integer(start_offset),
    end_offset = if (is.null(end_offset)) NULL else as.integer(end_offset),
    storage = match.arg(storage),
    storage_ref = if (is.null(storage_ref)) NULL else as.character(storage_ref),
    attrs = if (is.null(attrs)) NULL else as.character(attrs)
  )
}

#' Embedding search query
#'
#' @param embedding Numeric query embedding.
#' @param provider Optional provider filter.
#' @param subject_kind Optional subject-kind filter.
#' @param top_k Number of nearest rows to return.
#' @param metric One of `"cosine"`, `"cosine_distance"`, `"l2"`, or
#'   `"inner_product"`.
#' @param table Optional table to search. Defaults to `semantic_embeddings`.
#'   Pass a table created by [ducksemantics_materialize_embedding_index()] to use
#'   a dimensioned, HNSW-indexable table.
#' @return A `DucksemanticsEmbeddingQuery` object.
#' @export
DucksemanticsEmbeddingQuery <- S7::new_class(
  "DucksemanticsEmbeddingQuery",
  package = "ducksemantics",
  properties = list(
    embedding = ducksemantics_vector_property,
    provider = S7::new_union(NULL, S7::class_character),
    subject_kind = S7::new_union(NULL, S7::class_character),
    top_k = ducksemantics_positive_integer_property,
    metric = ducksemantics_text_property,
    table = S7::new_union(NULL, S7::class_character)
  ),
  validator = function(self) {
    metric <- S7::prop(self, "metric")
    if (!metric %in% c("cosine", "cosine_distance", "l2", "inner_product")) {
      return('@metric must be one of "cosine", "cosine_distance", "l2", or "inner_product"')
    }
    for (field in c("provider", "subject_kind", "table")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && (length(value) != 1L || is.na(value) || !nzchar(value))) {
        return(paste0("@", field, " must be NULL or a non-empty character scalar"))
      }
    }
    table <- S7::prop(self, "table")
    if (!is.null(table)) {
      invalid <- tryCatch({
        DucksemanticsSqlIdentifier(value = table, qualified = TRUE)
        NULL
      }, error = function(e) "@table must be a valid SQL identifier")
      if (!is.null(invalid)) return(invalid)
    }
    NULL
  }
)

#' Construct an embedding search query
#'
#' @inheritParams DucksemanticsEmbeddingQuery
#' @export
ducksemantics_embedding_query <- function(embedding,
                                          provider = NULL,
                                          subject_kind = NULL,
                                          top_k = 10L,
                                          metric = c("cosine", "cosine_distance", "l2", "inner_product"),
                                          table = NULL) {
  if (is.matrix(embedding)) {
    if (nrow(embedding) != 1L) {
      stop("`embedding` matrix input must have exactly one row.", call. = FALSE)
    }
    embedding <- as.numeric(embedding[1L, ])
  } else {
    embedding <- as.numeric(embedding)
  }
  DucksemanticsEmbeddingQuery(
    embedding = embedding,
    provider = provider,
    subject_kind = subject_kind,
    top_k = top_k,
    metric = match.arg(metric),
    table = table
  )
}

#' Embedding index specification
#'
#' @param dimensions Embedding dimension.
#' @param provider Optional provider filter.
#' @param subject_kind Optional subject-kind filter.
#' @param table Target table name. Defaults to
#'   `semantic_embedding_index_<dimensions>`.
#' @param hnsw Create a DuckDB HNSW index on the materialized table?
#' @param metric HNSW metric, usually `"cosine"`, `"l2sq"`, or `"ip"`.
#' @param load_vss Load DuckDB's `vss` extension before creating the HNSW index?
#' @return A `DucksemanticsEmbeddingIndexSpec` object.
#' @export
DucksemanticsEmbeddingIndexSpec <- S7::new_class(
  "DucksemanticsEmbeddingIndexSpec",
  package = "ducksemantics",
  properties = list(
    dimensions = ducksemantics_positive_integer_property,
    provider = S7::new_union(NULL, S7::class_character),
    subject_kind = S7::new_union(NULL, S7::class_character),
    table = S7::new_union(NULL, S7::class_character),
    hnsw = ducksemantics_flag_property,
    metric = ducksemantics_text_property,
    load_vss = ducksemantics_flag_property
  ),
  validator = function(self) {
    for (field in c("provider", "subject_kind", "table")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && (length(value) != 1L || is.na(value) || !nzchar(value))) {
        return(paste0("@", field, " must be NULL or a non-empty character scalar"))
      }
    }
    table <- S7::prop(self, "table")
    if (!is.null(table)) {
      invalid <- tryCatch({
        DucksemanticsSqlIdentifier(value = table, qualified = TRUE)
        NULL
      }, error = function(e) "@table must be a valid SQL identifier")
      if (!is.null(invalid)) return(invalid)
    }
    NULL
  }
)

#' Construct an embedding index specification
#'
#' @inheritParams DucksemanticsEmbeddingIndexSpec
#' @export
ducksemantics_embedding_index_spec <- function(dimensions,
                                               provider = NULL,
                                               subject_kind = NULL,
                                               table = NULL,
                                               hnsw = TRUE,
                                               metric = "cosine",
                                               load_vss = TRUE) {
  DucksemanticsEmbeddingIndexSpec(
    dimensions = dimensions,
    provider = provider,
    subject_kind = subject_kind,
    table = table,
    hnsw = hnsw,
    metric = metric,
    load_vss = load_vss
  )
}

#' Embedding clustering specification
#'
#' @param k Number of clusters.
#' @param provider Optional provider filter.
#' @param subject_kind Optional subject-kind filter.
#' @param dimensions Optional embedding dimension filter.
#' @param table Optional embedding table. Defaults to `semantic_embeddings`.
#' @param run_id Identifier written to cluster tables.
#' @param seed Random seed used by `stats::kmeans()`.
#' @param nstart Number of starts used by `stats::kmeans()`.
#' @param max_iter Maximum k-means iterations.
#' @param storage Matrix storage for the clustering pass. `"r"` uses an ordinary
#'   R matrix. `"rfmalloc"` allocates the working matrix through Rfmalloc.
#' @return A `DucksemanticsEmbeddingClusterSpec` object.
#' @export
DucksemanticsEmbeddingClusterSpec <- S7::new_class(
  "DucksemanticsEmbeddingClusterSpec",
  package = "ducksemantics",
  properties = list(
    k = ducksemantics_positive_integer_property,
    provider = S7::new_union(NULL, S7::class_character),
    subject_kind = S7::new_union(NULL, S7::class_character),
    dimensions = S7::new_union(NULL, S7::class_numeric),
    table = S7::new_union(NULL, S7::class_character),
    run_id = ducksemantics_text_property,
    seed = ducksemantics_positive_integer_property,
    nstart = ducksemantics_positive_integer_property,
    max_iter = ducksemantics_positive_integer_property,
    storage = ducksemantics_text_property
  ),
  validator = function(self) {
    for (field in c("provider", "subject_kind", "table")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && (length(value) != 1L || is.na(value) || !nzchar(value))) {
        return(paste0("@", field, " must be NULL or a non-empty character scalar"))
      }
    }
    dimensions <- S7::prop(self, "dimensions")
    if (!is.null(dimensions) && (length(dimensions) != 1L || is.na(dimensions) ||
      dimensions < 1 || dimensions != as.integer(dimensions))) {
      return("@dimensions must be NULL or a positive integer scalar")
    }
    table <- S7::prop(self, "table")
    if (!is.null(table)) {
      invalid <- tryCatch({
        DucksemanticsSqlIdentifier(value = table, qualified = TRUE)
        NULL
      }, error = function(e) "@table must be a valid SQL identifier")
      if (!is.null(invalid)) return(invalid)
    }
    storage <- S7::prop(self, "storage")
    if (!storage %in% c("r", "rfmalloc")) {
      return('@storage must be "r" or "rfmalloc"')
    }
    NULL
  }
)

#' Construct an embedding clustering specification
#'
#' @inheritParams DucksemanticsEmbeddingClusterSpec
#' @export
ducksemantics_embedding_cluster_spec <- function(k,
                                                 provider = NULL,
                                                 subject_kind = NULL,
                                                 dimensions = NULL,
                                                 table = NULL,
                                                 run_id = NULL,
                                                 seed = 1L,
                                                 nstart = 10L,
                                                 max_iter = 100L,
                                                 storage = c("r", "rfmalloc")) {
  if (is.null(run_id)) {
    run_id <- paste0("embedding-cluster:", format(Sys.time(), "%Y%m%d%H%M%OS3"))
  }
  DucksemanticsEmbeddingClusterSpec(
    k = k,
    provider = provider,
    subject_kind = subject_kind,
    dimensions = if (is.null(dimensions)) NULL else as.integer(dimensions),
    table = table,
    run_id = run_id,
    seed = seed,
    nstart = nstart,
    max_iter = max_iter,
    storage = match.arg(storage)
  )
}
