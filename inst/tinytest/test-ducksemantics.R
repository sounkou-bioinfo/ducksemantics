schema <- ducksemantics_schema_sql()
expect_true(any(grepl("semantic_nodes", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_aliases", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_judgments", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_embeddings", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_token_embeddings", schema, fixed = TRUE)))
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
expect_equal(
  projection,
  paste0(
    'CREATE OR REPLACE TABLE "semantic_edges" AS SELECT ',
    '"subject" AS from_id, "predicate" AS predicate, "object" AS to_id, ',
    '"attrs" AS attrs, NULL AS trust FROM "source_edges"'
  )
)

closure <- ducksemantics_closure_sql(c("rdfs:subClassOf", "BFO:0000050"))
expect_true(grepl("WITH RECURSIVE closure", closure, fixed = TRUE))
expect_true(grepl("'rdfs:subClassOf'", closure, fixed = TRUE))
expect_true(grepl("'BFO:0000050'", closure, fixed = TRUE))

empty_closure <- ducksemantics_closure_sql(character())
expect_equal(
  empty_closure,
  'CREATE OR REPLACE TABLE "semantic_entailed_edges" (from_id TEXT, predicate TEXT, to_id TEXT)'
)

expect_error(ducksemantics_tables("bad-prefix"))
expect_error(ducksemantics_projection_sql("source_edges", "bad-column", "predicate", "object"))

expect_true(s7contract::implements(ducksemantics_prompt_runner(function(prompt) "[]"), DucksemanticsPromptRunner))
expect_true(s7contract::implements(ducksemantics_json_judgment_parser(), DucksemanticsJudgmentParser))
expect_true(s7contract::implements(ducksemantics_lexical_annotator(), DucksemanticsAnnotator))

embedding_provider <- ducksemantics_embedding_provider(function(text) {
  matrix(seq_along(text), nrow = length(text), ncol = 1L)
})
expect_true(s7contract::implements(embedding_provider, DucksemanticsEmbeddingProvider))
expect_equal(dim(ducksemantics_embed(embedding_provider, c("alpha", "beta"))), c(2L, 1L))

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
expect_equal(as.vector(chunked_embeddings), c(1, 2, 3, 4, 5))
expect_equal(chunked_embeddings, chunked_again)
expect_equal(chunk_calls, 3L)
expect_true(file.exists(file.path(chunk_cache_dir, "manifest.rds")))

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
}

obo_path <- tempfile(fileext = ".obo")
writeLines(
  c(
    "format-version: 1.2",
    "",
    "[Term]",
    "id: HP:0000001",
    "name: All",
    "def: \"Root term\" []",
    "synonym: \"whole phenotype\" EXACT []",
    "is_a: HP:0000118 ! Phenotypic abnormality",
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
expect_equal(sort(obo_graph$aliases$alias), c("All", "whole phenotype"))
expect_equal(sort(obo_graph$edges$predicate), c("is_a", "part_of"))

if (requireNamespace("duckdb", quietly = TRUE) && requireNamespace("jsonlite", quietly = TRUE)) {
  conn <- ducksemantics_connect()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
  ducksemantics_init(conn)
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
      node_id = c("HP:0004322", "HP:0004322", "HP:0001250"),
      alias = c("short stature", "short height", "seizures"),
      alias_kind = c("label", "exact_synonym", "exact_synonym"),
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
  expect_true(all(hits$method == "lexical_alias"))

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
    suite = "tiny-hpo"
  )
  run <- benchmark |> ducksemantics_benchmark(conn)
  expect_equal(run$metrics$tp, 2)
  expect_equal(run$metrics$fp, 0)
  expect_equal(run$metrics$fn, 0)
  expect_equal(run$metrics$f1, 1)

  stats <- ducksemantics_index_stats(conn)
  expect_true(any(stats$tables$table == "semantic_alias_index"))
}
