schema <- ducksemantics_schema_sql()
expect_true(any(grepl("semantic_nodes", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_aliases", schema, fixed = TRUE)))
expect_true(any(grepl("semantic_judgments", schema, fixed = TRUE)))

tables <- ducksemantics_tables()
expect_equal(tables[["nodes"]], "semantic_nodes")
expect_equal(tables[["entailed_edges"]], "semantic_entailed_edges")

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
      node_id = c("HP:0004322", "HP:0001250"),
      family = "HPO",
      label = c("Short stature", "Seizure"),
      stringsAsFactors = FALSE
    ),
    replace = TRUE,
    aliases = data.frame(
      node_id = c("HP:0004322", "HP:0004322", "HP:0001250"),
      alias = c("short stature", "short height", "seizures"),
      alias_kind = c("label", "exact_synonym", "exact_synonym"),
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
