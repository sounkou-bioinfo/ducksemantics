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

ducksemantics_nullable_text_property <- S7::new_property(
  S7::new_union(NULL, S7::class_character)
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
    if (length(value) != 1L || is.na(value) || !is.finite(value) || value < 1 || value != floor(value)) {
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
    if (length(rows) != 1L || is.na(rows) || !is.finite(rows) || rows < 0 || rows != floor(rows)) {
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
    text = ducksemantics_nullable_text_property,
    attrs = ducksemantics_nullable_text_property
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

ducksemantics_default_block_id <- function(provider, subject_kind, subject_id) {
  paste0(
    nchar(provider, type = "bytes"), ":", provider, "|",
    nchar(subject_kind, type = "bytes"), ":", subject_kind, "|",
    nchar(subject_id, type = "bytes"), ":", subject_id
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
#' @param attrs Optional JSON text or other metadata for each token row.
#' @details Token vectors are always persisted as DuckDB `FLOAT[]` rows. This
#'   makes the index durable and queryable without an external allocator.
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
    token = ducksemantics_nullable_text_property,
    start_offset = S7::new_union(NULL, S7::class_numeric),
    end_offset = S7::new_union(NULL, S7::class_numeric),
    attrs = ducksemantics_nullable_text_property
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
    if (length(token_index) != n || anyNA(token_index) || any(!is.finite(token_index)) ||
          any(token_index < 0) || any(token_index != floor(token_index))) {
      return("@token_index must contain one non-negative integer value per token row")
    }
    if (anyDuplicated(data.frame(
      block_id = block_id,
      subject_id = subject_id,
      token_index = token_index
    ))) {
      return("@token_index must be unique within each @block_id and @subject_id")
    }
    for (field in c("token", "attrs")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && !(length(value) %in% c(1L, n))) {
        return(paste0("@", field, " must be NULL, length 1, or one value per token row"))
      }
      if (!is.null(value) && any(!is.na(value) & !nzchar(value))) {
        return(paste0("@", field, " must contain non-empty strings or NA"))
      }
    }
    for (field in c("start_offset", "end_offset")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && !(length(value) %in% c(1L, n))) {
        return(paste0("@", field, " must be NULL, length 1, or one value per token row"))
      }
      invalid_offset <- !is.null(value) && any(
        !is.na(value) & (!is.finite(value) | value < 0 | value != floor(value))
      )
      if (invalid_offset) {
        return(paste0("@", field, " must contain non-negative integer offsets or NA"))
      }
    }
    start_offset <- S7::prop(self, "start_offset")
    end_offset <- S7::prop(self, "end_offset")
    if (!is.null(start_offset) && !is.null(end_offset)) {
      starts <- rep(start_offset, length.out = n)
      ends <- rep(end_offset, length.out = n)
      if (any(xor(is.na(starts), is.na(ends))) || any(!is.na(starts) & starts > ends)) {
        return("@start_offset and @end_offset must be paired and start must not exceed end")
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
                                                attrs = NULL) {
  embeddings <- as.matrix(embeddings)
  storage.mode(embeddings) <- "double"
  subject_id <- as.character(subject_id)
  if (is.null(block_id)) {
    block_id <- ducksemantics_default_block_id(provider, subject_kind, subject_id)
  }
  block_id <- as.character(block_id)
  if (is.null(token_index)) {
    groups <- interaction(subject_id, block_id, drop = TRUE, lex.order = TRUE)
    token_index <- stats::ave(seq_along(subject_id), groups, FUN = seq_along) - 1L
  }
  DucksemanticsTokenEmbeddingBatch(
    embeddings = embeddings,
    subject_id = subject_id,
    subject_kind = subject_kind,
    provider = provider,
    token_index = as.numeric(token_index),
    block_id = block_id,
    token = if (is.null(token)) NULL else as.character(token),
    start_offset = if (is.null(start_offset)) NULL else as.numeric(start_offset),
    end_offset = if (is.null(end_offset)) NULL else as.numeric(end_offset),
    attrs = if (is.null(attrs)) NULL else as.character(attrs)
  )
}

#' Construct a token embedding batch from a provider
#'
#' @param text Character vector to embed.
#' @param provider Object implementing `DucksemanticsTokenEmbeddingProvider`.
#' @param subject_id Subject identifiers for input texts. Defaults to `text`.
#' @param subject_kind Subject type for stored token rows.
#' @param provider_label Stored provider label. Defaults to the provider label
#'   when available.
#' @param block_id Optional block id per input text.
#' @param attrs Optional attrs value per input text.
#' @param ... Extra arguments passed to `ducksemantics_token_embed()`.
#' @return A `DucksemanticsTokenEmbeddingBatch` object.
#' @export
ducksemantics_token_embedding_batch_from_provider <- function(text,
                                                              provider,
                                                              subject_id = text,
                                                              subject_kind = "node",
                                                              provider_label = NULL,
                                                              block_id = NULL,
                                                              attrs = NULL,
                                                              ...) {
  if (!is.character(text) || anyNA(text)) {
    stop("`text` must be a character vector without NA.", call. = FALSE)
  }
  if (!length(text)) {
    stop("`text` must contain at least one value.", call. = FALSE)
  }
  subject_id <- as.character(subject_id)
  if (length(subject_id) != length(text) || anyNA(subject_id) || any(!nzchar(subject_id))) {
    stop("`subject_id` must contain one non-empty value per input text.", call. = FALSE)
  }
  S7::prop(DucksemanticsScalarText(value = subject_kind), "value")
  if (is.null(provider_label)) {
    known_provider <- S7::S7_inherits(provider, ducksemantics_colbert_provider_class) ||
      S7::S7_inherits(provider, ducksemantics_function_token_embedding_provider_class)
    provider_label <- if (known_provider) provider@label else class(provider)[[1L]]
  }
  S7::prop(DucksemanticsScalarText(value = provider_label), "value")
  if (!is.null(block_id) && (length(block_id) != length(text) || anyNA(block_id) || any(!nzchar(block_id)))) {
    stop("`block_id` must be NULL or contain one non-empty value per input text.", call. = FALSE)
  }
  if (!is.null(attrs) && !(length(attrs) %in% c(1L, length(text)))) {
    stop("`attrs` must be NULL, length 1, or one value per input text.", call. = FALSE)
  }

  token_objects <- ducksemantics_token_embed(provider, text, ...)
  if (!is.list(token_objects) || length(token_objects) != length(text)) {
    stop("Token embedding providers must return one object per input text.", call. = FALSE)
  }
  embeddings <- vector("list", length(token_objects))
  subject_ids <- vector("list", length(token_objects))
  token_indices <- vector("list", length(token_objects))
  tokens <- vector("list", length(token_objects))
  start_offsets <- vector("list", length(token_objects))
  end_offsets <- vector("list", length(token_objects))
  block_ids <- vector("list", length(token_objects))
  attrs_out <- vector("list", length(token_objects))
  attrs_values <- if (is.null(attrs)) rep(NA_character_, length(text)) else rep(as.character(attrs), length.out = length(text))
  for (i in seq_along(token_objects)) {
    one <- token_objects[[i]]
    if (is.null(one$embeddings) || !is.matrix(one$embeddings)) {
      stop("Token embedding object ", i, " must contain an `embeddings` matrix.", call. = FALSE)
    }
    one_embeddings <- S7::prop(DucksemanticsEmbeddingMatrix(embeddings = one$embeddings, rows = nrow(one$embeddings)), "embeddings")
    n_tokens <- nrow(one_embeddings)
    embeddings[[i]] <- one_embeddings
    subject_ids[[i]] <- rep(subject_id[[i]], n_tokens)
    one_token_index <- if (is.null(one$token_index)) seq_len(n_tokens) - 1L else one$token_index
    if (!is.numeric(one_token_index) || length(one_token_index) != n_tokens ||
          anyNA(one_token_index) || any(!is.finite(one_token_index)) || any(one_token_index < 0) ||
          any(one_token_index != floor(one_token_index))) {
      stop("Token embedding object ", i, " has invalid `token_index`.", call. = FALSE)
    }
    one_tokens <- if (is.null(one$tokens)) rep(NA_character_, n_tokens) else as.character(one$tokens)
    if (length(one_tokens) != n_tokens) {
      stop("Token embedding object ", i, " must have one token value per embedding row.", call. = FALSE)
    }
    one_start <- if (is.null(one$start_offset)) rep(NA_integer_, n_tokens) else one$start_offset
    one_end <- if (is.null(one$end_offset)) rep(NA_integer_, n_tokens) else one$end_offset
    if (!is.numeric(one_start) || !is.numeric(one_end) ||
          length(one_start) != n_tokens || length(one_end) != n_tokens ||
          any(!is.na(one_start) & (!is.finite(one_start) | one_start < 0 | one_start != floor(one_start))) ||
          any(!is.na(one_end) & (!is.finite(one_end) | one_end < 0 | one_end != floor(one_end))) ||
          any(xor(is.na(one_start), is.na(one_end))) ||
          any(!is.na(one_start) & one_start > one_end)) {
      stop("Token embedding object ", i, " has invalid source offsets.", call. = FALSE)
    }
    token_indices[[i]] <- as.integer(one_token_index)
    tokens[[i]] <- one_tokens
    start_offsets[[i]] <- as.integer(one_start)
    end_offsets[[i]] <- as.integer(one_end)
    block_value <- if (is.null(block_id)) {
      ducksemantics_default_block_id(provider_label, subject_kind, subject_id[[i]])
    } else {
      block_id[[i]]
    }
    block_ids[[i]] <- rep(block_value, n_tokens)
    attrs_out[[i]] <- rep(attrs_values[[i]], n_tokens)
  }
  subject_ids <- unlist(subject_ids, use.names = FALSE)
  token_indices <- unlist(token_indices, use.names = FALSE)
  tokens <- unlist(tokens, use.names = FALSE)
  start_offsets <- unlist(start_offsets, use.names = FALSE)
  end_offsets <- unlist(end_offsets, use.names = FALSE)
  block_ids <- unlist(block_ids, use.names = FALSE)
  attrs_out <- unlist(attrs_out, use.names = FALSE)
  ducksemantics_token_embedding_batch(
    embeddings = do.call(rbind, embeddings),
    subject_id = subject_ids,
    subject_kind = subject_kind,
    provider = provider_label,
    token_index = token_indices,
    block_id = block_ids,
    token = if (all(is.na(tokens))) NULL else tokens,
    start_offset = if (all(is.na(start_offsets))) NULL else start_offsets,
    end_offset = if (all(is.na(end_offsets))) NULL else end_offsets,
    attrs = if (all(is.na(attrs_out))) NULL else attrs_out
  )
}

#' Token embedding late-interaction query
#'
#' @param embeddings Numeric query-token matrix.
#' @param provider Optional provider filter.
#' @param subject_kind Optional subject-kind filter.
#' @param top_k Number of scored blocks to return.
#' @param table Optional table to search. Defaults to `semantic_token_embeddings`.
#' @param candidate_subject_id Optional candidate subject identifiers.
#' @return A `DucksemanticsTokenEmbeddingQuery` object.
#' @export
DucksemanticsTokenEmbeddingQuery <- S7::new_class(
  "DucksemanticsTokenEmbeddingQuery",
  package = "ducksemantics",
  properties = list(
    embeddings = ducksemantics_matrix_property,
    provider = S7::new_union(NULL, S7::class_character),
    subject_kind = S7::new_union(NULL, S7::class_character),
    top_k = ducksemantics_positive_integer_property,
    table = S7::new_union(NULL, S7::class_character),
    candidate_subject_id = S7::new_union(NULL, S7::class_character)
  ),
  validator = function(self) {
    for (field in c("provider", "subject_kind", "table")) {
      value <- S7::prop(self, field)
      if (!is.null(value) && (length(value) != 1L || is.na(value) || !nzchar(value))) {
        return(paste0("@", field, " must be NULL or a non-empty character scalar"))
      }
    }
    candidates <- S7::prop(self, "candidate_subject_id")
    if (!is.null(candidates) && (!length(candidates) || anyNA(candidates) || any(!nzchar(candidates)))) {
      return("@candidate_subject_id must be NULL or a non-empty character vector without missing values")
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

#' Construct a token embedding late-interaction query
#'
#' @inheritParams DucksemanticsTokenEmbeddingQuery
#' @export
ducksemantics_token_embedding_query <- function(embeddings,
                                                provider = NULL,
                                                subject_kind = NULL,
                                                top_k = 10L,
                                                table = NULL,
                                                candidate_subject_id = NULL) {
  embeddings <- as.matrix(embeddings)
  storage.mode(embeddings) <- "double"
  DucksemanticsTokenEmbeddingQuery(
    embeddings = embeddings,
    provider = if (is.null(provider)) NULL else as.character(provider),
    subject_kind = if (is.null(subject_kind)) NULL else as.character(subject_kind),
    top_k = top_k,
    table = if (is.null(table)) NULL else as.character(table),
    candidate_subject_id = if (is.null(candidate_subject_id)) NULL else as.character(candidate_subject_id)
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
    if (metric %in% c("cosine", "cosine_distance") &&
          sum(S7::prop(self, "embedding") ^ 2) == 0) {
      return("@embedding must be non-zero for a cosine metric")
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
    if (!S7::prop(self, "metric") %in% c("cosine", "l2sq", "ip")) {
      return('@metric must be one of "cosine", "l2sq", or "ip"')
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
#' @return A `DucksemanticsEmbeddingClusterSpec` object.
#' @details Clustering always materializes an ordinary finite R matrix from the
#'   DuckDB `FLOAT[]` rows.
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
    max_iter = ducksemantics_positive_integer_property
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
                                   !is.finite(dimensions) || dimensions < 1 || dimensions != floor(dimensions))) {
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
                                                 max_iter = 100L) {
  if (is.null(run_id)) {
    run_id <- paste0("embedding-cluster:", format(Sys.time(), "%Y%m%d%H%M%OS3"))
  }
  DucksemanticsEmbeddingClusterSpec(
    k = k,
    provider = provider,
    subject_kind = subject_kind,
    dimensions = dimensions,
    table = table,
    run_id = run_id,
    seed = seed,
    nstart = nstart,
    max_iter = max_iter
  )
}
