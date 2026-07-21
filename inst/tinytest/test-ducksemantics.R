schema <- ducksemantics_schema_sql()
expect_true(any(grepl("semantic_nodes", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_aliases", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_judgments", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_embeddings", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_token_embeddings", schema, fixed = TRUE)))
expect_false(any(grepl("storage_ref", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_embedding_clusters", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_embedding_centroids", schema, fixed = TRUE)))

tables <- ducksemantics_tables()
expect_equal(tables[["nodes"]], "semantic_nodes")
expect_equal(tables[["entailed_edges"]], "semantic_entailed_edges")
expect_equal(tables[["embeddings"]], "semantic_embeddings")
expect_equal(tables[["token_embeddings"]], "semantic_token_embeddings")
expect_equal(tables[["embedding_clusters"]], "semantic_embedding_clusters")

projection <- ducksemantics_projection_sql(
  source_table = "source_edges",
  from = "subject",
  predicate = "predicate",
  to = "object",
  attrs = "attrs"
)
expect_true(grepl(
  paste0(
    'CREATE OR REPLACE TABLE "semantic_edges" AS SELECT ',
    '"subject" AS from_id, "predicate" AS predicate, "object" AS to_id, ',
    '"attrs" AS attrs, NULL AS trust FROM "source_edges"'
  ),
  projection,
  fixed = TRUE
))
expect_true(grepl('CREATE INDEX IF NOT EXISTS "semantic_edges_subj_idx"', projection, fixed = TRUE))
expect_true(grepl('CREATE INDEX IF NOT EXISTS "semantic_edges_obj_idx"', projection, fixed = TRUE))

closure <- ducksemantics_closure_sql(c("rdfs:subClassOf", "BFO:0000050"))
expect_true(grepl("WITH RECURSIVE closure", closure, fixed = TRUE))
expect_true(grepl("'rdfs:subClassOf'", closure, fixed = TRUE))
expect_true(grepl("'BFO:0000050'", closure, fixed = TRUE))

empty_closure <- ducksemantics_closure_sql(character())
expect_true(grepl(
  'CREATE OR REPLACE TABLE "semantic_entailed_edges" (from_id TEXT, predicate TEXT, to_id TEXT)',
  empty_closure,
  fixed = TRUE
))
expect_true(grepl('CREATE INDEX IF NOT EXISTS "semantic_entailed_edges_subj_idx"', empty_closure, fixed = TRUE))
expect_true(grepl('CREATE INDEX IF NOT EXISTS "semantic_entailed_edges_obj_idx"', empty_closure, fixed = TRUE))

expect_error(ducksemantics_tables("bad-prefix"))
expect_error(ducksemantics_projection_sql("source_edges", "bad-column", "predicate", "object"))

expect_true(s7contract::implements(ducksemantics_prompt_runner(function(prompt) "[]"), DucksemanticsPromptRunner))
expect_true(s7contract::implements(ducksemantics_json_judgment_parser(), DucksemanticsJudgmentParser))
expect_true(s7contract::implements(ducksemantics_lexical_annotator(), DucksemanticsAnnotator))

mixed_span_predictions <- data.frame(
  case_id = c("a", "a"),
  node_id = c("n1", "n2"),
  span = c("alpha", "beta"),
  start_offset = c(0L, NA_integer_),
  end_offset = c(5L, NA_integer_)
)
mixed_span_gold <- data.frame(
  case_id = c("a", "a"),
  node_id = c("n1", "n2"),
  span = c("alpha", "beta")
)
mixed_span_metrics <- ducksemantics_benchmark_metrics(
  mixed_span_predictions,
  mixed_span_gold,
  by = "span"
)
expect_equal(mixed_span_metrics$tp, 2)
expect_equal(mixed_span_metrics$f1, 1)

embedding_provider <- ducksemantics_embedding_provider(function(text) {
  matrix(seq_along(text), nrow = length(text), ncol = 1L)
})
expect_true(s7contract::implements(embedding_provider, DucksemanticsEmbeddingProvider))
expect_equal(dim(ducksemantics_embed(embedding_provider, c("alpha", "beta"))), c(2L, 1L))

