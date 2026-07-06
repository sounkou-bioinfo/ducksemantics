DUCKSEMANTICS_SCHEMA_VERSION <- "ducksemantics.schema.v0"

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
  prefix <- ducksemantics_check_identifier(prefix, "prefix")
  tables <- ducksemantics_tables(prefix)

  c(
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["nodes"]]), " (",
      "node_id TEXT PRIMARY KEY, ",
      "family TEXT NOT NULL, ",
      "label TEXT, ",
      "description TEXT, ",
      "attrs JSON, ",
      "trust JSON",
      ")"
    ),
    paste0(
      "CREATE TABLE IF NOT EXISTS ", ducksemantics_quote_ident(tables[["aliases"]]), " (",
      "node_id TEXT NOT NULL, ",
      "alias TEXT NOT NULL, ",
      "alias_kind TEXT NOT NULL, ",
      "source TEXT, ",
      "weight DOUBLE, ",
      "attrs JSON",
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
      "attrs JSON, ",
      "trust JSON",
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
      "attrs JSON, ",
      "trust JSON",
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
      "evidence JSON, ",
      "model TEXT, ",
      "recorded_at TIMESTAMP, ",
      "attrs JSON",
      ")"
    )
  )
}

#' Semantic graph table names
#'
#' @param prefix Prefix used for generated table names.
#' @return A named character vector.
#' @export
ducksemantics_tables <- function(prefix = "semantic") {
  prefix <- ducksemantics_check_identifier(prefix, "prefix")
  c(
    nodes = paste0(prefix, "_nodes"),
    aliases = paste0(prefix, "_aliases"),
    alias_index = paste0(prefix, "_alias_index"),
    edges = paste0(prefix, "_edges"),
    entailed_edges = paste0(prefix, "_entailed_edges"),
    mentions = paste0(prefix, "_mentions"),
    judgments = paste0(prefix, "_judgments")
  )
}

#' Connect to a DuckDB semantic store
#'
#' @param dbdir DuckDB database path, or `":memory:"`.
#' @param read_only Open read-only?
#' @return A DBI connection.
#' @export
ducksemantics_connect <- function(dbdir = ":memory:", read_only = FALSE) {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("The duckdb R package is required to create a DuckDB connection.", call. = FALSE)
  }
  check_scalar_character(dbdir, "dbdir")
  check_flag(read_only, "read_only")
  DBI::dbConnect(duckdb::duckdb(), dbdir = dbdir, read_only = read_only)
}

