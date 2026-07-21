DUCKSEMANTICS_SCHEMA_VERSION <- "ducksemantics.schema.v1"

#' DuckDB semantic graph schema
#'
#' Returns the core SQL DDL for the generic semantic graph and grounding
#' contract. The schema is intentionally not HPO-specific: ontology terms, local
#' concept graphs, memory nodes, and pi-bio-agent graph projections can all use
#' the same node, alias, edge, mention, and judgment tables.
#'
#' @param prefix Prefix used for the generated table names.
#' @return A character vector of SQL statements.
#' @export
ducksemantics_schema_sql <- function(prefix = "semantic") {
  prefix <- S7::prop(DucksemanticsSqlIdentifier(value = prefix, qualified = FALSE), "value")
  tables <- ducksemantics_tables(prefix)

  c(
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["nodes"]]), " (",
      "node_id TEXT PRIMARY KEY, ",
      "family TEXT NOT NULL, ",
      "label TEXT, ",
      "description TEXT, ",
      "attrs TEXT, ",
      "trust TEXT",
      ")"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["aliases"]]), " (",
      "node_id TEXT NOT NULL, ",
      "alias TEXT NOT NULL, ",
      "alias_kind TEXT NOT NULL, ",
      "source TEXT, ",
      "weight DOUBLE, ",
      "attrs TEXT",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["aliases"]], "_alias_idx")),
      " ON ", ducksemantics_quote_ident(tables[["aliases"]]), " (alias)"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["aliases"]], "_node_idx")),
      " ON ", ducksemantics_quote_ident(tables[["aliases"]]), " (node_id)"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["edges"]]), " (",
      "from_id TEXT NOT NULL, ",
      "predicate TEXT NOT NULL, ",
      "to_id TEXT NOT NULL, ",
      "attrs TEXT, ",
      "trust TEXT",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["edges"]], "_subj_idx")),
      " ON ", ducksemantics_quote_ident(tables[["edges"]]), " (from_id, predicate)"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["edges"]], "_obj_idx")),
      " ON ", ducksemantics_quote_ident(tables[["edges"]]), " (to_id, predicate)"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["entailed_edges"]]), " (",
      "from_id TEXT NOT NULL, ",
      "predicate TEXT NOT NULL, ",
      "to_id TEXT NOT NULL",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["entailed_edges"]], "_subj_idx")),
      " ON ", ducksemantics_quote_ident(tables[["entailed_edges"]]), " (from_id, predicate)"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["entailed_edges"]], "_obj_idx")),
      " ON ", ducksemantics_quote_ident(tables[["entailed_edges"]]), " (to_id, predicate)"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["mentions"]]), " (",
      "document_id TEXT, ",
      "mention_id TEXT NOT NULL, ",
      "node_id TEXT NOT NULL, ",
      "span TEXT NOT NULL, ",
      "start_offset INTEGER NOT NULL, ",
      "end_offset INTEGER NOT NULL, ",
      "score DOUBLE, ",
      "method TEXT NOT NULL, ",
      "attrs TEXT, ",
      "trust TEXT",
      ")"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["judgments"]]), " (",
      "judgment_id TEXT NOT NULL, ",
      "subject_id TEXT NOT NULL, ",
      "predicate TEXT NOT NULL, ",
      "object_id TEXT, ",
      "value_json TEXT, ",
      "decision TEXT NOT NULL, ",
      "confidence DOUBLE, ",
      "evidence TEXT, ",
      "model TEXT, ",
      "recorded_at TIMESTAMP, ",
      "attrs TEXT",
      ")"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["embeddings"]]), " (",
      "subject_id TEXT NOT NULL, ",
      "subject_kind TEXT NOT NULL, ",
      "provider TEXT NOT NULL, ",
      "text TEXT, ",
      "dim INTEGER NOT NULL, ",
      "embedding FLOAT[], ",
      "attrs TEXT",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["embeddings"]], "_subject_idx")),
      " ON ", ducksemantics_quote_ident(tables[["embeddings"]]), " (subject_kind, subject_id, provider)"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["embeddings"]], "_dim_idx")),
      " ON ", ducksemantics_quote_ident(tables[["embeddings"]]), " (provider, dim)"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["token_embeddings"]]), " (",
      "block_id TEXT NOT NULL, ",
      "subject_id TEXT NOT NULL, ",
      "subject_kind TEXT NOT NULL, ",
      "provider TEXT NOT NULL, ",
      "token_index INTEGER NOT NULL, ",
      "token TEXT, ",
      "start_offset INTEGER, ",
      "end_offset INTEGER, ",
      "dim INTEGER NOT NULL, ",
      "embedding FLOAT[], ",
      "attrs TEXT",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["token_embeddings"]], "_subject_idx")),
      " ON ", ducksemantics_quote_ident(tables[["token_embeddings"]]), " (subject_kind, subject_id, provider, block_id)"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["token_embeddings"]], "_dim_idx")),
      " ON ", ducksemantics_quote_ident(tables[["token_embeddings"]]), " (provider, dim)"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["embedding_clusters"]]), " (",
      "cluster_run_id TEXT NOT NULL, ",
      "subject_id TEXT NOT NULL, ",
      "subject_kind TEXT NOT NULL, ",
      "provider TEXT NOT NULL, ",
      "dim INTEGER NOT NULL, ",
      "cluster_id INTEGER NOT NULL, ",
      "distance DOUBLE, ",
      "text TEXT, ",
      "attrs TEXT",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["embedding_clusters"]], "_run_idx")),
      " ON ", ducksemantics_quote_ident(tables[["embedding_clusters"]]), " (cluster_run_id, cluster_id)"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["embedding_centroids"]]), " (",
      "cluster_run_id TEXT NOT NULL, ",
      "provider TEXT NOT NULL, ",
      "subject_kind TEXT NOT NULL, ",
      "dim INTEGER NOT NULL, ",
      "cluster_id INTEGER NOT NULL, ",
      "size INTEGER NOT NULL, ",
      "embedding FLOAT[], ",
      "attrs TEXT",
      ")"
    ),
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["embedding_centroids"]], "_run_idx")),
      " ON ", ducksemantics_quote_ident(tables[["embedding_centroids"]]), " (cluster_run_id, cluster_id)"
    )
  )
}

#' Semantic graph table names
#'
#' @param prefix Prefix used for generated table names.
#' @return A named character vector.
#' @export
ducksemantics_tables <- function(prefix = "semantic") {
  prefix <- S7::prop(DucksemanticsSqlIdentifier(value = prefix, qualified = FALSE), "value")
  c(
    nodes = paste0(prefix, "_nodes"),
    aliases = paste0(prefix, "_aliases"),
    alias_index = paste0(prefix, "_alias_index"),
    edges = paste0(prefix, "_edges"),
    entailed_edges = paste0(prefix, "_entailed_edges"),
    mentions = paste0(prefix, "_mentions"),
    judgments = paste0(prefix, "_judgments"),
    embeddings = paste0(prefix, "_embeddings"),
    token_embeddings = paste0(prefix, "_token_embeddings"),
    embedding_clusters = paste0(prefix, "_embedding_clusters"),
    embedding_centroids = paste0(prefix, "_embedding_centroids")
  )
}

#' Connect to a DuckDB semantic store
#'
#' @param dbdir DuckDB database path, or `":memory:"`.
#' @param read_only Open read-only?
#' @param array DuckDB array conversion mode. The default enables native vector
#'   columns to round-trip through R matrices.
#' @return A DBI connection.
#' @export
ducksemantics_connect <- function(dbdir = ":memory:", read_only = FALSE, array = "matrix") {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("The duckdb R package is required to create a DuckDB connection.", call. = FALSE)
  }
  S7::prop(DucksemanticsScalarText(value = dbdir), "value")
  S7::prop(DucksemanticsFlag(value = read_only), "value")
  S7::prop(DucksemanticsScalarText(value = array), "value")
  DBI::dbConnect(duckdb::duckdb(), dbdir = dbdir, read_only = read_only, array = array)
}

#' Initialize semantic graph tables
#'
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return Invisibly, `conn`.
#' @export
ducksemantics_init <- function(conn, prefix = "semantic") {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  DBI::dbWithTransaction(conn, {
    for (sql in ducksemantics_schema_sql(prefix)) {
      DBI::dbExecute(conn, sql)
    }
  })
  invisible(conn)
}

#' Write graph rows into the semantic store
#'
#' @param conn DBI connection.
#' @param nodes Data frame with `node_id`, `family`, and optional `label`,
#'   `description`, `attrs`, `trust`.
#' @param aliases Data frame with `node_id`, `alias`, and optional `alias_kind`,
#'   `source`, `weight`, `attrs`.
#' @param edges Data frame with `from_id`, `predicate`, `to_id`, and optional
#'   `attrs`, `trust`.
#' @param prefix Prefix used for semantic tables.
#' @param replace Delete existing rows from populated target tables before
#'   writing?
#' @param index Rebuild the alias index after writing aliases?
#' @return Invisibly, the semantic table names.
#' @export
ducksemantics_write_graph <- function(conn,
                                      nodes = NULL,
                                      aliases = NULL,
                                      edges = NULL,
                                      prefix = "semantic",
                                      replace = FALSE,
                                      index = TRUE) {
  ducksemantics_init(conn, prefix)
  replace <- S7::prop(DucksemanticsFlag(value = replace), "value")
  index <- S7::prop(DucksemanticsFlag(value = index), "value")
  tables <- ducksemantics_tables(prefix)
  if (!is.null(nodes)) nodes <- ducksemantics_prepare_nodes(nodes)
  if (!is.null(aliases)) aliases <- ducksemantics_prepare_aliases(aliases)
  if (!is.null(edges)) edges <- ducksemantics_prepare_edges(edges)

  DBI::dbWithTransaction(conn, {
    if (!is.null(nodes)) {
      if (replace) DBI::dbExecute(conn, paste0("DELETE FROM ", ducksemantics_quote_ident(tables[["nodes"]])))
      ducksemantics_append_nodes(conn, tables[["nodes"]], nodes)
    }
    if (!is.null(aliases)) {
      if (replace) DBI::dbExecute(conn, paste0("DELETE FROM ", ducksemantics_quote_ident(tables[["aliases"]])))
      ducksemantics_append_unique_rows(conn, tables[["aliases"]], aliases)
    }
    if (!is.null(edges)) {
      if (replace) DBI::dbExecute(conn, paste0("DELETE FROM ", ducksemantics_quote_ident(tables[["edges"]])))
      ducksemantics_append_unique_rows(conn, tables[["edges"]], edges)
    }
    if (isTRUE(index) && !is.null(aliases)) {
      ducksemantics_index_aliases(conn, prefix = prefix)
    }
  })

  invisible(tables)
}

#' Cache a source file
#'
#' @param url Source URL.
#' @param filename Cache filename.
#' @param cache_dir Cache directory.
#' @param refresh Download even when the cache file already exists?
#' @return Normalized path to the cached file.
#' @export
ducksemantics_cache_file <- function(url,
                                     filename = basename(url),
                                     cache_dir = tools::R_user_dir("ducksemantics", "cache"),
                                     refresh = FALSE) {
  S7::prop(DucksemanticsScalarText(value = url), "value")
  S7::prop(DucksemanticsScalarText(value = filename), "value")
  if (!identical(filename, basename(filename)) || filename %in% c(".", "..")) {
    stop("`filename` must be a file name without directory components.", call. = FALSE)
  }
  S7::prop(DucksemanticsScalarText(value = cache_dir), "value")
  S7::prop(DucksemanticsFlag(value = refresh), "value")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  path <- file.path(cache_dir, filename)
  if (isTRUE(refresh) || !file.exists(path) || is.na(file.info(path)$size) || file.info(path)$size == 0) {
    temporary <- tempfile(paste0(filename, "-"), tmpdir = cache_dir)
    on.exit(unlink(temporary, force = TRUE), add = TRUE)
    utils::download.file(url, temporary, mode = "wb", quiet = TRUE)
    if (!file.exists(temporary) || is.na(file.info(temporary)$size) || file.info(temporary)$size == 0) {
      stop("Downloaded cache file is empty: ", url, call. = FALSE)
    }
    ducksemantics_atomic_replace(temporary, path)
  }
  normalizePath(path, mustWork = TRUE)
}

#' Cache an R value on disk
#'
#' @param path RDS cache path.
#' @param compute Function called with no arguments when the cache is missing or
#'   refreshed.
#' @param refresh Recompute even when the cache file already exists?
#' @return The cached R object.
#' @export
ducksemantics_cache_rds <- function(path, compute, refresh = FALSE) {
  S7::prop(DucksemanticsScalarText(value = path), "value")
  if (!is.function(compute)) {
    stop("`compute` must be a function.", call. = FALSE)
  }
  S7::prop(DucksemanticsFlag(value = refresh), "value")
  cache_dir <- dirname(path)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (isTRUE(refresh) || !file.exists(path) || is.na(file.info(path)$size) || file.info(path)$size == 0) {
    ducksemantics_atomic_save_rds(compute(), path)
  }
  readRDS(path)
}