token_provider <- ducksemantics_token_embedding_provider(function(text) {
  lapply(seq_along(text), function(i) {
    tokens <- strsplit(text[[i]], " ", fixed = TRUE)[[1L]]
    list(
      embeddings = cbind(seq_along(tokens), rev(seq_along(tokens))),
      token_index = seq_along(tokens) - 1L,
      tokens = tokens,
      start_offset = seq_along(tokens) - 1L,
      end_offset = seq_along(tokens)
    )
  })
}, label = "tiny-token-provider")
expect_true(s7contract::implements(token_provider, DucksemanticsTokenEmbeddingProvider))
token_provider_batch <- ducksemantics_token_embedding_batch_from_provider(
  c("short stature", "seizure"),
  provider = token_provider,
  subject_id = c("HP:0004322", "HP:0001250"),
  subject_kind = "node"
)
expect_true(S7::S7_inherits(token_provider_batch, DucksemanticsTokenEmbeddingBatch))
expect_equal(nrow(S7::prop(token_provider_batch, "embeddings")), 3L)
expect_equal(S7::prop(token_provider_batch, "start_offset"), c(0, 1, 0))
expect_equal(S7::prop(token_provider_batch, "end_offset"), c(1, 2, 1))
expect_error(
  ducksemantics_token_embedding_batch(
    matrix(c(1, 0, 0, 1), ncol = 2L, byrow = TRUE),
    subject_id = c("a", "a"),
    token_index = c(0, 0)
  ),
  "must be unique"
)

chunk_cache_dir <- tempfile()
chunk_calls <- 0L
chunk_provider <- ducksemantics_embedding_provider(function(text) {
  chunk_calls <<- chunk_calls + 1L
  matrix(nchar(text), nrow = length(text), ncol = 1L)
})
chunked_embeddings <- ducksemantics_embed_cached(
  c("a", "bb", "ccc", "dddd", "eeeee"),
  provider = chunk_provider,
  cache_dir = chunk_cache_dir,
  chunk_size = 2L
)
chunked_again <- ducksemantics_embed_cached(
  c("a", "bb", "ccc", "dddd", "eeeee"),
  provider = chunk_provider,
  cache_dir = chunk_cache_dir,
  chunk_size = 2L
)
chunked_changed <- ducksemantics_embed_cached(
  c("z", "yy", "xxx", "wwww", "vvvvv"),
  provider = chunk_provider,
  cache_dir = chunk_cache_dir,
  chunk_size = 2L
)
sentinel <- file.path(chunk_cache_dir, "keep-me.txt")
writeLines("unmanaged", sentinel)
chunked_refreshed <- ducksemantics_embed_cached(
  c("z", "yy", "xxx", "wwww", "vvvvv"),
  provider = chunk_provider,
  cache_dir = chunk_cache_dir,
  chunk_size = 2L,
  refresh = TRUE
)
expect_equal(as.vector(chunked_embeddings), c(1, 2, 3, 4, 5))
expect_equal(chunked_embeddings, chunked_again)
expect_equal(as.vector(chunked_changed), c(1, 2, 3, 4, 5))
expect_equal(chunked_changed, chunked_refreshed)
expect_equal(chunk_calls, 9L)
expect_true(file.exists(file.path(chunk_cache_dir, "manifest.rds")))
expect_true(file.exists(sentinel))

expect_error(
  ducksemantics_cache_file("https://example.org/value", filename = "../outside"),
  "without directory components"
)
expect_error(ducksemantics_embedding_query(c(0, 0), metric = "cosine"), "must be non-zero")
expect_error(ducksemantics_embedding_index_spec(2L, metric = "unknown"), "must be one of")

cache_path <- tempfile(fileext = ".rds")
cache_calls <- 0L
cached_value <- ducksemantics_cache_rds(cache_path, function() {
  cache_calls <<- cache_calls + 1L
  data.frame(x = 1L, stringsAsFactors = FALSE)
})
cached_again <- ducksemantics_cache_rds(cache_path, function() {
  cache_calls <<- cache_calls + 1L
  data.frame(x = 2L, stringsAsFactors = FALSE)
})
expect_equal(cache_calls, 1L)
expect_equal(cached_value, cached_again)

if (requireNamespace("Rbebelm", quietly = TRUE)) {
  parsed_tool_call <- ducksemantics_parse(
    ducksemantics_bebel_tool_judgment_parser(),
    paste0(
      "<|tool_call_start|>",
      "[adjudicate_grounding(mention_id=\"m1\", decision=\"keep\", confidence=1, evidence_span=\"short stature\")]",
      "<|tool_call_end|>"
    )
  )
  expect_equal(parsed_tool_call$mention_id, "m1")
  expect_equal(parsed_tool_call$decision, "keep")
  expect_equal(parsed_tool_call$confidence, "1")

  parsed_json_call <- ducksemantics_parse(
    ducksemantics_bebel_tool_judgment_parser(),
    paste0(
      "{\"array\":[{\"mention_id\":\"m2\",",
      "\"decision\":\"drop\",",
      "\"confidence\":0.8}]}"
    )
  )
  expect_equal(parsed_json_call$mention_id, "m2")
  expect_equal(parsed_json_call$decision, "drop")

  expect_error(
    ducksemantics_parse(
      ducksemantics_json_judgment_parser(),
      paste0(
        "{\"m3\":{\"mention_id\":\"m3\",\"decision\":\"keep\"},",
        "\"m4\":{\"mention_id\":\"m4\",\"decision\":\"drop\"}}"
      )
    )
  )
}