#' Initialize semantic graph tables
#'
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return Invisibly, `conn`.
#' @export
ducksemantics_init <- function(conn, prefix = "semantic") {
  ducksemantics_check_connection(conn)
  for (sql in ducksemantics_schema_sql(prefix)) {
    DBI::dbExecute(conn, sql)
  }
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
  check_flag(replace, "replace")
  check_flag(index, "index")
  tables <- ducksemantics_tables(prefix)

  if (!is.null(nodes)) {
    nodes <- ducksemantics_prepare_nodes(nodes)
    if (replace) DBI::dbExecute(conn, paste0("DELETE FROM ", ducksemantics_quote_ident(tables[["nodes"]])))
    ducksemantics_append_nodes(conn, tables[["nodes"]], nodes)
  }
  if (!is.null(aliases)) {
    aliases <- ducksemantics_prepare_aliases(aliases)
    if (replace) DBI::dbExecute(conn, paste0("DELETE FROM ", ducksemantics_quote_ident(tables[["aliases"]])))
    DBI::dbAppendTable(conn, tables[["aliases"]], unique(aliases))
  }
  if (!is.null(edges)) {
    edges <- ducksemantics_prepare_edges(edges)
    if (replace) DBI::dbExecute(conn, paste0("DELETE FROM ", ducksemantics_quote_ident(tables[["edges"]])))
    DBI::dbAppendTable(conn, tables[["edges"]], unique(edges))
  }
  if (isTRUE(index) && !is.null(aliases)) {
    ducksemantics_index_aliases(conn, prefix = prefix)
  }

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
  check_scalar_character(url, "url")
  check_scalar_character(filename, "filename")
  check_scalar_character(cache_dir, "cache_dir")
  check_flag(refresh, "refresh")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  path <- file.path(cache_dir, filename)
  if (isTRUE(refresh) || !file.exists(path) || file.info(path)$size == 0) {
    utils::download.file(url, path, mode = "wb", quiet = TRUE)
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
  check_scalar_character(path, "path")
  if (!is.function(compute)) {
    stop("`compute` must be a function.", call. = FALSE)
  }
  check_flag(refresh, "refresh")
  cache_dir <- dirname(path)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (isTRUE(refresh) || !file.exists(path) || file.info(path)$size == 0) {
    saveRDS(compute(), path)
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
  check_scalar_character(path, "path")
  check_scalar_character(family, "family")
  check_scalar_character(source, "source")
  check_flag(include_obsolete, "include_obsolete")
  if (!file.exists(path)) {
    stop("OBO file does not exist: ", path, call. = FALSE)
  }

  lines <- readLines(path, warn = FALSE)
  stanzas <- ducksemantics_obo_term_stanzas(lines)
  nodes <- vector("list", length(stanzas))
  aliases <- list()
  edges <- list()
  node_n <- 0L
  alias_n <- 0L
  edge_n <- 0L

  for (stanza in stanzas) {
    id <- ducksemantics_obo_first(stanza, "id")
    if (is.na(id) || !nzchar(id)) next
    obsolete <- identical(tolower(ducksemantics_obo_first(stanza, "is_obsolete")), "true")
    if (isTRUE(obsolete) && !isTRUE(include_obsolete)) next

    label <- ducksemantics_obo_first(stanza, "name")
    description <- ducksemantics_obo_quoted(ducksemantics_obo_first_line(stanza, "def"))
    node_n <- node_n + 1L
    nodes[[node_n]] <- data.frame(
      node_id = id,
      family = family,
      label = label,
      description = description,
      attrs = NA_character_,
      trust = NA_character_,
      stringsAsFactors = FALSE
    )

    if (!is.na(label) && nzchar(label)) {
      alias_n <- alias_n + 1L
      aliases[[alias_n]] <- data.frame(
        node_id = id,
        alias = label,
        alias_kind = "label",
        source = source,
        weight = 1,
        attrs = NA_character_,
        stringsAsFactors = FALSE
      )
    }
    for (syn_line in ducksemantics_obo_lines(stanza, "synonym")) {
      syn <- ducksemantics_obo_quoted(syn_line)
      if (is.na(syn) || !nzchar(syn)) next
      alias_n <- alias_n + 1L
      aliases[[alias_n]] <- data.frame(
        node_id = id,
        alias = syn,
        alias_kind = ducksemantics_obo_synonym_kind(syn_line),
        source = source,
        weight = 0.95,
        attrs = NA_character_,
        stringsAsFactors = FALSE
      )
    }
    for (is_a in ducksemantics_obo_values(stanza, "is_a")) {
      edge_n <- edge_n + 1L
      edges[[edge_n]] <- data.frame(
        from_id = id,
        predicate = "is_a",
        to_id = sub("\\s*!.*$", "", is_a, perl = TRUE),
        attrs = NA_character_,
        trust = NA_character_,
        stringsAsFactors = FALSE
      )
    }
    for (rel in ducksemantics_obo_values(stanza, "relationship")) {
      parts <- strsplit(sub("\\s*!.*$", "", rel, perl = TRUE), "[[:space:]]+", perl = TRUE)[[1L]]
      parts <- parts[nzchar(parts)]
      if (length(parts) < 2L) next
      edge_n <- edge_n + 1L
      edges[[edge_n]] <- data.frame(
        from_id = id,
        predicate = parts[[1L]],
        to_id = parts[[2L]],
        attrs = NA_character_,
        trust = NA_character_,
        stringsAsFactors = FALSE
      )
    }
  }

  list(
    nodes = ducksemantics_bind_or_empty(nodes[seq_len(node_n)], ducksemantics_empty_nodes()),
    aliases = ducksemantics_bind_or_empty(aliases, ducksemantics_empty_aliases()),
    edges = ducksemantics_bind_or_empty(edges, ducksemantics_empty_edges())
  )
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
  check_scalar_character(text, "text")
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
  ducksemantics_check_connection(conn)
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
  ducksemantics_check_connection(conn)
  check_scalar_character(text, "text")
  if (!is.null(document_id)) check_scalar_character(document_id, "document_id")
  check_flag(longest_match, "longest_match")
  check_flag(record, "record")
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
  candidate_table <- paste0("ducksemantics_candidates_", as.integer(stats::runif(1L, 1e8, 1e9 - 1L)))
  DBI::dbWriteTable(conn, candidate_table, candidates, temporary = TRUE, overwrite = TRUE)
  on.exit(try(DBI::dbExecute(conn, paste0("DROP TABLE IF EXISTS ", ducksemantics_quote_ident(candidate_table))), silent = TRUE), add = TRUE)

  sql <- paste0(
    "SELECT c.document_id, c.mention_id, a.node_id, c.span, ",
    "c.start_offset, c.end_offset, a.weight AS score, ",
    "'lexical_alias' AS method, CAST(NULL AS JSON) AS attrs, CAST(NULL AS JSON) AS trust, ",
    "a.alias, a.alias_kind, a.source ",
    "FROM ", ducksemantics_quote_ident(candidate_table), " c ",
    "JOIN ", ducksemantics_quote_ident(tables[["alias_index"]]), " a ",
    "ON c.normalized_span = a.normalized_alias AND c.token_count = a.token_count ",
    "ORDER BY c.start_offset, c.end_offset DESC, a.node_id"
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
    "Return only JSON: an array of objects with mention_id, decision, confidence, patient_context, evidence_span, short_reason, and optional replacement_node_id.",
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
  check_scalar_character(text, "text")
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
#' @param on_event Optional Rbebelm event callback.
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
  check_scalar_character(text, "text")
  s7contract::assert_implements(runner, DucksemanticsPromptRunner, arg = "runner")
  s7contract::assert_implements(parser, DucksemanticsJudgmentParser, arg = "parser")
  if (!is.function(prompt_builder)) {
    stop("`prompt_builder` must be a function.", call. = FALSE)
  }
  check_flag(record, "record")
  check_scalar_character(model, "model")

  prompt <- prompt_builder(
    text = text,
    mentions = mentions,
    graph_context = graph_context,
    instructions = instructions,
    ...
  )
  response <- ducksemantics_run(runner, prompt)
  parsed <- ducksemantics_parse(parser, response)
  judgments <- ducksemantics_judgments_from_model(parsed, mentions, model = model)
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
#' @param on_event Optional Rbebelm event callback.
#' @param record Append judgments to the judgment table?
#' @param model Model label recorded with judgments.
#' @return A data frame of judgment rows.
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
                                      record = !is.null(conn),
                                      model = "Rbebelm") {
  if (!requireNamespace("Rbebelm", quietly = TRUE)) {
    stop("Rbebelm is required for BebeLM judgment.", call. = FALSE)
  }
  ducksemantics_judge(
    text = text,
    mentions = mentions,
    runner = ducksemantics_bebel_runner(agent, on_event = on_event),
    conn = conn,
    prefix = prefix,
    graph_context = graph_context,
    instructions = instructions,
    parser = parser,
    record = record,
    model = model
  )
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

#' Summarize semantic index size
#'
#' @param conn DBI connection.
#' @param prefix Prefix used for semantic tables.
#' @return A list with table row counts and alias-index pressure metrics.
#' @export
ducksemantics_index_stats <- function(conn, prefix = "semantic") {
  ducksemantics_check_connection(conn)
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
#' @return A benchmark object.
#' @export
ducksemantics_benchmark_cases <- function(cases, gold, suite = "semantic") {
  cases <- ducksemantics_check_data_frame(cases, "cases")
  gold <- ducksemantics_check_data_frame(gold, "gold")
  ducksemantics_require_columns(cases, c("case_id", "text"), "cases")
  ducksemantics_require_columns(gold, c("case_id", "node_id"), "gold")
  check_scalar_character(suite, "suite")

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
  ducksemantics_check_connection(conn)
  if (!inherits(benchmark, "ducksemantics_benchmark")) {
    stop("`benchmark` must come from ducksemantics_benchmark_cases().", call. = FALSE)
  }
  s7contract::assert_implements(annotator, DucksemanticsAnnotator, arg = "annotator")
  check_flag(longest_match, "longest_match")
  check_flag(record, "record")
  check_flag(collect_index_stats, "collect_index_stats")

  predictions <- list()
  timings <- vector("list", nrow(benchmark$cases))
  for (i in seq_len(nrow(benchmark$cases))) {
    case_id <- as.character(benchmark$cases$case_id[[i]])
    text <- as.character(benchmark$cases$text[[i]])
    elapsed <- system.time({
      pred <- ducksemantics_ground(
        annotator = annotator,
        conn = conn,
        text = text,
        document_id = case_id,
        prefix = prefix,
        longest_match = longest_match,
        record = record
      )
    })
    if (nrow(pred)) {
      pred$case_id <- case_id
      predictions[[length(predictions) + 1L]] <- pred
    }
    timings[[i]] <- data.frame(
      case_id = case_id,
      seconds = unname(elapsed[["elapsed"]]),
      token_count = nrow(ducksemantics_tokens(text)),
      prediction_count = nrow(pred),
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
  out <- list(
    suite = benchmark$suite,
    predictions = predictions,
    timings = timings,
    metrics = metrics,
    index_stats = if (isTRUE(collect_index_stats)) ducksemantics_index_stats(conn, prefix = prefix) else NULL
  )
  class(out) <- c("ducksemantics_benchmark_result", "list")
  out
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
  predictions <- ducksemantics_check_data_frame(predictions, "predictions")
  gold <- ducksemantics_check_data_frame(gold, "gold")
  ducksemantics_require_columns(gold, c("case_id", "node_id"), "gold")
  if (!"case_id" %in% names(predictions)) {
    if ("document_id" %in% names(predictions)) {
      predictions$case_id <- predictions$document_id
    } else {
      stop("`predictions` must contain `case_id` or `document_id`.", call. = FALSE)
    }
  }
  ducksemantics_require_columns(predictions, c("case_id", "node_id"), "predictions")

  pred_keys <- ducksemantics_metric_keys(predictions, by = by)
  gold_keys <- ducksemantics_metric_keys(gold, by = by)
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
#' @param attrs,trust Optional source columns containing JSON.
#' @return A single `CREATE OR REPLACE TABLE ... AS SELECT ...` SQL statement.
#' @export
ducksemantics_projection_sql <- function(source_table,
                                         from,
                                         predicate,
                                         to,
                                         target_table = "semantic_edges",
                                         attrs = NULL,
                                         trust = NULL) {
  source_table <- ducksemantics_check_identifier(source_table, "source_table", qualified = TRUE)
  target_table <- ducksemantics_check_identifier(target_table, "target_table", qualified = TRUE)
  from <- ducksemantics_check_identifier(from, "from")
  predicate <- ducksemantics_check_identifier(predicate, "predicate")
  to <- ducksemantics_check_identifier(to, "to")
  attrs_sql <- ducksemantics_optional_column(attrs, "attrs")
  trust_sql <- ducksemantics_optional_column(trust, "trust")

  paste0(
    "CREATE OR REPLACE TABLE ", ducksemantics_quote_ident(target_table),
    " AS SELECT ",
    ducksemantics_quote_ident(from), " AS from_id, ",
    ducksemantics_quote_ident(predicate), " AS predicate, ",
    ducksemantics_quote_ident(to), " AS to_id, ",
    attrs_sql, " AS attrs, ",
    trust_sql, " AS trust",
    " FROM ", ducksemantics_quote_ident(source_table)
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
#' @return A single SQL statement.
#' @export
ducksemantics_closure_sql <- function(transitive_predicates,
                                      source_table = "semantic_edges",
                                      target_table = "semantic_entailed_edges") {
  source_table <- ducksemantics_check_identifier(source_table, "source_table", qualified = TRUE)
  target_table <- ducksemantics_check_identifier(target_table, "target_table", qualified = TRUE)
  if (!is.character(transitive_predicates) || anyNA(transitive_predicates) || any(!nzchar(transitive_predicates))) {
    stop("`transitive_predicates` must be a character vector of non-empty strings.", call. = FALSE)
  }
  if (!length(transitive_predicates)) {
    return(paste0(
      "CREATE OR REPLACE TABLE ", ducksemantics_quote_ident(target_table),
      " (from_id TEXT, predicate TEXT, to_id TEXT)"
    ))
  }

  predicates <- paste(vapply(transitive_predicates, ducksemantics_quote_string, character(1)), collapse = ", ")
  paste0(
    "CREATE OR REPLACE TABLE ", ducksemantics_quote_ident(target_table), " AS ",
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

ducksemantics_optional_column <- function(column, arg) {
  if (is.null(column)) {
    return("NULL")
  }
  column <- ducksemantics_check_identifier(column, arg)
  ducksemantics_quote_ident(column)
}

ducksemantics_check_identifier <- function(x, arg, qualified = FALSE) {
  check_scalar_character(x, arg)
  pattern <- if (isTRUE(qualified)) {
    "^[A-Za-z_][A-Za-z0-9_]*(\\.[A-Za-z_][A-Za-z0-9_]*){0,2}$"
  } else {
    "^[A-Za-z_][A-Za-z0-9_]*$"
  }
  if (!grepl(pattern, x, perl = TRUE)) {
    stop("`", arg, "` must be a valid SQL identifier.", call. = FALSE)
  }
  x
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

ducksemantics_check_connection <- function(conn) {
  if (!DBI::dbIsValid(conn)) {
    stop("`conn` must be a valid DBI connection.", call. = FALSE)
  }
  invisible(conn)
}

ducksemantics_prepare_nodes <- function(nodes) {
  nodes <- ducksemantics_check_data_frame(nodes, "nodes")
  ducksemantics_require_columns(nodes, c("node_id", "family"), "nodes")
  ducksemantics_add_missing(nodes, c(
    label = NA_character_,
    description = NA_character_,
    attrs = NA_character_,
    trust = NA_character_
  ))[, c("node_id", "family", "label", "description", "attrs", "trust")]
}

ducksemantics_append_nodes <- function(conn, table, nodes) {
  if (!nrow(nodes)) {
    return(invisible(0L))
  }
  temp_table <- paste0("ducksemantics_incoming_nodes_", Sys.getpid(), "_", sample.int(1e9, 1L))
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

ducksemantics_prepare_aliases <- function(aliases) {
  aliases <- ducksemantics_check_data_frame(aliases, "aliases")
  ducksemantics_require_columns(aliases, c("node_id", "alias"), "aliases")
  aliases <- ducksemantics_add_missing(aliases, c(
    alias_kind = "label",
    source = NA_character_,
    weight = 1,
    attrs = NA_character_
  ))
  aliases$weight <- as.numeric(aliases$weight)
  aliases[, c("node_id", "alias", "alias_kind", "source", "weight", "attrs")]
}

ducksemantics_prepare_edges <- function(edges) {
  edges <- ducksemantics_check_data_frame(edges, "edges")
  ducksemantics_require_columns(edges, c("from_id", "predicate", "to_id"), "edges")
  ducksemantics_add_missing(edges, c(
    attrs = NA_character_,
    trust = NA_character_
  ))[, c("from_id", "predicate", "to_id", "attrs", "trust")]
}

ducksemantics_prepare_judgments <- function(judgments) {
  judgments <- ducksemantics_check_data_frame(judgments, "judgments")
  ducksemantics_require_columns(judgments, c("judgment_id", "subject_id", "predicate", "decision"), "judgments")
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

ducksemantics_check_data_frame <- function(x, arg) {
  if (!is.data.frame(x)) {
    stop("`", arg, "` must be a data frame.", call. = FALSE)
  }
  x
}

ducksemantics_require_columns <- function(x, columns, arg) {
  missing <- setdiff(columns, names(x))
  if (length(missing)) {
    stop("`", arg, "` is missing required column(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(x)
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
  sub('^[^"]*"(([^"\\\\]|\\\\.)*)".*$', "\\1", line, perl = TRUE)
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
  mentions <- ducksemantics_check_data_frame(mentions, "mentions")
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
  check_scalar_character(response, "response")
  ducksemantics_require_jsonlite()
  json <- ducksemantics_extract_json(response)
  jsonlite::fromJSON(json, simplifyDataFrame = TRUE)
}

ducksemantics_normalize_judgment_payload <- function(parsed) {
  wrapper_names <- c("array", "judgments", "results", "items", "arguments", "args")
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
    return(as.data.frame(parsed, stringsAsFactors = FALSE))
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

ducksemantics_judgments_from_model <- function(parsed, mentions, model = "Rbebelm") {
  ducksemantics_require_jsonlite()
  if (is.list(parsed) && !is.data.frame(parsed)) {
    parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  }
  parsed <- ducksemantics_check_data_frame(parsed, "parsed")
  ducksemantics_require_columns(parsed, c("mention_id", "decision"), "parsed")
  allowed_decisions <- c("keep", "drop", "replace", "enrich")
  bad_decisions <- setdiff(unique(as.character(parsed$decision)), allowed_decisions)
  if (length(bad_decisions)) {
    stop(
      "Model returned unsupported decision value(s): ",
      paste(bad_decisions, collapse = ", "),
      call. = FALSE
    )
  }
  mention_map <- mentions[, intersect(c("mention_id", "node_id"), names(mentions)), drop = FALSE]
  parsed <- merge(parsed, mention_map, by = "mention_id", all.x = TRUE, sort = FALSE)
  confidence <- if ("confidence" %in% names(parsed)) as.numeric(parsed$confidence) else NA_real_
  object_id <- if ("replacement_node_id" %in% names(parsed)) {
    ifelse(!is.na(parsed$replacement_node_id) & nzchar(parsed$replacement_node_id), parsed$replacement_node_id, parsed$node_id)
  } else {
    parsed$node_id
  }
  keep_object <- parsed$decision %in% c("keep", "replace", "enrich")
  object_id[!keep_object] <- NA_character_
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

ducksemantics_metric_keys <- function(x, by = "node") {
  if (!nrow(x)) {
    return(character())
  }
  case_id <- as.character(x$case_id)
  node_id <- as.character(x$node_id)
  if (identical(by, "node")) {
    return(unique(paste(case_id, node_id, sep = "\r")))
  }
  has_offsets <- all(c("start_offset", "end_offset") %in% names(x)) &&
    any(!is.na(x$start_offset) & !is.na(x$end_offset))
  if (has_offsets) {
    return(unique(paste(case_id, node_id, as.integer(x$start_offset), as.integer(x$end_offset), sep = "\r")))
  }
  if ("span" %in% names(x) && any(!is.na(x$span))) {
    return(unique(paste(case_id, node_id, as.character(x$span), sep = "\r")))
  }
  stop("Span metrics require `start_offset`/`end_offset` or `span` columns.", call. = FALSE)
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