#' Read an OBO ontology into semantic graph rows
#'
#' @param path OBO file path.
#' @param family Graph family label, for example `"HPO"` or `"MONDO"`.
#' @param source Source label stored on alias rows.
#' @param include_obsolete Include terms marked `is_obsolete: true`?
#' @return A list with `nodes`, `aliases`, and `edges` data frames.
#' @export
ducksemantics_read_obo <- function(path,
                                   family,
                                   source = basename(path),
                                   include_obsolete = FALSE) {
  S7::prop(DucksemanticsScalarText(value = path), "value")
  S7::prop(DucksemanticsScalarText(value = family), "value")
  S7::prop(DucksemanticsScalarText(value = source), "value")
  S7::prop(DucksemanticsFlag(value = include_obsolete), "value")
  if (!file.exists(path)) {
    stop("OBO file does not exist: ", path, call. = FALSE)
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  stanzas <- ducksemantics_obo_term_stanzas(lines)
  node_capacity <- length(stanzas)
  row_capacity <- length(lines)
  node_id <- family_out <- label_out <- description_out <- character(node_capacity)
  alias_node_id <- alias <- alias_kind <- alias_source <- character(row_capacity)
  alias_weight <- numeric(row_capacity)
  edge_from_id <- edge_predicate <- edge_to_id <- character(row_capacity)
  node_n <- alias_n <- edge_n <- 0L

  add_alias <- function(id, value, kind, weight) {
    alias_n <<- alias_n + 1L
    alias_node_id[[alias_n]] <<- id
    alias[[alias_n]] <<- value
    alias_kind[[alias_n]] <<- kind
    alias_source[[alias_n]] <<- source
    alias_weight[[alias_n]] <<- weight
  }
  add_edge <- function(id, predicate, target) {
    if (is.na(target) || !nzchar(target)) return(invisible(NULL))
    edge_n <<- edge_n + 1L
    edge_from_id[[edge_n]] <<- id
    edge_predicate[[edge_n]] <<- predicate
    edge_to_id[[edge_n]] <<- target
    invisible(NULL)
  }

  for (stanza in stanzas) {
    id <- ducksemantics_obo_first(stanza, "id")
    if (is.na(id) || !nzchar(id)) next
    obsolete <- identical(tolower(ducksemantics_obo_first(stanza, "is_obsolete")), "true")
    if (isTRUE(obsolete) && !isTRUE(include_obsolete)) next

    label <- ducksemantics_obo_first(stanza, "name")
    node_n <- node_n + 1L
    node_id[[node_n]] <- id
    family_out[[node_n]] <- family
    label_out[[node_n]] <- label
    description_out[[node_n]] <- ducksemantics_obo_quoted(ducksemantics_obo_first_line(stanza, "def"))

    if (!is.na(label) && nzchar(label)) add_alias(id, label, "label", 1)
    for (alt_id in ducksemantics_obo_values(stanza, "alt_id")) {
      if (!is.na(alt_id) && nzchar(alt_id)) add_alias(id, alt_id, "alt_id", 1)
    }
    for (syn_line in ducksemantics_obo_lines(stanza, "synonym")) {
      syn <- ducksemantics_obo_quoted(syn_line)
      if (!is.na(syn) && nzchar(syn)) {
        add_alias(id, syn, ducksemantics_obo_synonym_kind(syn_line), 0.95)
      }
    }
    for (is_a in ducksemantics_obo_values(stanza, "is_a")) {
      add_edge(id, "is_a", ducksemantics_obo_object_id(is_a))
    }
    for (rel in ducksemantics_obo_values(stanza, "relationship")) {
      parts <- strsplit(sub("[[:space:]]*!.*$", "", rel, perl = TRUE), "[[:space:]]+", perl = TRUE)[[1L]]
      parts <- parts[nzchar(parts)]
      if (length(parts) >= 2L) add_edge(id, parts[[1L]], ducksemantics_obo_object_id(parts[[2L]]))
    }
  }

  nodes <- data.frame(
    node_id = node_id[seq_len(node_n)],
    family = family_out[seq_len(node_n)],
    label = label_out[seq_len(node_n)],
    description = description_out[seq_len(node_n)],
    attrs = rep(NA_character_, node_n),
    trust = rep(NA_character_, node_n),
    stringsAsFactors = FALSE
  )
  aliases <- data.frame(
    node_id = alias_node_id[seq_len(alias_n)],
    alias = alias[seq_len(alias_n)],
    alias_kind = alias_kind[seq_len(alias_n)],
    source = alias_source[seq_len(alias_n)],
    weight = alias_weight[seq_len(alias_n)],
    attrs = rep(NA_character_, alias_n),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from_id = edge_from_id[seq_len(edge_n)],
    predicate = edge_predicate[seq_len(edge_n)],
    to_id = edge_to_id[seq_len(edge_n)],
    attrs = rep(NA_character_, edge_n),
    trust = rep(NA_character_, edge_n),
    stringsAsFactors = FALSE
  )
  list(nodes = nodes, aliases = aliases, edges = edges)
}

#' Write an OBO ontology into the semantic store
#'
#' @inheritParams ducksemantics_read_obo
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @param replace Delete existing graph rows before writing?
#' @param index Rebuild the alias index?
#' @return The parsed graph rows, invisibly.
#' @export
ducksemantics_write_obo <- function(conn,
                                    path,
                                    family,
                                    source = basename(path),
                                    prefix = "semantic",
                                    replace = FALSE,
                                    index = TRUE,
                                    include_obsolete = FALSE) {
  graph <- ducksemantics_read_obo(
    path = path,
    family = family,
    source = source,
    include_obsolete = include_obsolete
  )
  ducksemantics_write_graph(
    conn,
    nodes = graph$nodes,
    aliases = graph$aliases,
    edges = graph$edges,
    prefix = prefix,
    replace = replace,
    index = index
  )
  invisible(graph)
}

#' Normalize text for semantic grounding
#'
#' @param text Character vector.
#' @return Normalized character vector.
#' @export
ducksemantics_normalize <- function(text) {
  if (!is.character(text)) {
    stop("`text` must be character.", call. = FALSE)
  }
  out <- tolower(text)
  out <- gsub("[^[:alnum:]]+", " ", out, perl = TRUE)
  out <- gsub("[[:space:]]+", " ", out, perl = TRUE)
  trimws(out)
}

#' Tokenize text for semantic grounding
#'
#' @param text Character scalar.
#' @return A data frame with token text, normalized token text, zero-based start
#'   offset, end offset, and token index.
#' @export
ducksemantics_tokens <- function(text) {
  S7::prop(DucksemanticsScalarText(value = text), "value")
  hits <- gregexpr("[[:alnum:]]+", text, perl = TRUE)[[1L]]
  if (identical(hits, -1L)) {
    return(data.frame(
      token_index = integer(),
      token = character(),
      normalized = character(),
      start_offset = integer(),
      end_offset = integer(),
      stringsAsFactors = FALSE
    ))
  }
  lengths <- attr(hits, "match.length")
  token <- substring(text, hits, hits + lengths - 1L)
  data.frame(
    token_index = seq_along(hits),
    token = token,
    normalized = ducksemantics_normalize(token),
    start_offset = as.integer(hits - 1L),
    end_offset = as.integer(hits + lengths - 1L),
    stringsAsFactors = FALSE
  )
}

#' Build the lexical alias index
#'
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return Invisibly, the alias index table name.
#' @export
ducksemantics_index_aliases <- function(conn, prefix = "semantic") {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  tables <- ducksemantics_tables(prefix)
  aliases <- DBI::dbGetQuery(
    conn,
    paste0(
      "SELECT node_id, alias, alias_kind, source, COALESCE(weight, 1.0) AS weight, attrs ",
      "FROM ", ducksemantics_quote_ident(tables[["aliases"]])
    )
  )
  if (!nrow(aliases)) {
    alias_index <- data.frame(
      node_id = character(),
      alias = character(),
      alias_kind = character(),
      source = character(),
      weight = numeric(),
      attrs = character(),
      normalized_alias = character(),
      token_count = integer(),
      stringsAsFactors = FALSE
    )
  } else {
    normalized <- ducksemantics_normalize(aliases$alias)
    alias_index <- aliases[nzchar(normalized), , drop = FALSE]
    alias_index$normalized_alias <- normalized[nzchar(normalized)]
    alias_index$token_count <- vapply(strsplit(alias_index$normalized_alias, " ", fixed = TRUE), length, integer(1))
  }
  DBI::dbWriteTable(conn, tables[["alias_index"]], alias_index, overwrite = TRUE)
  DBI::dbExecute(
    conn,
    paste0(
      "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(paste0(tables[["alias_index"]], "_norm_idx")),
      " ON ", ducksemantics_quote_ident(tables[["alias_index"]]), " (normalized_alias, token_count)"
    )
  )
  invisible(tables[["alias_index"]])
}

#' Annotate text against the semantic alias index
#'
#' @param conn DBI connection.
#' @param text Character scalar.
#' @param document_id Optional document id.
#' @param prefix Prefix used for semantic tables.
#' @param longest_match Drop matches contained by a longer span.
#' @param record Append returned mentions to the mentions table?
#' @return A data frame of grounded mentions.
#' @export
ducksemantics_annotate <- function(conn,
                                   text,
                                   document_id = NULL,
                                   prefix = "semantic",
                                   longest_match = TRUE,
                                   record = FALSE) {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  S7::prop(DucksemanticsScalarText(value = text), "value")
  if (!is.null(document_id)) S7::prop(DucksemanticsScalarText(value = document_id), "value")
  S7::prop(DucksemanticsFlag(value = longest_match), "value")
  S7::prop(DucksemanticsFlag(value = record), "value")
  tables <- ducksemantics_tables(prefix)
  if (!DBI::dbExistsTable(conn, tables[["alias_index"]])) {
    ducksemantics_index_aliases(conn, prefix = prefix)
  }

  tokens <- ducksemantics_tokens(text)
  if (!nrow(tokens)) {
    return(ducksemantics_empty_mentions())
  }
  max_n <- DBI::dbGetQuery(
    conn,
    paste0("SELECT COALESCE(MAX(token_count), 0) AS n FROM ", ducksemantics_quote_ident(tables[["alias_index"]]))
  )$n[[1L]]
  max_n <- as.integer(max_n)
  if (!is.finite(max_n) || max_n < 1L) {
    return(ducksemantics_empty_mentions())
  }

  candidates <- ducksemantics_ngrams(text, tokens, max_n, document_id = document_id)
  if (!nrow(candidates)) {
    return(ducksemantics_empty_mentions())
  }
  candidate_table <- ducksemantics_temp_table_name("ducksemantics_candidates")
  DBI::dbWriteTable(conn, candidate_table, candidates, temporary = TRUE, overwrite = TRUE)
  on.exit(
    try(
      DBI::dbExecute(
        conn,
        paste0("DROP TABLE IF EXISTS ", ducksemantics_quote_ident(candidate_table))
      ),
      silent = TRUE
    ),
    add = TRUE
  )

  sql <- paste0(
    "WITH matched AS (",
    "SELECT c.document_id, c.mention_id AS span_id, a.node_id, c.span, ",
    "c.start_offset, c.end_offset, a.weight AS score, ",
    "'lexical_alias' AS method, CAST(NULL AS TEXT) AS attrs, CAST(NULL AS TEXT) AS trust, ",
    "a.alias, a.alias_kind, a.source, ",
    "ROW_NUMBER() OVER (PARTITION BY c.mention_id, a.node_id ",
    "ORDER BY a.weight DESC NULLS LAST, a.alias_kind, a.alias, a.source) AS alias_rank ",
    "FROM ", ducksemantics_quote_ident(candidate_table), " c ",
    "JOIN ", ducksemantics_quote_ident(tables[["alias_index"]]), " a ",
    "ON c.normalized_span = a.normalized_alias AND c.token_count = a.token_count",
    "), deduplicated AS (SELECT * FROM matched WHERE alias_rank = 1), identified AS (",
    "SELECT document_id, CASE WHEN COUNT(*) OVER (PARTITION BY span_id) > 1 ",
    "THEN span_id || ':' || node_id ELSE span_id END AS mention_id, node_id, span, ",
    "start_offset, end_offset, score, method, attrs, trust, alias, alias_kind, source ",
    "FROM deduplicated) SELECT * FROM identified ",
    "ORDER BY start_offset, end_offset DESC, node_id"
  )
  out <- DBI::dbGetQuery(conn, sql)
  if (isTRUE(longest_match) && nrow(out)) {
    out <- ducksemantics_longest_matches(out)
  }
  row.names(out) <- NULL

  if (isTRUE(record) && nrow(out)) {
    DBI::dbAppendTable(conn, tables[["mentions"]], out[, c(
      "document_id", "mention_id", "node_id", "span", "start_offset",
      "end_offset", "score", "method", "attrs", "trust"
    )])
  }
  out
}

#' Default judgment instructions
#'
#' These are only the default policy for the judgment prompt. Pass an explicit
#' instruction string to [ducksemantics_judgment_prompt()] or
#' [ducksemantics_judge()] when benchmarking a specific adjudication protocol.
#'
#' @return A character scalar.
#' @export
ducksemantics_default_judgment_instructions <- function() {
  paste(
    "You adjudicate deterministic semantic grounding candidates.",
    "Return exactly one valid top-level JSON array and nothing before or after it. Its first character must be [ and its final character must be ].",
    "Return exactly one result for every CANDIDATES_JSON row, in the same order.",
    "Every result must copy its candidate mention_id exactly.",
    "Include mention_id, decision, confidence, patient_context, evidence_span, short_reason, and optional replacement_node_id.",
    "For example, a candidate with mention_id m1 requires an array beginning [{\"mention_id\":\"m1\",...}].",
    "Do not wrap results in candidates_json or any other named object.",
    "decision must be one of keep, drop, replace, enrich.",
    "Use drop for negated, uncertain, family-history-only, not-about-the-subject, duplicate, or unsupported mentions.",
    "Never invent identifiers; replacements must come from supplied candidates or graph context.",
    sep = "\n"
  )
}

#' Build a semantic judgment prompt
#'
#' @param text Source text.
#' @param mentions Mention data frame from [ducksemantics_annotate()].
#' @param graph_context Optional data frame or list with nearby graph context.
#' @param instructions Character scalar or vector containing the adjudication
#'   policy. This is deliberately explicit so benchmark runs can vary the
#'   policy without changing candidate generation.
#' @return Prompt text.
#' @export
ducksemantics_judgment_prompt <- function(text,
                                          mentions,
                                          graph_context = NULL,
                                          instructions = ducksemantics_default_judgment_instructions()) {
  S7::prop(DucksemanticsScalarText(value = text), "value")
  ducksemantics_require_jsonlite()
  instructions <- ducksemantics_prompt_text(instructions, "instructions")
  mention_payload <- ducksemantics_mentions_payload(mentions)
  context_payload <- if (is.null(graph_context)) list() else graph_context
  paste(
    instructions,
    "",
    "TEXT:",
    text,
    "",
    "CANDIDATES_JSON:",
    jsonlite::toJSON(mention_payload, auto_unbox = TRUE, null = "null", dataframe = "rows"),
    "",
    "GRAPH_CONTEXT_JSON:",
    jsonlite::toJSON(context_payload, auto_unbox = TRUE, null = "null", dataframe = "rows"),
    sep = "\n"
  )
}

#' Create a BebeLM prompt runner
#'
#' @param agent A `Rbebelm` agent object.
#' @param on_event Optional Rbebelm event handler.
#' @return An object implementing [DucksemanticsPromptRunner].
#' @export
ducksemantics_bebel_runner <- function(agent, on_event = NULL) {
  if (!requireNamespace("Rbebelm", quietly = TRUE)) {
    stop("Rbebelm is required for BebeLM judgment.", call. = FALSE)
  }
  if (!is.null(on_event) && !is.function(on_event)) {
    stop("`on_event` must be NULL or a function.", call. = FALSE)
  }
  ducksemantics_bebel_runner_class(agent = agent, on_event = on_event)
}

#' Judge mentions with a model runner
#'
#' @param text Source text.
#' @param mentions Mention data frame from [ducksemantics_annotate()].
#' @param runner Object implementing [DucksemanticsPromptRunner].
#' @param conn Optional DBI connection. When supplied with `record = TRUE`,
#'   judgments are appended to the judgment table.
#' @param prefix Prefix used for semantic tables.
#' @param graph_context Optional data frame or list with nearby graph context.
#' @param instructions Character scalar or vector containing the adjudication
#'   policy.
#' @param prompt_builder Function that builds the prompt.
#' @param parser Object implementing [DucksemanticsJudgmentParser].
#' @param record Append judgments to the judgment table?
#' @param model Model label recorded with judgments.
#' @param ... Extra arguments passed to `prompt_builder`.
#' @return A data frame of judgment rows. The prompt and raw response are stored
#'   as `prompt` and `response` attributes for audit and benchmarking.
#' @export
ducksemantics_judge <- function(text,
                                mentions,
                                runner,
                                conn = NULL,
                                prefix = "semantic",
                                graph_context = NULL,
                                instructions = ducksemantics_default_judgment_instructions(),
                                prompt_builder = ducksemantics_judgment_prompt,
                                parser = ducksemantics_json_judgment_parser(),
                                record = !is.null(conn),
                                model = "semantic-runner",
                                ...) {
  S7::prop(DucksemanticsScalarText(value = text), "value")
  s7contract::assert_implements(runner, DucksemanticsPromptRunner, arg = "runner")
  s7contract::assert_implements(parser, DucksemanticsJudgmentParser, arg = "parser")
  if (!is.function(prompt_builder)) {
    stop("`prompt_builder` must be a function.", call. = FALSE)
  }
  S7::prop(DucksemanticsFlag(value = record), "value")
  S7::prop(DucksemanticsScalarText(value = model), "value")

  prompt <- prompt_builder(
    text = text,
    mentions = mentions,
    graph_context = graph_context,
    instructions = instructions,
    ...
  )
  response <- ducksemantics_run(runner, prompt)
  parsed <- ducksemantics_parse(parser, response)
  judgments <- ducksemantics_judgments_from_model(
    parsed,
    mentions,
    model = model,
    allowed_node_id = ducksemantics_judgment_node_ids(mentions, graph_context)
  )
  attr(judgments, "prompt") <- prompt
  attr(judgments, "response") <- response
  if (isTRUE(record)) {
    if (is.null(conn)) stop("`conn` is required when `record = TRUE`.", call. = FALSE)
    ducksemantics_record_judgments(conn, judgments, prefix = prefix)
  }
  judgments
}

#' Judge mentions with a BebeLM/Rbebelm agent
#'
#' @param agent A `Rbebelm` agent object.
#' @param text Source text.
#' @param mentions Mention data frame from [ducksemantics_annotate()].
#' @param conn Optional DBI connection. When supplied with `record = TRUE`,
#'   judgments are appended to the judgment table.
#' @param prefix Prefix used for semantic tables.
#' @param graph_context Optional data frame or list with nearby graph context.
#' @param instructions Character scalar or vector containing the adjudication
#'   policy.
#' @param parser Object implementing [DucksemanticsJudgmentParser].
#' @param on_event Optional Rbebelm event handler.
#' @param max_retries Number of corrective turns after a response fails the
#'   strict `DucksemanticsJudgmentParser` contract. Each parse error is appended
#'   to the same BebeLM transcript as a user turn; it is never silently coerced.
#' @param record Append judgments to the judgment table?
#' @param model Model label recorded with judgments.
#' @return A data frame of judgment rows. Its `responses` and `parse_errors`
#'   attributes retain every model response and corrective parse error.
#' @export
ducksemantics_bebel_judge <- function(agent,
                                      text,
                                      mentions,
                                      conn = NULL,
                                      prefix = "semantic",
                                      graph_context = NULL,
                                      instructions = ducksemantics_default_judgment_instructions(),
                                      parser = ducksemantics_json_judgment_parser(),
                                      on_event = NULL,
                                      max_retries = 1L,
                                      record = !is.null(conn),
                                      model = "Rbebelm") {
  if (!requireNamespace("Rbebelm", quietly = TRUE)) {
    stop("Rbebelm is required for BebeLM judgment.", call. = FALSE)
  }
  S7::prop(DucksemanticsScalarText(value = text), "value")
  s7contract::assert_implements(parser, DucksemanticsJudgmentParser, arg = "parser")
  S7::prop(DucksemanticsFlag(value = record), "value")
  S7::prop(DucksemanticsScalarText(value = model), "value")
  if (!is.numeric(max_retries) || length(max_retries) != 1L || is.na(max_retries) ||
        !is.finite(max_retries) || max_retries < 0L || max_retries != floor(max_retries)) {
    stop("`max_retries` must be a non-negative integer scalar.", call. = FALSE)
  }

  initial_prompt <- ducksemantics_judgment_prompt(
    text = text,
    mentions = mentions,
    graph_context = graph_context,
    instructions = instructions
  )
  runner <- ducksemantics_bebel_runner(agent, on_event = on_event)
  prompt <- initial_prompt
  responses <- character()
  parse_errors <- list()

  for (attempt in 0L:as.integer(max_retries)) {
    response <- ducksemantics_run(runner, prompt)
    responses <- c(responses, response)
    result <- tryCatch({
      parsed <- ducksemantics_parse(parser, response)
      ducksemantics_judgments_from_model(
        parsed,
        mentions,
        model = model,
        allowed_node_id = ducksemantics_judgment_node_ids(mentions, graph_context)
      )
    }, error = function(error) error)
    if (!inherits(result, "error")) {
      attr(result, "prompt") <- initial_prompt
      attr(result, "response") <- response
      attr(result, "responses") <- responses
      attr(result, "parse_errors") <- parse_errors
      if (isTRUE(record)) {
        if (is.null(conn)) stop("`conn` is required when `record = TRUE`.", call. = FALSE)
        ducksemantics_record_judgments(conn, result, prefix = prefix)
      }
      return(result)
    }

    parse_error <- ducksemantics_judgment_parse_error(result, response)
    parse_errors[[length(parse_errors) + 1L]] <- parse_error
    if (attempt >= as.integer(max_retries)) {
      stop(
        "BebeLM response failed the judgment parser after ",
        length(responses), " attempt(s): ", S7::prop(parse_error, "message"),
        call. = FALSE
      )
    }
    prompt <- ducksemantics_bebel_parse_repair_prompt(parse_error)
  }
  stop("Unreachable BebeLM judgment retry state.", call. = FALSE)
}

#' Record semantic judgments
#'
#' @param conn DBI connection.
#' @param judgments Judgment data frame.
#' @param prefix Prefix used for semantic tables.
#' @return Invisibly, `judgments`.
#' @export
ducksemantics_record_judgments <- function(conn, judgments, prefix = "semantic") {
  ducksemantics_init(conn, prefix)
  tables <- ducksemantics_tables(prefix)
  judgments <- ducksemantics_prepare_judgments(judgments)
  if (nrow(judgments)) {
    DBI::dbAppendTable(conn, tables[["judgments"]], judgments)
  }
  invisible(judgments)
}

#' Store an embedding batch in DuckDB
#'
#' Embeddings are stored in DuckDB as native `FLOAT[]` vectors. Similarity search
#' casts those vectors to fixed-size `FLOAT[N]` arrays so DuckDB's vector
#' functions and optional HNSW index can be used directly.
#'
#' @param batch A [DucksemanticsEmbeddingBatch] object from
#'   [ducksemantics_embedding_batch()].
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @param replace Delete existing embeddings for the same subjects and provider
#'   before inserting?
#' @return Invisibly, the written embedding rows.
#' @export
ducksemantics_write_embeddings <- function(batch,
                                           conn,
                                           prefix = "semantic",
                                           replace = FALSE) {
  if (!S7::S7_inherits(batch, DucksemanticsEmbeddingBatch)) {
    stop("`batch` must be a DucksemanticsEmbeddingBatch from ducksemantics_embedding_batch().", call. = FALSE)
  }
  ducksemantics_init(conn, prefix)
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  replace <- S7::prop(DucksemanticsFlag(value = replace), "value")
  rows <- ducksemantics_embedding_rows(batch)
  subject_kind <- S7::prop(batch, "subject_kind")
  provider <- S7::prop(batch, "provider")
  tables <- ducksemantics_tables(prefix)
  DBI::dbWithTransaction(conn, {
    if (isTRUE(replace) && nrow(rows)) {
      delete_ids <- paste(ducksemantics_quote_string(unique(rows$subject_id)), collapse = ", ")
      DBI::dbExecute(
        conn,
        paste0(
          "DELETE FROM ", ducksemantics_quote_ident(tables[["embeddings"]]),
          " WHERE subject_kind = ", ducksemantics_quote_string(subject_kind),
          " AND provider = ", ducksemantics_quote_string(provider),
          " AND subject_id IN (", delete_ids, ")"
        )
      )
    }
    if (nrow(rows)) DBI::dbAppendTable(conn, tables[["embeddings"]], rows)
  })
  invisible(rows)
}

#' Store token embeddings for late-interaction scoring
#'
#' Native ColBERT document vectors are grouped by `block_id`, so exact MaxSim
#' can compare a query-token matrix to a stored candidate matrix without
#' changing the graph schema. Dense vectors in `semantic_embeddings` remain the
#' inexpensive broad-retrieval layer.
#'
#' @param batch A `DucksemanticsTokenEmbeddingBatch` object from
#'   `ducksemantics_token_embedding_batch()`.
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @param replace Delete existing token rows for the same subjects and provider
#'   before inserting?
#' @return Invisibly, the written token embedding rows.
#' @export
ducksemantics_write_token_embeddings <- function(batch,
                                                 conn,
                                                 prefix = "semantic",
                                                 replace = FALSE) {
  if (!S7::S7_inherits(batch, DucksemanticsTokenEmbeddingBatch)) {
    stop("`batch` must be a DucksemanticsTokenEmbeddingBatch from ducksemantics_token_embedding_batch().", call. = FALSE)
  }
  ducksemantics_init(conn, prefix)
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  replace <- S7::prop(DucksemanticsFlag(value = replace), "value")
  rows <- ducksemantics_token_embedding_rows(batch)
  subject_kind <- S7::prop(batch, "subject_kind")
  provider <- S7::prop(batch, "provider")
  tables <- ducksemantics_tables(prefix)
  DBI::dbWithTransaction(conn, {
    if (isTRUE(replace) && nrow(rows)) {
      delete_ids <- paste(ducksemantics_quote_string(unique(rows$subject_id)), collapse = ", ")
      DBI::dbExecute(
        conn,
        paste0(
          "DELETE FROM ", ducksemantics_quote_ident(tables[["token_embeddings"]]),
          " WHERE subject_kind = ", ducksemantics_quote_string(subject_kind),
          " AND provider = ", ducksemantics_quote_string(provider),
          " AND subject_id IN (", delete_ids, ")"
        )
      )
    }
    if (nrow(rows)) DBI::dbAppendTable(conn, tables[["token_embeddings"]], rows)
  })
  invisible(rows)
}

#' Search token embeddings with exact late interaction
#'
#' Scores stored native ColBERT document blocks with exact MaxSim. For each
#' query token, the scorer finds the best matching document token and sums those
#' maxima, matching `Rbebelm::colbert_maxsim()` once both matrices have been
#' materialized. Use dense EmbeddingGemma/HNSW, aliases, FTS, or graph context
#' to reduce large corpora before this reranker.
#'
#' @param query A `DucksemanticsTokenEmbeddingQuery` object from
#'   `ducksemantics_token_embedding_query()`.
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return Data frame ordered by descending MaxSim score.
#' @export
ducksemantics_late_interaction_search <- function(query,
                                                  conn,
                                                  prefix = "semantic") {
  if (!S7::S7_inherits(query, DucksemanticsTokenEmbeddingQuery)) {
    query <- ducksemantics_token_embedding_query(query)
  }
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  query_embeddings <- S7::prop(query, "embeddings")
  provider <- S7::prop(query, "provider")
  subject_kind <- S7::prop(query, "subject_kind")
  top_k <- as.integer(S7::prop(query, "top_k"))
  candidate_subject_id <- S7::prop(query, "candidate_subject_id")
  dim <- ncol(query_embeddings)
  query_embeddings <- ducksemantics_l2_normalize_rows(query_embeddings)
  tables <- ducksemantics_tables(prefix)
  table <- S7::prop(query, "table") %||% tables[["token_embeddings"]]
  table <- S7::prop(DucksemanticsSqlIdentifier(value = table, qualified = TRUE), "value")
  filters <- c(
    paste0("dim = ", dim),
    "embedding IS NOT NULL"
  )
  if (!is.null(provider)) {
    filters <- c(filters, paste0("provider = ", ducksemantics_quote_string(provider)))
  }
  if (!is.null(subject_kind)) {
    filters <- c(filters, paste0("subject_kind = ", ducksemantics_quote_string(subject_kind)))
  }
  if (!is.null(candidate_subject_id)) {
    filters <- c(filters, paste0(
      "subject_id IN (",
      paste(ducksemantics_quote_string(unique(candidate_subject_id)), collapse = ", "),
      ")"
    ))
  }
  rows <- DBI::dbGetQuery(
    conn,
    paste0(
      "SELECT block_id, subject_id, subject_kind, provider, token_index, token, dim, embedding ",
      "FROM ", ducksemantics_quote_ident(table),
      " WHERE ", paste(filters, collapse = " AND "),
      " ORDER BY provider, subject_kind, subject_id, block_id, token_index"
    )
  )
  empty <- data.frame(
    block_id = character(),
    subject_id = character(),
    subject_kind = character(),
    provider = character(),
    dim = integer(),
    score = numeric(),
    score_mean = numeric(),
    score_sum = numeric(),
    query_token_count = integer(),
    candidate_token_count = integer(),
    best_token_index = character(),
    best_token = character(),
    stringsAsFactors = FALSE
  )
  if (!nrow(rows)) {
    class(empty) <- c("ducksemantics_late_interaction_result", class(empty))
    return(empty)
  }
  stored_embeddings <- ducksemantics_l2_normalize_rows(
    ducksemantics_embedding_column_matrix(rows$embedding, dim)
  )
  group_start <- c(
    TRUE,
    rows$provider[-1L] != rows$provider[-nrow(rows)] |
      rows$subject_kind[-1L] != rows$subject_kind[-nrow(rows)] |
      rows$subject_id[-1L] != rows$subject_id[-nrow(rows)] |
      rows$block_id[-1L] != rows$block_id[-nrow(rows)]
  )
  groups <- split(seq_len(nrow(rows)), cumsum(group_start))
  scored <- lapply(groups, function(idx) {
    candidate <- stored_embeddings[idx, , drop = FALSE]
    sims <- query_embeddings %*% t(candidate)
    best <- max.col(sims, ties.method = "first")
    best_scores <- sims[cbind(seq_len(nrow(sims)), best)]
    best_rows <- idx[best]
    data.frame(
      block_id = rows$block_id[[idx[[1L]]]],
      subject_id = rows$subject_id[[idx[[1L]]]],
      subject_kind = rows$subject_kind[[idx[[1L]]]],
      provider = rows$provider[[idx[[1L]]]],
      dim = dim,
      score = sum(best_scores),
      score_mean = mean(best_scores),
      score_sum = sum(best_scores),
      query_token_count = nrow(query_embeddings),
      candidate_token_count = length(idx),
      best_token_index = paste(rows$token_index[best_rows], collapse = ","),
      best_token = paste(rows$token[best_rows], collapse = ""),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, scored)
  row.names(out) <- NULL
  out <- out[order(out$score, decreasing = TRUE), , drop = FALSE]
  out <- utils::head(out, top_k)
  row.names(out) <- NULL
  class(out) <- c("ducksemantics_late_interaction_result", class(out))
  out
}

#' Search embeddings with DuckDB vector functions
#'
#' @param query A [DucksemanticsEmbeddingQuery] object from
#'   [ducksemantics_embedding_query()].
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return Data frame ordered by best match.
#' @export
ducksemantics_embedding_search <- function(query,
                                           conn,
                                           prefix = "semantic") {
  if (!S7::S7_inherits(query, DucksemanticsEmbeddingQuery)) {
    query <- ducksemantics_embedding_query(query)
  }
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  embedding <- S7::prop(query, "embedding")
  provider <- S7::prop(query, "provider")
  subject_kind <- S7::prop(query, "subject_kind")
  top_k <- as.integer(S7::prop(query, "top_k"))
  metric <- S7::prop(query, "metric")
  dim <- length(embedding)
  vector_sql <- ducksemantics_float_array_literal(embedding)
  tables <- ducksemantics_tables(prefix)
  table <- S7::prop(query, "table") %||% tables[["embeddings"]]
  table <- S7::prop(DucksemanticsSqlIdentifier(value = table, qualified = TRUE), "value")
  embedded_sql <- paste0("embedding::FLOAT[", dim, "]")
  score_sql <- switch(
    metric,
    cosine = paste0("array_cosine_similarity(", embedded_sql, ", ", vector_sql, ")"),
    cosine_distance = paste0("array_cosine_distance(", embedded_sql, ", ", vector_sql, ")"),
    l2 = paste0("array_distance(", embedded_sql, ", ", vector_sql, ")"),
    inner_product = paste0("array_inner_product(", embedded_sql, ", ", vector_sql, ")")
  )
  order <- if (metric %in% c("cosine", "inner_product")) "DESC" else "ASC"
  filters <- c(paste0("dim = ", dim))
  if (!is.null(provider)) {
    filters <- c(filters, paste0("provider = ", ducksemantics_quote_string(provider)))
  }
  if (!is.null(subject_kind)) {
    filters <- c(filters, paste0("subject_kind = ", ducksemantics_quote_string(subject_kind)))
  }
  DBI::dbGetQuery(
    conn,
    paste0(
      "SELECT subject_id, subject_kind, provider, text, dim, ",
      score_sql, " AS score ",
      "FROM ", ducksemantics_quote_ident(table),
      " WHERE ", paste(filters, collapse = " AND "),
      " ORDER BY score ", order,
      " LIMIT ", top_k
    )
  )
}

#' Materialize a fixed-dimension embedding table
#'
#' DuckDB's HNSW index requires a fixed-size vector type such as `FLOAT[384]`.
#' This function projects rows from `semantic_embeddings` into a dimensioned
#' table and can create a native HNSW index on that table.
#'
#' @param spec A [DucksemanticsEmbeddingIndexSpec] object from
#'   [ducksemantics_embedding_index_spec()].
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return Target table name.
#' @export
ducksemantics_materialize_embedding_index <- function(spec,
                                                      conn,
                                                      prefix = "semantic") {
  if (!S7::S7_inherits(spec, DucksemanticsEmbeddingIndexSpec)) {
    spec <- ducksemantics_embedding_index_spec(spec)
  }
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  dimensions <- as.integer(S7::prop(spec, "dimensions"))
  provider <- S7::prop(spec, "provider")
  subject_kind <- S7::prop(spec, "subject_kind")
  hnsw <- S7::prop(spec, "hnsw")
  metric <- S7::prop(spec, "metric")
  load_vss <- S7::prop(spec, "load_vss")
  tables <- ducksemantics_tables(prefix)
  target <- S7::prop(spec, "table") %||% paste0(prefix, "_embedding_index_", dimensions)
  target <- S7::prop(DucksemanticsSqlIdentifier(value = target, qualified = TRUE), "value")
  filters <- c(paste0("dim = ", dimensions))
  if (!is.null(provider)) {
    filters <- c(filters, paste0("provider = ", ducksemantics_quote_string(provider)))
  }
  if (!is.null(subject_kind)) {
    filters <- c(filters, paste0("subject_kind = ", ducksemantics_quote_string(subject_kind)))
  }
  DBI::dbExecute(
    conn,
    paste0(
      "CREATE OR REPLACE TABLE ", ducksemantics_quote_ident(target), " AS ",
      "SELECT subject_id, subject_kind, provider, text, dim, ",
      "embedding::FLOAT[", dimensions, "] AS embedding, attrs ",
      "FROM ", ducksemantics_quote_ident(tables[["embeddings"]]),
      " WHERE ", paste(filters, collapse = " AND ")
    )
  )
  if (isTRUE(hnsw)) {
    if (isTRUE(load_vss)) {
      DBI::dbExecute(conn, "LOAD vss")
    }
    index_name <- paste0(gsub("[^A-Za-z0-9_]", "_", target), "_hnsw_idx")
    DBI::dbExecute(conn, paste0("DROP INDEX IF EXISTS ", ducksemantics_quote_ident(index_name)))
    DBI::dbExecute(
      conn,
      paste0(
        "CREATE INDEX ", ducksemantics_quote_ident(index_name),
        " ON ", ducksemantics_quote_ident(target),
        " USING HNSW (embedding) WITH (metric = ", ducksemantics_quote_string(metric), ")"
      )
    )
  }
  target
}

#' Cluster embedding rows
#'
#' Clustering writes assignments and centroids back to DuckDB. It is intended as
#' a first measurement surface for whether a provider's embeddings recover
#' ontology structure before adding graph-aware or late-interaction scoring.
#'
#' @param spec A `DucksemanticsEmbeddingClusterSpec` object from
#'   `ducksemantics_embedding_cluster_spec()`.
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @param replace Delete rows for `spec$run_id` before writing?
#' @return A list with assignments, centroids, summary, and the `kmeans` object.
#' @export
ducksemantics_cluster_embeddings <- function(spec,
                                             conn,
                                             prefix = "semantic",
                                             replace = TRUE) {
  if (!S7::S7_inherits(spec, DucksemanticsEmbeddingClusterSpec)) {
    spec <- ducksemantics_embedding_cluster_spec(spec)
  }
  ducksemantics_init(conn, prefix)
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  replace <- S7::prop(DucksemanticsFlag(value = replace), "value")
  tables <- ducksemantics_tables(prefix)
  rows <- ducksemantics_embedding_table_rows(conn, spec, prefix = prefix)
  if (!nrow(rows)) {
    stop("No embedding rows matched the clustering specification.", call. = FALSE)
  }
  dimensions <- unique(as.integer(rows$dim))
  if (length(dimensions) != 1L) {
    stop("Clustering requires one embedding dimension; set `dimensions` in the cluster spec.", call. = FALSE)
  }
  k <- as.integer(S7::prop(spec, "k"))
  if (k >= nrow(rows)) {
    stop("`k` must be smaller than the number of matched embedding rows.", call. = FALSE)
  }
  x <- ducksemantics_embedding_column_matrix(rows$embedding, dimensions)

  seed <- as.integer(S7::prop(spec, "seed"))
  old_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    if (is.null(old_seed)) {
      rm(".Random.seed", envir = .GlobalEnv)
    } else {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  fit <- stats::kmeans(
    x,
    centers = k,
    nstart = as.integer(S7::prop(spec, "nstart")),
    iter.max = as.integer(S7::prop(spec, "max_iter"))
  )

  run_id <- S7::prop(spec, "run_id")
  assignments <- ducksemantics_cluster_assignment_rows(rows, x, fit, run_id)
  centroids <- ducksemantics_cluster_centroid_rows(rows, fit, run_id, dimensions)
  DBI::dbWithTransaction(conn, {
    if (isTRUE(replace)) {
      DBI::dbExecute(
        conn,
        paste0(
          "DELETE FROM ", ducksemantics_quote_ident(tables[["embedding_clusters"]]),
          " WHERE cluster_run_id = ", ducksemantics_quote_string(run_id)
        )
      )
      DBI::dbExecute(
        conn,
        paste0(
          "DELETE FROM ", ducksemantics_quote_ident(tables[["embedding_centroids"]]),
          " WHERE cluster_run_id = ", ducksemantics_quote_string(run_id)
        )
      )
    }
    DBI::dbAppendTable(conn, tables[["embedding_clusters"]], assignments)
    DBI::dbAppendTable(conn, tables[["embedding_centroids"]], centroids)
  })

  summary <- data.frame(
    cluster_run_id = run_id,
    cluster_id = seq_len(k),
    size = as.integer(fit$size),
    withinss = as.numeric(fit$withinss),
    mean_distance = vapply(seq_len(k), function(cluster_id) {
      distance <- assignments$distance[assignments$cluster_id == cluster_id]
      if (length(distance)) mean(distance) else NA_real_
    }, numeric(1)),
    stringsAsFactors = FALSE
  )
  out <- list(
    cluster_run_id = run_id,
    assignments = assignments,
    centroids = centroids,
    summary = summary,
    fit = fit
  )
  class(out) <- c("ducksemantics_embedding_cluster_result", "list")
  out
}

#' Summarize stored embedding clusters
#'
#' @param conn DBI connection.
#' @param cluster_run_id Optional cluster run filter.
#' @param prefix Prefix used for semantic tables.
#' @return Data frame with cluster sizes and distance summaries.
#' @export
ducksemantics_embedding_cluster_summary <- function(conn,
                                                    cluster_run_id = NULL,
                                                    prefix = "semantic") {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  if (!is.null(cluster_run_id)) S7::prop(DucksemanticsScalarText(value = cluster_run_id), "value")
  tables <- ducksemantics_tables(prefix)
  filters <- ""
  if (!is.null(cluster_run_id)) {
    filters <- paste0(" WHERE cluster_run_id = ", ducksemantics_quote_string(cluster_run_id))
  }
  DBI::dbGetQuery(
    conn,
    paste0(
      "SELECT cluster_run_id, cluster_id, COUNT(*) AS size, ",
      "AVG(distance) AS mean_distance, MIN(distance) AS min_distance, MAX(distance) AS max_distance ",
      "FROM ", ducksemantics_quote_ident(tables[["embedding_clusters"]]),
      filters,
      " GROUP BY cluster_run_id, cluster_id ",
      " ORDER BY cluster_run_id, cluster_id"
    )
  )
}

#' Compare embedding clusters with graph edges
#'
#' This measures whether clustered node embeddings respect direct ontology
#' relations such as `is_a` and `part_of`. It is a coarse diagnostic: high
#' agreement does not prove semantic quality, but low agreement is actionable
#' evidence for the embedding, text source, or clustering setup.
#'
#' @param conn DBI connection.
#' @param cluster_run_id Cluster run id written by
#'   `ducksemantics_cluster_embeddings()`.
#' @param predicates Edge predicates to evaluate.
#' @param prefix Prefix used for semantic tables.
#' @return One-row data frame with edge counts and same-cluster rate.
#' @export
ducksemantics_embedding_cluster_graph_agreement <- function(conn,
                                                            cluster_run_id,
                                                            predicates = c("is_a", "part_of"),
                                                            prefix = "semantic") {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  S7::prop(DucksemanticsScalarText(value = cluster_run_id), "value")
  if (!is.character(predicates) || anyNA(predicates) || any(!nzchar(predicates))) {
    stop("`predicates` must be a character vector of non-empty strings.", call. = FALSE)
  }
  tables <- ducksemantics_tables(prefix)
  predicate_sql <- paste(vapply(predicates, ducksemantics_quote_string, character(1)), collapse = ", ")
  DBI::dbGetQuery(
    conn,
    paste0(
      "WITH edge_clusters AS (",
      "SELECT e.predicate, from_cluster.cluster_id AS from_cluster, to_cluster.cluster_id AS to_cluster ",
      "FROM ", ducksemantics_quote_ident(tables[["edges"]]), " e ",
      "JOIN ", ducksemantics_quote_ident(tables[["embedding_clusters"]]), " from_cluster ",
      "ON from_cluster.cluster_run_id = ", ducksemantics_quote_string(cluster_run_id),
      " AND from_cluster.subject_id = e.from_id ",
      "JOIN ", ducksemantics_quote_ident(tables[["embedding_clusters"]]), " to_cluster ",
      "ON to_cluster.cluster_run_id = ", ducksemantics_quote_string(cluster_run_id),
      " AND to_cluster.subject_id = e.to_id ",
      "WHERE e.predicate IN (", predicate_sql, ")",
      ") SELECT ",
      ducksemantics_quote_string(cluster_run_id), " AS cluster_run_id, ",
      "COUNT(*) AS edge_count, ",
      "SUM(CASE WHEN from_cluster = to_cluster THEN 1 ELSE 0 END) AS same_cluster_edges, ",
      "CASE WHEN COUNT(*) > 0 THEN SUM(CASE WHEN from_cluster = to_cluster THEN 1 ELSE 0 END)::DOUBLE / COUNT(*) ELSE NULL END AS same_cluster_rate ",
      "FROM edge_clusters"
    )
  )
}

#' Summarize semantic index size
#'
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return A list with table row counts and alias-index pressure metrics.
#' @export
ducksemantics_index_stats <- function(conn, prefix = "semantic") {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  tables <- ducksemantics_tables(prefix)
  counts <- data.frame(
    table = unname(tables),
    row_count = NA_real_,
    stringsAsFactors = FALSE
  )
  for (i in seq_along(tables)) {
    if (DBI::dbExistsTable(conn, tables[[i]])) {
      counts$row_count[[i]] <- DBI::dbGetQuery(
        conn,
        paste0("SELECT COUNT(*) AS n FROM ", ducksemantics_quote_ident(tables[[i]]))
      )$n[[1L]]
    }
  }

  alias_pressure <- data.frame(
    metric = c("aliases", "normalized_aliases", "max_alias_tokens"),
    value = c(0, 0, 0),
    stringsAsFactors = FALSE
  )
  if (DBI::dbExistsTable(conn, tables[["alias_index"]])) {
    alias_pressure <- DBI::dbGetQuery(
      conn,
      paste0(
        "SELECT ",
        "COUNT(*)::DOUBLE AS aliases, ",
        "COUNT(DISTINCT normalized_alias)::DOUBLE AS normalized_aliases, ",
        "COALESCE(MAX(token_count), 0)::DOUBLE AS max_alias_tokens ",
        "FROM ", ducksemantics_quote_ident(tables[["alias_index"]])
      )
    )
    alias_pressure <- data.frame(
      metric = names(alias_pressure),
      value = as.numeric(alias_pressure[1L, ]),
      stringsAsFactors = FALSE
    )
  }

  list(
    tables = counts,
    alias_pressure = alias_pressure,
    database_size = ducksemantics_database_size(conn)
  )
}

#' Define benchmark cases
#'
#' @param cases Data frame with `case_id` and `text`.
#' @param gold Data frame with `case_id` and `node_id`. Optional span columns
#'   are `span`, `start_offset`, and `end_offset`.
#' @param suite Benchmark suite label.
#' @param task Benchmark task label.
#' @param source Optional source dataset label.
#' @param version Optional source dataset version.
#' @param metadata Optional named list of benchmark metadata.
#' @return A benchmark object.
#' @export
ducksemantics_benchmark_cases <- function(cases,
                                          gold,
                                          suite = "semantic",
                                          task = "grounding",
                                          source = NULL,
                                          version = NULL,
                                          metadata = list()) {
  cases <- S7::prop(
    DucksemanticsTable(value = cases, required = c("case_id", "text"), allow_empty = FALSE),
    "value"
  )
  gold <- S7::prop(
    DucksemanticsTable(value = gold, required = c("case_id", "node_id"), allow_empty = TRUE),
    "value"
  )
  ducksemantics_validate_required_text(cases, c("case_id", "text"), "cases")
  ducksemantics_validate_required_text(gold, c("case_id", "node_id"), "gold")
  if (anyDuplicated(cases$case_id)) {
    stop("`cases$case_id` must uniquely identify each benchmark case.", call. = FALSE)
  }
  unknown_cases <- setdiff(unique(gold$case_id), cases$case_id)
  if (length(unknown_cases)) {
    stop("Every `gold$case_id` must occur in `cases$case_id`.", call. = FALSE)
  }
  S7::prop(DucksemanticsScalarText(value = suite), "value")
  S7::prop(DucksemanticsScalarText(value = task), "value")
  if (!is.null(source)) S7::prop(DucksemanticsScalarText(value = source), "value")
  if (!is.null(version)) S7::prop(DucksemanticsScalarText(value = version), "value")
  if (!is.list(metadata)) stop("`metadata` must be a list.", call. = FALSE)

  cases <- cases[, c("case_id", "text", setdiff(names(cases), c("case_id", "text"))), drop = FALSE]
  gold <- ducksemantics_add_missing(gold, c(
    span = NA_character_,
    start_offset = NA_integer_,
    end_offset = NA_integer_
  ))
  gold <- gold[, c("case_id", "node_id", "span", "start_offset", "end_offset", setdiff(names(gold), c(
    "case_id", "node_id", "span", "start_offset", "end_offset"
  ))), drop = FALSE]

  out <- list(
    suite = suite,
    task = task,
    source = source,
    version = version,
    metadata = metadata,
    cases = cases,
    gold = gold
  )
  class(out) <- c("ducksemantics_benchmark", "list")
  out
}

#' Run a grounding benchmark
#'
#' @param benchmark Benchmark object from [ducksemantics_benchmark_cases()].
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @param annotator Object implementing [DucksemanticsAnnotator].
#' @param longest_match Drop matches contained by a longer span.
#' @param record Append predicted mentions to the mentions table?
#' @param collect_index_stats Include index stats in the result?
#' @return A list with predictions, timings, metrics, and optional index stats.
#' @export
ducksemantics_benchmark <- function(benchmark,
                                    conn,
                                    prefix = "semantic",
                                    annotator = ducksemantics_lexical_annotator(),
                                    longest_match = TRUE,
                                    record = FALSE,
                                    collect_index_stats = TRUE) {
  S7::prop(DucksemanticsDbConnection(value = conn), "value")
  if (!inherits(benchmark, "ducksemantics_benchmark")) {
    stop("`benchmark` must come from ducksemantics_benchmark_cases().", call. = FALSE)
  }
  s7contract::assert_implements(annotator, DucksemanticsAnnotator, arg = "annotator")
  S7::prop(DucksemanticsFlag(value = longest_match), "value")
  S7::prop(DucksemanticsFlag(value = record), "value")
  S7::prop(DucksemanticsFlag(value = collect_index_stats), "value")

  started_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%OS3%z")
  wall_start <- proc.time()[["elapsed"]]
  predictions <- list()
  timings <- vector("list", nrow(benchmark$cases))
  for (i in seq_len(nrow(benchmark$cases))) {
    case_id <- as.character(benchmark$cases$case_id[[i]])
    text <- as.character(benchmark$cases$text[[i]])
    case_start <- proc.time()[["elapsed"]]
    pred <- ducksemantics_ground(
      annotator = annotator,
      conn = conn,
      text = text,
      document_id = case_id,
      prefix = prefix,
      longest_match = longest_match,
      record = record
    )
    case_seconds <- proc.time()[["elapsed"]] - case_start
    if (nrow(pred)) {
      pred$case_id <- case_id
      predictions[[length(predictions) + 1L]] <- pred
    }
    timings[[i]] <- data.frame(
      case_id = case_id,
      seconds = case_seconds,
      char_count = nchar(text, type = "chars"),
      token_count = nrow(ducksemantics_tokens(text)),
      gold_count = sum(benchmark$gold$case_id == case_id),
      prediction_count = nrow(pred),
      predicted_node_count = length(unique(pred$node_id)),
      prediction_bytes = as.numeric(utils::object.size(pred)),
      stringsAsFactors = FALSE
    )
  }

  predictions <- if (length(predictions)) {
    do.call(rbind, predictions)
  } else {
    ducksemantics_empty_mentions_with_case()
  }
  row.names(predictions) <- NULL
  timings <- do.call(rbind, timings)
  metrics <- ducksemantics_benchmark_metrics(predictions, benchmark$gold)
  case_metrics <- ducksemantics_benchmark_case_metrics(predictions, benchmark$gold, benchmark$cases$case_id)
  elapsed_seconds <- proc.time()[["elapsed"]] - wall_start
  summary <- data.frame(
    suite = benchmark$suite,
    task = benchmark$task,
    case_count = nrow(benchmark$cases),
    gold_count = nrow(benchmark$gold),
    prediction_count = nrow(predictions),
    elapsed_seconds = elapsed_seconds,
    case_seconds = sum(timings$seconds),
    token_count = sum(timings$token_count),
    tokens_per_second = if (elapsed_seconds > 0) sum(timings$token_count) / elapsed_seconds else NA_real_,
    cases_per_second = if (elapsed_seconds > 0) nrow(benchmark$cases) / elapsed_seconds else NA_real_,
    prediction_bytes = sum(timings$prediction_bytes),
    stringsAsFactors = FALSE
  )
  out <- list(
    suite = benchmark$suite,
    task = benchmark$task,
    source = benchmark$source,
    version = benchmark$version,
    metadata = benchmark$metadata,
    started_at = started_at,
    finished_at = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3%z"),
    environment = ducksemantics_benchmark_environment(),
    summary = summary,
    predictions = predictions,
    timings = timings,
    case_metrics = case_metrics,
    metrics = metrics,
    index_stats = if (isTRUE(collect_index_stats)) ducksemantics_index_stats(conn, prefix = prefix) else NULL
  )
  class(out) <- c("ducksemantics_benchmark_result", "list")
  out
}

#' @export
print.ducksemantics_benchmark_result <- function(x, ...) {
  cat("<ducksemantics benchmark>\n")
  cat("  suite: ", x$suite, "\n", sep = "")
  cat("  task: ", x$task, "\n", sep = "")
  cat("  cases: ", x$summary$case_count, "\n", sep = "")
  cat("  elapsed: ", sprintf("%.3f s", x$summary$elapsed_seconds), "\n", sep = "")
  cat("  F1: ", sprintf("%.3f", x$metrics$f1), "\n", sep = "")
  invisible(x)
}

#' @export
print.ducksemantics_late_interaction_result <- function(x, ...) {
  cat("<ducksemantics late-interaction result>\n")
  cat("  blocks: ", nrow(x), "\n", sep = "")
  if (nrow(x)) {
    cat("  top score: ", sprintf("%.4f", x$score[[1L]]), "\n", sep = "")
  }
  invisible(x)
}

#' Compute benchmark precision and recall
#'
#' @param predictions Prediction data frame from [ducksemantics_benchmark()]
#'   or [ducksemantics_annotate()].
#' @param gold Gold data frame with `case_id` and `node_id`.
#' @param by Match on `node` only, or on exact `span` offsets when available.
#' @return A one-row data frame with `tp`, `fp`, `fn`, `precision`, `recall`,
#'   and `f1`.
#' @export
ducksemantics_benchmark_metrics <- function(predictions, gold, by = c("node", "span")) {
  by <- match.arg(by)
  predictions <- S7::prop(DucksemanticsTable(value = predictions, required = character(), allow_empty = TRUE), "value")
  gold <- S7::prop(DucksemanticsTable(value = gold, required = c("case_id", "node_id"), allow_empty = TRUE), "value")
  if (!"case_id" %in% names(predictions)) {
    if ("document_id" %in% names(predictions)) {
      predictions$case_id <- predictions$document_id
    } else {
      stop("`predictions` must contain `case_id` or `document_id`.", call. = FALSE)
    }
  }
  predictions <- S7::prop(DucksemanticsTable(value = predictions, required = c("case_id", "node_id"), allow_empty = TRUE), "value")

  key_by <- by
  if (identical(by, "span")) {
    complete_offsets <- function(x) {
      all(c("start_offset", "end_offset") %in% names(x)) &&
        all(!is.na(x$start_offset) & !is.na(x$end_offset))
    }
    complete_spans <- function(x) {
      "span" %in% names(x) && all(!is.na(x$span) & nzchar(as.character(x$span)))
    }
    if (complete_offsets(predictions) && complete_offsets(gold)) {
      key_by <- "offset"
    } else if (complete_spans(predictions) && complete_spans(gold)) {
      key_by <- "span_text"
    } else {
      stop(
        "Span metrics require complete offsets in both tables or complete span text in both tables.",
        call. = FALSE
      )
    }
  }
  pred_keys <- ducksemantics_metric_keys(predictions, by = key_by)
  gold_keys <- ducksemantics_metric_keys(gold, by = key_by)
  tp <- sum(pred_keys %in% gold_keys)
  fp <- sum(!pred_keys %in% gold_keys)
  fn <- sum(!gold_keys %in% pred_keys)
  precision <- if ((tp + fp) > 0) tp / (tp + fp) else NA_real_
  recall <- if ((tp + fn) > 0) tp / (tp + fn) else NA_real_
  f1 <- if (is.finite(precision) && is.finite(recall) && (precision + recall) > 0) {
    2 * precision * recall / (precision + recall)
  } else {
    NA_real_
  }
  data.frame(
    by = by,
    tp = tp,
    fp = fp,
    fn = fn,
    precision = precision,
    recall = recall,
    f1 = f1,
    stringsAsFactors = FALSE
  )
}

#' Project any edge-shaped source relation into graph shape
#'
#' This mirrors the graph projection profile used in pi-bio-agent: a source
#' table with caller-named columns becomes a stable graph edge table with
#' `from_id`, `predicate`, `to_id`, `attrs`, and `trust`.
#'
#' @param source_table Source table or view name.
#' @param from,predicate,to Source column names.
#' @param target_table Target table name.
#' @param attrs,trust Optional source columns containing JSON text.
#' @return A DuckDB SQL script that replaces the target table and restores its
#'   graph indexes.
#' @export
ducksemantics_projection_sql <- function(source_table,
                                         from,
                                         predicate,
                                         to,
                                         target_table = "semantic_edges",
                                         attrs = NULL,
                                         trust = NULL) {
  source_table <- S7::prop(DucksemanticsSqlIdentifier(value = source_table, qualified = TRUE), "value")
  target_table <- S7::prop(DucksemanticsSqlIdentifier(value = target_table, qualified = TRUE), "value")
  from <- S7::prop(DucksemanticsSqlIdentifier(value = from, qualified = FALSE), "value")
  predicate <- S7::prop(DucksemanticsSqlIdentifier(value = predicate, qualified = FALSE), "value")
  to <- S7::prop(DucksemanticsSqlIdentifier(value = to, qualified = FALSE), "value")
  attrs_sql <- ducksemantics_optional_column(attrs, "attrs")
  trust_sql <- ducksemantics_optional_column(trust, "trust")

  target_sql <- ducksemantics_quote_ident(target_table)
  subject_index <- ducksemantics_derived_index_name(target_table, "subj_idx")
  object_index <- ducksemantics_derived_index_name(target_table, "obj_idx")
  paste0(
    "CREATE OR REPLACE TABLE ", target_sql,
    " AS SELECT ",
    ducksemantics_quote_ident(from), " AS from_id, ",
    ducksemantics_quote_ident(predicate), " AS predicate, ",
    ducksemantics_quote_ident(to), " AS to_id, ",
    attrs_sql, " AS attrs, ",
    trust_sql, " AS trust",
    " FROM ", ducksemantics_quote_ident(source_table), "; ",
    "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(subject_index),
    " ON ", target_sql, " (from_id, predicate); ",
    "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(object_index),
    " ON ", target_sql, " (to_id, predicate)"
  )
}

#' Materialize transitive edge closure
#'
#' Returns DuckDB SQL that computes `target_table(from_id, predicate, to_id)` as
#' the transitive closure of `source_table` for the supplied predicates. This is
#' the same graph-as-SQL primitive used for ontology ancestors, partonomy,
#' memory walks, and arbitrary declared transitive graph relations.
#'
#' @param transitive_predicates Character vector of predicates to close.
#' @param source_table Source edge table.
#' @param target_table Target closure table.
#' @return A DuckDB SQL script that replaces the closure table and restores its
#'   graph indexes.
#' @export
ducksemantics_closure_sql <- function(transitive_predicates,
                                      source_table = "semantic_edges",
                                      target_table = "semantic_entailed_edges") {
  source_table <- S7::prop(DucksemanticsSqlIdentifier(value = source_table, qualified = TRUE), "value")
  target_table <- S7::prop(DucksemanticsSqlIdentifier(value = target_table, qualified = TRUE), "value")
  if (!is.character(transitive_predicates) || anyNA(transitive_predicates) || any(!nzchar(transitive_predicates))) {
    stop("`transitive_predicates` must be a character vector of non-empty strings.", call. = FALSE)
  }
  target_sql <- ducksemantics_quote_ident(target_table)
  subject_index <- ducksemantics_derived_index_name(target_table, "subj_idx")
  object_index <- ducksemantics_derived_index_name(target_table, "obj_idx")
  create <- if (!length(transitive_predicates)) {
    paste0(
      "CREATE OR REPLACE TABLE ", target_sql,
      " (from_id TEXT, predicate TEXT, to_id TEXT)"
    )
  } else {
    predicates <- paste(
      vapply(transitive_predicates, ducksemantics_quote_string, character(1)),
      collapse = ", "
    )
    paste0(
      "CREATE OR REPLACE TABLE ", target_sql, " AS ",
      "WITH RECURSIVE closure(from_id, predicate, to_id) AS (",
      "SELECT from_id, predicate, to_id FROM ", ducksemantics_quote_ident(source_table),
      " WHERE predicate IN (", predicates, ") ",
      "UNION ",
      "SELECT c.from_id, c.predicate, e.to_id ",
      "FROM closure c JOIN ", ducksemantics_quote_ident(source_table),
      " e ON e.from_id = c.to_id AND e.predicate = c.predicate",
      ") SELECT DISTINCT from_id, predicate, to_id FROM closure"
    )
  }
  paste0(
    create, "; ",
    "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(subject_index),
    " ON ", target_sql, " (from_id, predicate); ",
    "CREATE INDEX IF NOT EXISTS ", ducksemantics_quote_ident(object_index),
    " ON ", target_sql, " (to_id, predicate)"
  )
}

ducksemantics_derived_index_name <- function(table, suffix) {
  parts <- strsplit(table, ".", fixed = TRUE)[[1L]]
  parts[[length(parts)]] <- paste0(parts[[length(parts)]], "_", suffix)
  paste(parts, collapse = ".")
}

ducksemantics_optional_column <- function(column, arg) {
  if (is.null(column)) {
    return("NULL")
  }
  column <- S7::prop(DucksemanticsSqlIdentifier(value = column, qualified = FALSE), "value")
  ducksemantics_quote_ident(column)
}

ducksemantics_quote_ident <- function(x) {
  paste(
    sprintf('"%s"', gsub('"', '""', strsplit(x, ".", fixed = TRUE)[[1L]], fixed = TRUE)),
    collapse = "."
  )
}

ducksemantics_quote_string <- function(x) {
  paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
}

ducksemantics_temp_table_name <- function(prefix) {
  name <- basename(tempfile(paste0(prefix, "_")))
  gsub("[^A-Za-z0-9_]", "_", name)
}

ducksemantics_validate_required_text <- function(x, columns, arg) {
  for (column in columns) {
    value <- x[[column]]
    if (!is.character(value) || anyNA(value) || any(!nzchar(value))) {
      stop("`", arg, "$", column, "` must contain non-empty strings without NA.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ducksemantics_validate_optional_text <- function(x, columns, arg) {
  for (column in columns) {
    value <- x[[column]]
    if (!is.character(value) || any(!is.na(value) & !nzchar(value))) {
      stop("`", arg, "$", column, "` must contain non-empty strings or NA.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

ducksemantics_atomic_replace <- function(source, target) {
  backup <- NULL
  if (file.exists(target)) {
    backup <- tempfile(paste0(basename(target), "-backup-"), tmpdir = dirname(target))
    if (!file.rename(target, backup)) {
      stop("Could not stage existing cache file for replacement: ", target, call. = FALSE)
    }
  }
  installed <- file.rename(source, target)
  if (!installed && !is.null(backup)) file.rename(backup, target)
  if (!installed) stop("Could not install cache file: ", target, call. = FALSE)
  if (!is.null(backup)) unlink(backup, force = TRUE)
  invisible(target)
}

ducksemantics_atomic_save_rds <- function(value, path) {
  temporary <- tempfile(paste0(basename(path), "-"), tmpdir = dirname(path))
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  saveRDS(value, temporary)
  ducksemantics_atomic_replace(temporary, path)
}

ducksemantics_prepare_nodes <- function(nodes) {
  nodes <- S7::prop(
    DucksemanticsTable(value = nodes, required = c("node_id", "family"), allow_empty = TRUE),
    "value"
  )
  nodes <- ducksemantics_add_missing(nodes, c(
    label = NA_character_,
    description = NA_character_,
    attrs = NA_character_,
    trust = NA_character_
  ))[, c("node_id", "family", "label", "description", "attrs", "trust")]
  ducksemantics_validate_required_text(nodes, c("node_id", "family"), "nodes")
  ducksemantics_validate_optional_text(
    nodes,
    c("label", "description", "attrs", "trust"),
    "nodes"
  )
  nodes <- unique(nodes)
  if (anyDuplicated(nodes$node_id)) {
    stop("`nodes$node_id` must uniquely identify one node row.", call. = FALSE)
  }
  nodes
}

ducksemantics_append_nodes <- function(conn, table, nodes) {
  if (!nrow(nodes)) {
    return(invisible(0L))
  }
  temp_table <- ducksemantics_temp_table_name("ducksemantics_incoming_nodes")
  quoted_temp <- ducksemantics_quote_ident(temp_table)
  on.exit(
    try(DBI::dbExecute(conn, paste0("DROP TABLE IF EXISTS ", quoted_temp)), silent = TRUE),
    add = TRUE
  )
  DBI::dbWriteTable(conn, temp_table, nodes, temporary = TRUE)
  DBI::dbExecute(
    conn,
    paste0(
      "INSERT INTO ", ducksemantics_quote_ident(table), " ",
      "SELECT node_id, family, label, description, attrs, trust ",
      "FROM (",
      "SELECT node_id, family, label, description, attrs, trust, ",
      "ROW_NUMBER() OVER (PARTITION BY node_id ORDER BY node_id) AS rn ",
      "FROM ", quoted_temp,
      ") incoming ",
      "WHERE rn = 1 AND NOT EXISTS (",
      "SELECT 1 FROM ", ducksemantics_quote_ident(table), " existing ",
      "WHERE existing.node_id = incoming.node_id",
      ")"
    )
  )
}

ducksemantics_append_unique_rows <- function(conn, table, rows) {
  if (!nrow(rows)) return(invisible(0L))
  temp_table <- ducksemantics_temp_table_name("ducksemantics_incoming_rows")
  quoted_temp <- ducksemantics_quote_ident(temp_table)
  quoted_table <- ducksemantics_quote_ident(table)
  columns <- names(rows)
  quoted_columns <- vapply(columns, ducksemantics_quote_ident, character(1))
  on.exit(
    try(DBI::dbExecute(conn, paste0("DROP TABLE IF EXISTS ", quoted_temp)), silent = TRUE),
    add = TRUE
  )
  DBI::dbWriteTable(conn, temp_table, rows, temporary = TRUE)
  comparisons <- paste0(
    "existing.", quoted_columns,
    " IS NOT DISTINCT FROM incoming.", quoted_columns
  )
  DBI::dbExecute(
    conn,
    paste0(
      "INSERT INTO ", quoted_table, " (", paste(quoted_columns, collapse = ", "), ") ",
      "SELECT ", paste(paste0("incoming.", quoted_columns), collapse = ", "),
      " FROM ", quoted_temp, " incoming WHERE NOT EXISTS (SELECT 1 FROM ", quoted_table,
      " existing WHERE ", paste(comparisons, collapse = " AND "), ")"
    )
  )
}

ducksemantics_prepare_aliases <- function(aliases) {
  aliases <- S7::prop(
    DucksemanticsTable(value = aliases, required = c("node_id", "alias"), allow_empty = TRUE),
    "value"
  )
  aliases <- ducksemantics_add_missing(aliases, c(
    alias_kind = "label",
    source = NA_character_,
    weight = 1,
    attrs = NA_character_
  ))
  ducksemantics_validate_required_text(aliases, c("node_id", "alias", "alias_kind"), "aliases")
  ducksemantics_validate_optional_text(aliases, c("source", "attrs"), "aliases")
  raw_weight <- aliases$weight
  aliases$weight <- suppressWarnings(as.numeric(raw_weight))
  if (any(!is.na(raw_weight) & is.na(aliases$weight)) ||
        any(!is.na(aliases$weight) & !is.finite(aliases$weight))) {
    stop("`aliases$weight` must contain finite numbers or NA.", call. = FALSE)
  }
  unique(aliases[, c("node_id", "alias", "alias_kind", "source", "weight", "attrs")])
}

ducksemantics_prepare_edges <- function(edges) {
  edges <- S7::prop(
    DucksemanticsTable(value = edges, required = c("from_id", "predicate", "to_id"), allow_empty = TRUE),
    "value"
  )
  edges <- ducksemantics_add_missing(edges, c(
    attrs = NA_character_,
    trust = NA_character_
  ))[, c("from_id", "predicate", "to_id", "attrs", "trust")]
  ducksemantics_validate_required_text(edges, c("from_id", "predicate", "to_id"), "edges")
  ducksemantics_validate_optional_text(edges, c("attrs", "trust"), "edges")
  unique(edges)
}

ducksemantics_prepare_judgments <- function(judgments) {
  judgments <- S7::prop(DucksemanticsTable(value = judgments, required = c("judgment_id", "subject_id", "predicate", "decision"), allow_empty = TRUE), "value")
  judgments <- ducksemantics_add_missing(judgments, c(
    object_id = NA_character_,
    value_json = NA_character_,
    confidence = NA_real_,
    evidence = NA_character_,
    model = NA_character_,
    recorded_at = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    attrs = NA_character_
  ))
  judgments[, c(
    "judgment_id", "subject_id", "predicate", "object_id", "value_json",
    "decision", "confidence", "evidence", "model", "recorded_at", "attrs"
  )]
}

ducksemantics_embedding_rows <- function(batch) {
  embeddings <- S7::prop(batch, "embeddings")
  subject_id <- S7::prop(batch, "subject_id")
  subject_kind <- S7::prop(batch, "subject_kind")
  provider <- S7::prop(batch, "provider")
  text <- S7::prop(batch, "text")
  attrs <- S7::prop(batch, "attrs")
  if (is.null(text)) text <- NA_character_
  if (is.null(attrs)) attrs <- NA_character_
  text <- rep(text, length.out = nrow(embeddings))
  attrs <- rep(attrs, length.out = nrow(embeddings))
  rows <- data.frame(
    subject_id = subject_id,
    subject_kind = rep(subject_kind, nrow(embeddings)),
    provider = rep(provider, nrow(embeddings)),
    text = text,
    dim = rep(ncol(embeddings), nrow(embeddings)),
    attrs = attrs,
    stringsAsFactors = FALSE
  )
  rows$embedding <- I(lapply(seq_len(nrow(embeddings)), function(i) as.single(embeddings[i, ])))
  rows[, c("subject_id", "subject_kind", "provider", "text", "dim", "embedding", "attrs")]
}

ducksemantics_token_embedding_rows <- function(batch) {
  embeddings <- S7::prop(batch, "embeddings")
  subject_id <- S7::prop(batch, "subject_id")
  subject_kind <- S7::prop(batch, "subject_kind")
  provider <- S7::prop(batch, "provider")
  token_index <- as.integer(S7::prop(batch, "token_index"))
  block_id <- S7::prop(batch, "block_id")
  token <- S7::prop(batch, "token")
  start_offset <- S7::prop(batch, "start_offset")
  end_offset <- S7::prop(batch, "end_offset")
  attrs <- S7::prop(batch, "attrs")
  n <- nrow(embeddings)
  if (is.null(token)) token <- NA_character_
  if (is.null(start_offset)) start_offset <- NA_integer_
  if (is.null(end_offset)) end_offset <- NA_integer_
  if (is.null(attrs)) attrs <- NA_character_
  rows <- data.frame(
    block_id = block_id,
    subject_id = subject_id,
    subject_kind = rep(subject_kind, n),
    provider = rep(provider, n),
    token_index = token_index,
    token = rep(token, length.out = n),
    start_offset = rep(as.integer(start_offset), length.out = n),
    end_offset = rep(as.integer(end_offset), length.out = n),
    dim = rep(ncol(embeddings), n),
    attrs = rep(attrs, length.out = n),
    stringsAsFactors = FALSE
  )
  rows$embedding <- I(lapply(seq_len(n), function(i) as.single(embeddings[i, ])))
  rows[, c(
    "block_id", "subject_id", "subject_kind", "provider", "token_index",
    "token", "start_offset", "end_offset", "dim", "embedding", "attrs"
  )]
}

ducksemantics_embedding_table_rows <- function(conn, spec, prefix = "semantic") {
  tables <- ducksemantics_tables(prefix)
  table <- S7::prop(spec, "table") %||% tables[["embeddings"]]
  table <- S7::prop(DucksemanticsSqlIdentifier(value = table, qualified = TRUE), "value")
  filters <- c("embedding IS NOT NULL")
  dimensions <- S7::prop(spec, "dimensions")
  if (!is.null(dimensions)) {
    filters <- c(filters, paste0("dim = ", as.integer(dimensions)))
  }
  provider <- S7::prop(spec, "provider")
  if (!is.null(provider)) {
    filters <- c(filters, paste0("provider = ", ducksemantics_quote_string(provider)))
  }
  subject_kind <- S7::prop(spec, "subject_kind")
  if (!is.null(subject_kind)) {
    filters <- c(filters, paste0("subject_kind = ", ducksemantics_quote_string(subject_kind)))
  }
  DBI::dbGetQuery(
    conn,
    paste0(
      "SELECT subject_id, subject_kind, provider, text, dim, embedding, attrs ",
      "FROM ", ducksemantics_quote_ident(table),
      " WHERE ", paste(filters, collapse = " AND "),
      " ORDER BY provider, subject_kind, subject_id"
    )
  )
}

ducksemantics_embedding_column_matrix <- function(embedding, dimensions) {
  if (is.matrix(embedding) && ncol(embedding) == dimensions) {
    x <- embedding
  } else {
    rows <- if (is.list(embedding)) {
      lapply(embedding, function(value) as.numeric(unlist(value, use.names = FALSE)))
    } else {
      lapply(seq_along(embedding), function(i) as.numeric(embedding[[i]]))
    }
    bad <- which(vapply(rows, length, integer(1)) != dimensions)
    if (length(bad)) {
      stop("Embedding row ", bad[[1L]], " does not match dimension ", dimensions, ".", call. = FALSE)
    }
    x <- matrix(0, nrow = length(rows), ncol = dimensions)
    for (i in seq_along(rows)) {
      x[i, ] <- rows[[i]]
    }
  }
  storage.mode(x) <- "double"
  if (anyNA(x) || any(!is.finite(x))) {
    stop("Embedding rows must contain only finite non-missing values.", call. = FALSE)
  }
  x
}

ducksemantics_l2_normalize_rows <- function(x) {
  x <- as.matrix(x)
  storage.mode(x) <- "double"
  norms <- sqrt(rowSums(x * x))
  if (any(!is.finite(norms) | norms <= 0)) {
    stop("Late-interaction embedding rows must have a finite non-zero norm.", call. = FALSE)
  }
  x / norms
}

ducksemantics_cluster_assignment_rows <- function(rows, x, fit, run_id) {
  centers <- fit$centers[fit$cluster, , drop = FALSE]
  distance <- sqrt(rowSums((x - centers) ^ 2))
  data.frame(
    cluster_run_id = run_id,
    subject_id = rows$subject_id,
    subject_kind = rows$subject_kind,
    provider = rows$provider,
    dim = as.integer(rows$dim),
    cluster_id = as.integer(fit$cluster),
    distance = as.numeric(distance),
    text = rows$text,
    attrs = rows$attrs,
    stringsAsFactors = FALSE
  )
}

ducksemantics_cluster_centroid_rows <- function(rows, fit, run_id, dimensions) {
  provider <- unique(rows$provider)
  subject_kind <- unique(rows$subject_kind)
  if (length(provider) != 1L) provider <- "<mixed>"
  if (length(subject_kind) != 1L) subject_kind <- "<mixed>"
  out <- data.frame(
    cluster_run_id = rep(run_id, nrow(fit$centers)),
    provider = rep(provider, nrow(fit$centers)),
    subject_kind = rep(subject_kind, nrow(fit$centers)),
    dim = rep(as.integer(dimensions), nrow(fit$centers)),
    cluster_id = seq_len(nrow(fit$centers)),
    size = as.integer(fit$size),
    attrs = NA_character_,
    stringsAsFactors = FALSE
  )
  out$embedding <- I(lapply(seq_len(nrow(fit$centers)), function(i) as.single(fit$centers[i, ])))
  out[, c("cluster_run_id", "provider", "subject_kind", "dim", "cluster_id", "size", "embedding", "attrs")]
}

ducksemantics_float_array_literal <- function(x) {
  values <- paste(sprintf("%.9g::FLOAT", as.numeric(x)), collapse = ",")
  paste0("[", values, "]::FLOAT[", length(x), "]")
}

ducksemantics_add_missing <- function(x, defaults) {
  for (nm in names(defaults)) {
    if (!nm %in% names(x)) {
      x[[nm]] <- rep(defaults[[nm]], nrow(x))
    }
  }
  x
}

ducksemantics_empty_mentions <- function() {
  data.frame(
    document_id = character(),
    mention_id = character(),
    node_id = character(),
    span = character(),
    start_offset = integer(),
    end_offset = integer(),
    score = numeric(),
    method = character(),
    attrs = character(),
    trust = character(),
    alias = character(),
    alias_kind = character(),
    source = character(),
    stringsAsFactors = FALSE
  )
}

ducksemantics_empty_nodes <- function() {
  data.frame(
    node_id = character(),
    family = character(),
    label = character(),
    description = character(),
    attrs = character(),
    trust = character(),
    stringsAsFactors = FALSE
  )
}

ducksemantics_empty_aliases <- function() {
  data.frame(
    node_id = character(),
    alias = character(),
    alias_kind = character(),
    source = character(),
    weight = numeric(),
    attrs = character(),
    stringsAsFactors = FALSE
  )
}

ducksemantics_empty_edges <- function() {
  data.frame(
    from_id = character(),
    predicate = character(),
    to_id = character(),
    attrs = character(),
    trust = character(),
    stringsAsFactors = FALSE
  )
}

ducksemantics_empty_mentions_with_case <- function() {
  out <- ducksemantics_empty_mentions()
  out$case_id <- character()
  out
}

ducksemantics_empty_judgments <- function() {
  data.frame(
    judgment_id = character(),
    subject_id = character(),
    predicate = character(),
    object_id = character(),
    value_json = character(),
    decision = character(),
    confidence = numeric(),
    evidence = character(),
    model = character(),
    recorded_at = character(),
    attrs = character(),
    stringsAsFactors = FALSE
  )
}

ducksemantics_bind_or_empty <- function(rows, empty) {
  rows <- rows[lengths(rows) > 0L]
  if (!length(rows)) {
    return(empty)
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

ducksemantics_obo_term_stanzas <- function(lines) {
  stanzas <- list()
  current <- character()
  in_term <- FALSE
  for (line in c(lines, "")) {
    line <- trimws(line)
    if (!nzchar(line)) {
      if (isTRUE(in_term) && length(current)) {
        stanzas[[length(stanzas) + 1L]] <- current
      }
      current <- character()
      in_term <- FALSE
      next
    }
    if (startsWith(line, "[")) {
      if (isTRUE(in_term) && length(current)) {
        stanzas[[length(stanzas) + 1L]] <- current
      }
      current <- character()
      in_term <- identical(line, "[Term]")
      next
    }
    if (isTRUE(in_term)) {
      current <- c(current, line)
    }
  }
  stanzas
}

ducksemantics_obo_lines <- function(stanza, tag) {
  prefix <- paste0(tag, ":")
  stanza[startsWith(stanza, prefix)]
}

ducksemantics_obo_values <- function(stanza, tag) {
  lines <- ducksemantics_obo_lines(stanza, tag)
  trimws(sub(paste0("^", tag, ":[[:space:]]*"), "", lines, perl = TRUE))
}

ducksemantics_obo_first_line <- function(stanza, tag) {
  lines <- ducksemantics_obo_lines(stanza, tag)
  if (!length(lines)) NA_character_ else lines[[1L]]
}

ducksemantics_obo_first <- function(stanza, tag) {
  values <- ducksemantics_obo_values(stanza, tag)
  if (!length(values)) NA_character_ else values[[1L]]
}

ducksemantics_obo_quoted <- function(line) {
  if (is.na(line) || !grepl('"', line, fixed = TRUE)) {
    return(NA_character_)
  }
  value <- sub('^[^"]*"(([^"\\\\]|\\\\.)*)".*$', "\\1", line, perl = TRUE)
  ducksemantics_obo_unescape(value)
}

ducksemantics_obo_unescape <- function(value) {
  chars <- strsplit(value, "", fixed = TRUE)[[1L]]
  if (!length(chars) || !any(chars == "\\")) return(value)
  out <- character()
  i <- 1L
  while (i <= length(chars)) {
    if (chars[[i]] != "\\" || i == length(chars)) {
      out <- c(out, chars[[i]])
      i <- i + 1L
      next
    }
    escaped <- chars[[i + 1L]]
    out <- c(out, switch(escaped, n = "\n", t = "\t", W = " ", escaped))
    i <- i + 2L
  }
  paste0(out, collapse = "")
}

ducksemantics_obo_object_id <- function(value) {
  value <- sub("[[:space:]]*!.*$", "", value, perl = TRUE)
  value <- sub("[[:space:]]*\\{.*$", "", value, perl = TRUE)
  fields <- strsplit(trimws(value), "[[:space:]]+", perl = TRUE)[[1L]]
  if (!length(fields)) NA_character_ else fields[[1L]]
}

ducksemantics_obo_synonym_kind <- function(line) {
  rest <- sub('^[^"]*"([^"\\\\]|\\\\.)*"[[:space:]]*', "", line, perl = TRUE)
  kind <- strsplit(rest, "[[:space:]]+", perl = TRUE)[[1L]][[1L]]
  kind <- tolower(kind)
  if (!nzchar(kind) || identical(kind, "[]")) "synonym" else paste0("synonym:", kind)
}

ducksemantics_ngrams <- function(text, tokens, max_n, document_id = NULL) {
  rows <- list()
  k <- 0L
  n_tokens <- nrow(tokens)
  for (i in seq_len(n_tokens)) {
    upper <- min(n_tokens, i + max_n - 1L)
    for (j in seq.int(i, upper)) {
      start <- tokens$start_offset[[i]]
      end <- tokens$end_offset[[j]]
      span <- substring(text, start + 1L, end)
      normalized <- ducksemantics_normalize(span)
      if (!nzchar(normalized)) next
      k <- k + 1L
      rows[[k]] <- data.frame(
        document_id = document_id %||% NA_character_,
        mention_id = sprintf("%s%06d", if (is.null(document_id)) "mention:" else paste0(document_id, ":"), k),
        span = span,
        normalized_span = normalized,
        start_offset = start,
        end_offset = end,
        token_count = j - i + 1L,
        stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) {
    return(data.frame(
      document_id = character(),
      mention_id = character(),
      span = character(),
      normalized_span = character(),
      start_offset = integer(),
      end_offset = integer(),
      token_count = integer(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

ducksemantics_longest_matches <- function(x) {
  widths <- x$end_offset - x$start_offset
  ord <- order(-widths, x$start_offset, x$end_offset, x$node_id)
  keep <- rep(FALSE, nrow(x))
  kept <- integer()
  for (idx in ord) {
    contained <- FALSE
    for (j in kept) {
      strict <- x$start_offset[[j]] < x$start_offset[[idx]] || x$end_offset[[j]] > x$end_offset[[idx]]
      if (strict && x$start_offset[[j]] <= x$start_offset[[idx]] && x$end_offset[[j]] >= x$end_offset[[idx]]) {
        contained <- TRUE
        break
      }
    }
    if (!contained) {
      keep[[idx]] <- TRUE
      kept <- c(kept, idx)
    }
  }
  x[keep, , drop = FALSE][order(x$start_offset[keep], x$end_offset[keep], x$node_id[keep]), , drop = FALSE]
}

ducksemantics_mentions_payload <- function(mentions) {
  mentions <- S7::prop(DucksemanticsTable(value = mentions, required = character(), allow_empty = TRUE), "value")
  keep <- intersect(
    c("mention_id", "node_id", "span", "start_offset", "end_offset", "score", "alias", "alias_kind", "source"),
    names(mentions)
  )
  mentions[, keep, drop = FALSE]
}

ducksemantics_prompt_text <- function(x, arg) {
  if (!is.character(x) || anyNA(x) || !length(x)) {
    stop("`", arg, "` must be a non-empty character vector without NA.", call. = FALSE)
  }
  x <- paste(x, collapse = "\n")
  if (!nzchar(trimws(x))) {
    stop("`", arg, "` must not be blank.", call. = FALSE)
  }
  x
}

ducksemantics_judgment_parse_error <- function(error, response) {
  ducksemantics_judgment_parse_error_class(
    message = conditionMessage(error),
    response = ducksemantics_response_text(response)
  )
}

ducksemantics_bebel_parse_repair_prompt <- function(parse_error) {
  if (!S7::S7_inherits(parse_error, ducksemantics_judgment_parse_error_class)) {
    stop("`parse_error` must be a Ducksemantics judgment parse error.", call. = FALSE)
  }
  paste(
    "Your preceding response failed the required semantic-judgment JSON contract.",
    paste0("PARSE_ERROR: ", S7::prop(parse_error, "message")),
    "The source text and CANDIDATES_JSON are in the immediately preceding user turn.",
    "Return a corrected response only: its first character must be [ and its final character must be ].",
    "Do not use candidates_json, CANDIDATES_JSON, judgments, results, or any other top-level wrapper key.",
    "The array must have exactly one object per candidate, in candidate order.",
    "Every object must copy that candidate's mention_id exactly and include decision.",
    sep = "\n"
  )
}

ducksemantics_response_text <- function(x) {
  if (is.character(x) && length(x) == 1L && !is.na(x)) {
    return(x)
  }
  if (is.list(x) && "text" %in% names(x)) {
    return(ducksemantics_response_text(x[["text"]]))
  }
  out <- as.character(x)
  if (!length(out) || is.na(out[[1L]])) {
    stop("Provider response could not be converted to text.", call. = FALSE)
  }
  out[[1L]]
}

ducksemantics_parse_json_response <- function(response) {
  S7::prop(DucksemanticsScalarText(value = response), "value")
  ducksemantics_require_jsonlite()
  json <- ducksemantics_extract_json(response)
  jsonlite::fromJSON(json, simplifyDataFrame = TRUE)
}

ducksemantics_normalize_judgment_payload <- function(parsed) {
  wrapper_names <- c("array", "judgments", "results", "items", "arguments", "args")
  if (is.list(parsed) && !length(parsed)) {
    return(data.frame(mention_id = character(), decision = character()))
  }
  if (is.data.frame(parsed)) {
    prefixes <- paste0(wrapper_names, ".")
    for (prefix in prefixes) {
      prefixed <- startsWith(names(parsed), prefix)
      if (any(prefixed) && !"mention_id" %in% names(parsed)) {
        names(parsed)[prefixed] <- substring(names(parsed)[prefixed], nchar(prefix, type = "chars") + 1L)
      }
    }
    return(parsed)
  }
  if (is.list(parsed)) {
    for (wrapper in wrapper_names) {
      if (!is.null(parsed[[wrapper]])) {
        return(ducksemantics_normalize_judgment_payload(parsed[[wrapper]]))
      }
    }
    if (all(c("mention_id", "decision") %in% names(parsed))) {
      return(ducksemantics_lists_to_data_frame(list(parsed)))
    }
    stop(
      "JSON judgment payload must be an array, a documented wrapper, or one object with mention_id and decision.",
      call. = FALSE
    )
  }
  parsed
}

ducksemantics_extract_json <- function(response) {
  response <- trimws(response)
  if (startsWith(response, "[") || startsWith(response, "{")) {
    return(response)
  }
  starts <- gregexpr("[\\[{]", response, perl = TRUE)[[1L]]
  if (identical(starts, -1L)) {
    stop("BebeLM response did not contain JSON.", call. = FALSE)
  }
  for (start in starts) {
    candidate <- substring(response, start)
    ok <- try(jsonlite::validate(candidate), silent = TRUE)
    if (isTRUE(ok)) return(candidate)
  }
  stop("BebeLM response did not contain valid JSON.", call. = FALSE)
}

ducksemantics_judgments_from_model <- function(parsed,
                                               mentions,
                                               model = "Rbebelm",
                                               allowed_node_id = NULL) {
  ducksemantics_require_jsonlite()
  mentions <- S7::prop(
    DucksemanticsTable(
      value = mentions,
      required = c("mention_id", "node_id"),
      allow_empty = TRUE
    ),
    "value"
  )
  ducksemantics_validate_required_text(mentions, c("mention_id", "node_id"), "mentions")
  expected_ids <- as.character(mentions$mention_id)
  if (anyDuplicated(expected_ids)) {
    stop("`mentions$mention_id` must uniquely identify each candidate.", call. = FALSE)
  }
  if (is.list(parsed) && !is.data.frame(parsed)) {
    parsed <- ducksemantics_lists_to_data_frame(parsed)
  }
  parsed <- S7::prop(
    DucksemanticsTable(
      value = parsed,
      required = c("mention_id", "decision"),
      allow_empty = TRUE
    ),
    "value"
  )
  if (!nrow(parsed) && !length(expected_ids)) return(ducksemantics_empty_judgments())
  ducksemantics_validate_required_text(parsed, c("mention_id", "decision"), "parsed")
  parsed$mention_id <- as.character(parsed$mention_id)
  parsed$decision <- as.character(parsed$decision)
  if (anyDuplicated(parsed$mention_id)) {
    stop("Model returned duplicate mention_id values.", call. = FALSE)
  }
  if (!identical(parsed$mention_id, expected_ids)) {
    stop(
      "Model response must contain exactly one result per candidate in candidate order.",
      call. = FALSE
    )
  }

  allowed_decisions <- c("keep", "drop", "replace", "enrich")
  bad_decisions <- setdiff(unique(parsed$decision), allowed_decisions)
  if (length(bad_decisions)) {
    stop(
      "Model returned unsupported decision value(s): ",
      paste(bad_decisions, collapse = ", "),
      call. = FALSE
    )
  }
  raw_confidence <- if ("confidence" %in% names(parsed)) parsed$confidence else rep(NA, nrow(parsed))
  confidence <- suppressWarnings(as.numeric(raw_confidence))
  conversion_failed <- !is.na(raw_confidence) & is.na(confidence)
  if (length(confidence) != nrow(parsed) || any(conversion_failed) ||
        any(!is.na(confidence) & (!is.finite(confidence) | confidence < 0 | confidence > 1))) {
    stop("Model confidence values must be finite numbers from 0 to 1 or null.", call. = FALSE)
  }

  replacement <- if ("replacement_node_id" %in% names(parsed)) {
    as.character(parsed$replacement_node_id)
  } else {
    rep(NA_character_, nrow(parsed))
  }
  has_replacement <- !is.na(replacement) & nzchar(replacement)
  if (any(parsed$decision == "replace" & !has_replacement)) {
    stop("Every replace decision must supply replacement_node_id.", call. = FALSE)
  }
  if (any(parsed$decision %in% c("keep", "drop") & has_replacement)) {
    stop("keep and drop decisions must not supply replacement_node_id.", call. = FALSE)
  }
  allowed_node_id <- unique(as.character(c(mentions$node_id, allowed_node_id)))
  allowed_node_id <- allowed_node_id[!is.na(allowed_node_id) & nzchar(allowed_node_id)]
  unknown <- setdiff(unique(replacement[has_replacement]), allowed_node_id)
  if (length(unknown)) {
    stop(
      "Model returned replacement_node_id values outside supplied candidates or graph context: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  parsed$node_id <- as.character(mentions$node_id)
  object_id <- parsed$node_id
  object_id[has_replacement] <- replacement[has_replacement]
  object_id[parsed$decision == "drop"] <- NA_character_
  value_json <- vapply(seq_len(nrow(parsed)), function(i) {
    jsonlite::toJSON(as.list(parsed[i, , drop = FALSE]), auto_unbox = TRUE, null = "null")
  }, character(1))
  evidence <- vapply(seq_len(nrow(parsed)), function(i) {
    fields <- intersect(c("evidence_span", "short_reason", "patient_context"), names(parsed))
    jsonlite::toJSON(as.list(parsed[i, fields, drop = FALSE]), auto_unbox = TRUE, null = "null")
  }, character(1))
  data.frame(
    judgment_id = paste0("judgment:", parsed$mention_id),
    subject_id = parsed$mention_id,
    predicate = "semantic:grounding_decision",
    object_id = object_id,
    value_json = value_json,
    decision = parsed$decision,
    confidence = confidence,
    evidence = evidence,
    model = model,
    recorded_at = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    attrs = NA_character_,
    stringsAsFactors = FALSE
  )
}

ducksemantics_judgment_node_ids <- function(mentions, graph_context = NULL) {
  ids <- if (is.data.frame(mentions) && "node_id" %in% names(mentions)) {
    as.character(mentions$node_id)
  } else {
    character()
  }
  collect <- function(value) {
    if (is.data.frame(value)) {
      columns <- grep("(^|_)(node_id|from_id|to_id|object_id)$", names(value), value = TRUE)
      return(unlist(lapply(value[columns], as.character), use.names = FALSE))
    }
    if (is.list(value)) {
      direct <- character()
      if (!is.null(names(value))) {
        columns <- grep("(^|_)(node_id|from_id|to_id|object_id)$", names(value), value = TRUE)
        direct <- unlist(lapply(value[columns], as.character), use.names = FALSE)
      }
      return(c(direct, unlist(lapply(value, collect), use.names = FALSE)))
    }
    character()
  }
  ids <- unique(c(ids, collect(graph_context)))
  ids[!is.na(ids) & nzchar(ids)]
}

ducksemantics_metric_keys <- function(x, by = "node") {
  if (!nrow(x)) return(character())
  case_id <- as.character(x$case_id)
  node_id <- as.character(x$node_id)
  if (identical(by, "node")) {
    return(unique(paste(case_id, node_id, sep = "\r")))
  }
  if (identical(by, "offset")) {
    return(unique(paste(
      case_id,
      node_id,
      as.integer(x$start_offset),
      as.integer(x$end_offset),
      sep = "\r"
    )))
  }
  if (identical(by, "span_text")) {
    return(unique(paste(case_id, node_id, as.character(x$span), sep = "\r")))
  }
  stop("Unknown internal metric key mode.", call. = FALSE)
}

ducksemantics_benchmark_case_metrics <- function(predictions, gold, case_ids) {
  case_ids <- unique(as.character(case_ids))
  rows <- lapply(case_ids, function(case_id) {
    pred_i <- predictions[predictions$case_id == case_id, , drop = FALSE]
    gold_i <- gold[gold$case_id == case_id, , drop = FALSE]
    out <- ducksemantics_benchmark_metrics(pred_i, gold_i)
    out$case_id <- case_id
    out[, c("case_id", setdiff(names(out), "case_id")), drop = FALSE]
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

ducksemantics_benchmark_environment <- function() {
  packages <- c("ducksemantics", "duckdb", "DBI", "S7", "s7contract", "Rbebelm")
  versions <- vapply(packages, function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      return(NA_character_)
    }
    as.character(utils::packageVersion(pkg))
  }, character(1), USE.NAMES = TRUE)
  system <- Sys.info()
  list(
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    platform = R.version$platform,
    os_type = .Platform$OS.type,
    sysname = unname(system[["sysname"]]),
    os_release = unname(system[["release"]]),
    machine = unname(system[["machine"]]),
    packages = as.list(versions)
  )
}

ducksemantics_database_size <- function(conn) {
  tryCatch(
    DBI::dbGetQuery(conn, "PRAGMA database_size"),
    error = function(e) data.frame()
  )
}

ducksemantics_require_jsonlite <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for semantic judgment JSON handling.", call. = FALSE)
  }
  invisible(TRUE)
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) y else x
}