obo_path <- tempfile(fileext = ".obo")
writeLines(
  c(
    "format-version: 1.2",
    "",
    "[Term]",
    "id: HP:0000001",
    "name: All",
    "def: \"Root \\\"term\\\"\" []",
    "alt_id: HP:OLD0001",
    "synonym: \"whole phenotype\" EXACT []",
    "is_a: HP:0000118 {xref=\"PMID:1\"} ! Phenotypic abnormality",
    "relationship: part_of HP:0000707 ! Nervous system",
    "",
    "[Term]",
    "id: HP:9999999",
    "name: Obsolete term",
    "is_obsolete: true"
  ),
  obo_path
)
obo_graph <- ducksemantics_read_obo(obo_path, family = "HPO", source = "tiny.obo")
expect_equal(obo_graph$nodes$node_id, "HP:0000001")
expect_equal(obo_graph$nodes$description, 'Root "term"')
expect_equal(sort(obo_graph$aliases$alias), c("All", "HP:OLD0001", "whole phenotype"))
expect_equal(sort(obo_graph$edges$predicate), c("is_a", "part_of"))
expect_equal(obo_graph$edges$to_id[obo_graph$edges$predicate == "is_a"], "HP:0000118")

if (requireNamespace("duckdb", quietly = TRUE) && requireNamespace("jsonlite", quietly = TRUE)) {
  conn <- ducksemantics_connect()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
  ducksemantics_init(conn)
  DBI::dbExecute(conn, empty_closure)
  closure_indexes <- DBI::dbGetQuery(
    conn,
    "SELECT index_name FROM duckdb_indexes() WHERE table_name = 'semantic_entailed_edges'"
  )
  expect_equal(nrow(closure_indexes), 2L)
  ducksemantics_write_obo(conn, obo_path, family = "HPO", source = "tiny.obo", replace = TRUE)
  tiny_hits <- ducksemantics_annotate(conn, "whole phenotype", document_id = "tiny-obo")
  expect_equal(tiny_hits$node_id, "HP:0000001")

  ducksemantics_write_graph(
    conn,
    nodes = data.frame(
      node_id = c("HP:0004322", "HP:0001250", "HP:0000001"),
      family = "HPO",
      label = c("Short stature", "Seizure", "Phenotypic abnormality"),
      stringsAsFactors = FALSE
    ),
    replace = TRUE,
    aliases = data.frame(
      node_id = c("HP:0004322", "HP:0004322", "HP:0004322", "HP:0001250"),
      alias = c("short stature", "short stature", "short height", "seizures"),
      alias_kind = c("label", "exact_synonym", "exact_synonym", "exact_synonym"),
      stringsAsFactors = FALSE
    ),
    edges = data.frame(
      from_id = c("HP:0004322", "HP:0001250"),
      predicate = "is_a",
      to_id = "HP:0000001",
      stringsAsFactors = FALSE
    )
  )

  hits <- ducksemantics_annotate(
    conn,
    "The patient has short stature and seizures.",
    document_id = "case-001"
  )
  expect_equal(sort(hits$node_id), c("HP:0001250", "HP:0004322"))
  expect_equal(nrow(hits), 2L)
  expect_true(all(hits$method == "lexical_alias"))

  graph_counts_before <- DBI::dbGetQuery(
    conn,
    "SELECT (SELECT COUNT(*) FROM semantic_aliases) AS aliases, (SELECT COUNT(*) FROM semantic_edges) AS edges"
  )
  ducksemantics_write_graph(
    conn,
    aliases = data.frame(node_id = "HP:0004322", alias = "short stature", alias_kind = "label"),
    edges = data.frame(from_id = "HP:0004322", predicate = "is_a", to_id = "HP:0000001")
  )
  graph_counts_after <- DBI::dbGetQuery(
    conn,
    "SELECT (SELECT COUNT(*) FROM semantic_aliases) AS aliases, (SELECT COUNT(*) FROM semantic_edges) AS edges"
  )
  expect_equal(graph_counts_after, graph_counts_before)

  vector_batch <- ducksemantics_embedding_batch(
    embeddings = matrix(
      c(
        1.0, 0.0, 0.0,
        0.9, 0.1, 0.0,
        0.0, 1.0, 0.0,
        0.45, 0.55, 0.0
      ),
      ncol = 3L,
      byrow = TRUE
    ),
    subject_id = c("HP:0004322", "HP:0004322_synonym", "HP:0001250", "HP:0000001"),
    subject_kind = "node",
    provider = "tiny",
    text = c("short stature", "short height", "seizure", "phenotypic abnormality")
  )
  vector_rows <- vector_batch |>
    ducksemantics_write_embeddings(conn, replace = TRUE)
  expect_equal(nrow(vector_rows), 4L)

  token_batch <- ducksemantics_token_embedding_batch(
    embeddings = matrix(
      c(
        1.0, 0.0,
        0.8, 0.2,
        0.0, 1.0
      ),
      ncol = 2L,
      byrow = TRUE
    ),
    subject_id = c("HP:0004322", "HP:0004322", "HP:0001250"),
    subject_kind = "node",
    provider = "tiny-token",
    token = c("short", "stature", "seizure")
  )
  token_rows <- token_batch |>
    ducksemantics_write_token_embeddings(conn, replace = TRUE)
  expect_equal(nrow(token_rows), 3L)
  expect_equal(token_rows$token_index, c(0L, 1L, 0L))

  late_hits <- ducksemantics_token_embedding_query(
    matrix(
      c(
        1.0, 0.0,
        0.0, 1.0
      ),
      ncol = 2L,
      byrow = TRUE
    ),
    provider = "tiny-token",
    subject_kind = "node",
    top_k = 2L
  ) |>
    ducksemantics_late_interaction_search(conn)
  expect_true(inherits(late_hits, "ducksemantics_late_interaction_result"))
  expect_equal(late_hits$subject_id[[1L]], "HP:0004322")
  expect_error(
    ducksemantics_late_interaction_search(
      ducksemantics_token_embedding_query(matrix(c(0, 0), ncol = 2L)),
      conn
    ),
    "non-zero norm"
  )
  expect_equal(nrow(late_hits), 2L)
  expect_true(late_hits$score[[1L]] > late_hits$score[[2L]])

  candidate_hit <- ducksemantics_token_embedding_query(
    matrix(c(0.0, 1.0), ncol = 2L),
    provider = "tiny-token",
    subject_kind = "node",
    candidate_subject_id = "HP:0001250",
    top_k = 5L
  ) |>
    ducksemantics_late_interaction_search(conn)
  expect_equal(candidate_hit$subject_id, "HP:0001250")

  collision_batch <- ducksemantics_token_embedding_batch(
    embeddings = matrix(c(1, 0, 0, 1), ncol = 2L, byrow = TRUE),
    subject_id = c("collision-a", "collision-b"),
    subject_kind = "node",
    provider = "collision-provider",
    block_id = c("same-block", "same-block")
  )
  ducksemantics_write_token_embeddings(collision_batch, conn, replace = TRUE)
  collision_hits <- ducksemantics_token_embedding_query(
    matrix(c(1, 0), ncol = 2L),
    provider = "collision-provider",
    top_k = 5L
  ) |>
    ducksemantics_late_interaction_search(conn)
  expect_equal(nrow(collision_hits), 2L)
  expect_equal(sort(collision_hits$subject_id), c("collision-a", "collision-b"))

  vector_hits <- ducksemantics_embedding_query(
    c(1, 0, 0),
    provider = "tiny",
    subject_kind = "node",
    top_k = 2
  ) |>
    ducksemantics_embedding_search(conn)
  expect_equal(vector_hits$subject_id[[1L]], "HP:0004322")
  expect_equal(nrow(vector_hits), 2L)

  materialized <- ducksemantics_embedding_index_spec(
    dimensions = 3,
    provider = "tiny",
    subject_kind = "node",
    hnsw = FALSE
  ) |>
    ducksemantics_materialize_embedding_index(conn)
  indexed_hits <- ducksemantics_embedding_query(
    c(0, 1, 0),
    table = materialized,
    provider = "tiny",
    subject_kind = "node",
    top_k = 1
  ) |>
    ducksemantics_embedding_search(conn)
  expect_equal(indexed_hits$subject_id[[1L]], "HP:0001250")

  clusters <- ducksemantics_embedding_cluster_spec(
    k = 2L,
    provider = "tiny",
    subject_kind = "node",
    dimensions = 3L,
    run_id = "tiny-embedding-clusters",
    nstart = 2L
  ) |>
    ducksemantics_cluster_embeddings(conn)
  expect_equal(nrow(clusters$assignments), 4L)
  expect_equal(nrow(clusters$centroids), 2L)
  expect_equal(sum(clusters$summary$size), 4L)

  stored_clusters <- ducksemantics_embedding_cluster_summary(conn, "tiny-embedding-clusters")
  expect_equal(sum(stored_clusters$size), 4)

  graph_agreement <- ducksemantics_embedding_cluster_graph_agreement(
    conn,
    "tiny-embedding-clusters",
    predicates = "is_a"
  )
  expect_equal(graph_agreement$edge_count, 2)

  runner <- ducksemantics_prompt_runner(function(prompt) {
    jsonlite::toJSON(
      data.frame(
        mention_id = hits$mention_id,
        decision = "keep",
        confidence = 1,
        stringsAsFactors = FALSE
      ),
      dataframe = "rows",
      auto_unbox = TRUE
    )
  })
  judgments <- ducksemantics_judge(
    "The patient has short stature and seizures.",
    hits,
    runner = runner,
    instructions = "Return keep/drop JSON for each supplied mention."
  )
  expect_equal(nrow(judgments), nrow(hits))
  expect_true(all(judgments$decision == "keep"))

  missing_runner <- ducksemantics_prompt_runner(function(prompt) {
    '[{"mention_id":"case-001:000017","decision":"keep"}]'
  })
  expect_error(
    ducksemantics_judge("text", hits, runner = missing_runner),
    "exactly one result per candidate"
  )
  replacement_runner <- ducksemantics_prompt_runner(function(prompt) {
    jsonlite::toJSON(
      data.frame(
        mention_id = hits$mention_id,
        decision = c("replace", "keep"),
        replacement_node_id = c("HP:NOT_SUPPLIED", NA_character_),
        stringsAsFactors = FALSE
      ),
      dataframe = "rows",
      auto_unbox = TRUE,
      na = "null"
    )
  })
  expect_error(
    ducksemantics_judge("text", hits, runner = replacement_runner),
    "outside supplied candidates"
  )
  empty_judgments <- ducksemantics_judge(
    "text",
    hits[FALSE, , drop = FALSE],
    runner = ducksemantics_prompt_runner(function(prompt) "[]")
  )
  expect_equal(nrow(empty_judgments), 0L)

  expect_error(
    ducksemantics_benchmark_cases(
      cases = data.frame(case_id = character(), text = character()),
      gold = data.frame(case_id = character(), node_id = character())
    )
  )
  expect_error(
    ducksemantics_benchmark_cases(
      cases = data.frame(case_id = c("duplicate", "duplicate"), text = c("a", "b")),
      gold = data.frame(case_id = character(), node_id = character())
    ),
    "uniquely identify"
  )
  benchmark <- ducksemantics_benchmark_cases(
    cases = data.frame(
      case_id = "case-001",
      text = "The patient has short stature and seizures.",
      stringsAsFactors = FALSE
    ),
    gold = data.frame(
      case_id = "case-001",
      node_id = c("HP:0004322", "HP:0001250"),
      stringsAsFactors = FALSE
    ),
    suite = "tiny-hpo",
    source = "tinytest",
    version = "1"
  )
  result <- benchmark |> ducksemantics_benchmark(conn)
  expect_equal(result$metrics$tp, 2)
  expect_equal(result$metrics$fp, 0)
  expect_equal(result$metrics$fn, 0)
  expect_equal(result$metrics$f1, 1)
  expect_equal(result$summary$case_count, 1L)
  expect_equal(result$summary$gold_count, 2L)
  expect_equal(result$case_metrics$case_id, "case-001")
  expect_equal(result$source, "tinytest")
  expect_true(is.list(result$environment$packages))
  expect_true(result$environment$os_type %in% c("unix", "windows"))
  expect_true(nzchar(result$environment$sysname))

  stats <- ducksemantics_index_stats(conn)
  expect_true(any(stats$tables$table == "semantic_alias_index"))

  ducksemantics_write_graph(
    conn,
    nodes = data.frame(node_id = "HP:AMBIGUOUS", family = "HPO", label = "Other seizures"),
    aliases = data.frame(node_id = "HP:AMBIGUOUS", alias = "seizures", alias_kind = "label"),
    index = TRUE
  )
  ambiguous_hits <- ducksemantics_annotate(conn, "seizures", document_id = "ambiguous")
  expect_equal(nrow(ambiguous_hits), 2L)
  expect_equal(anyDuplicated(ambiguous_hits$mention_id), 0L)
  expect_true(all(grepl("HP:", ambiguous_hits$mention_id, fixed = TRUE)))
}
