
# ducksemantics

`ducksemantics` is a DuckDB-native semantic graph and grounding package
for R. The package owns the graph schema, OBO import, alias indexing,
mention grounding, provider interfaces, model judgment, and benchmark
measurement.

HPO and MONDO are first-class graph sources here, but they are not the
whole abstraction. The same tables can hold ORPHANET, study notes,
pi-bio-agent memory edges, run ledgers, and local concept maps.
BebeLM/Rbebelm is the bundled on-device provider for CPU embedding and
judgment; other providers implement the same S7 generics.

``` r
library(ducksemantics)
library(Rbebelm)

cache_dir <- tools::R_user_dir("ducksemantics", "cache")

ontology_files <- c(
  HPO = ducksemantics_cache_file(
    "https://purl.obolibrary.org/obo/hp.obo",
    "hp.obo",
    cache_dir = cache_dir
  ),
  MONDO = ducksemantics_cache_file(
    "https://purl.obolibrary.org/obo/mondo.obo",
    "mondo.obo",
    cache_dir = cache_dir
  )
)

weights_file <- Sys.getenv(
  "BEBELM_WEIGHTS_FILE",
  "/root/bebelm/LFM2.5-8B-A1B-Q4_K_M.gguf"
)
stopifnot(file.exists(weights_file))
```

The OBO parser produces the graph rows that DuckDB stores and indexes.

``` r
graphs <- list(
  HPO = ducksemantics_read_obo(ontology_files[["HPO"]], family = "HPO", source = "hp.obo"),
  MONDO = ducksemantics_read_obo(ontology_files[["MONDO"]], family = "MONDO", source = "mondo.obo")
)

data.frame(
  source = names(graphs),
  nodes = vapply(graphs, function(x) nrow(x$nodes), integer(1)),
  aliases = vapply(graphs, function(x) nrow(x$aliases), integer(1)),
  edges = vapply(graphs, function(x) nrow(x$edges), integer(1)),
  row.names = NULL
)
#>   source nodes aliases  edges
#> 1    HPO 19836   46065  24378
#> 2  MONDO 56273  149279 115738
```

The database below is rebuilt from those full ontologies, then indexed
once for lexical grounding.

``` r
db_path <- file.path(cache_dir, "readme.duckdb")
unlink(db_path)

conn <- ducksemantics_connect(db_path)
ducksemantics_write_graph(
  conn,
  nodes = graphs$HPO$nodes,
  aliases = graphs$HPO$aliases,
  edges = graphs$HPO$edges,
  replace = TRUE,
  index = FALSE
)
ducksemantics_write_graph(
  conn,
  nodes = graphs$MONDO$nodes,
  aliases = graphs$MONDO$aliases,
  edges = graphs$MONDO$edges,
  index = TRUE
)

ducksemantics_index_stats(conn)$tables
#>                     table row_count
#> 1          semantic_nodes     71333
#> 2        semantic_aliases    195344
#> 3    semantic_alias_index    195344
#> 4          semantic_edges    140110
#> 5 semantic_entailed_edges         0
#> 6       semantic_mentions         0
#> 7      semantic_judgments         0
```

Grounding returns deterministic candidates with source provenance. The
diabetes mention is deliberately negated; the lexical layer should
surface it, and the judgment layer should decide whether it belongs in
the patient phenotype.

``` r
note <- paste(
  "The proband presents with global developmental delay, seizures,",
  "short stature, cardiomyopathy, and no diabetes mellitus."
)

mentions <- ducksemantics_annotate(conn, note, document_id = "readme-case-001")
unique(mentions[, c("span", "node_id", "alias_kind", "source")])
#>                          span       node_id    alias_kind    source
#> 1  global developmental delay    HP:0001263         label    hp.obo
#> 2                    seizures    HP:0001250 synonym:exact    hp.obo
#> 3               short stature    HP:0004322         label    hp.obo
#> 4               short stature    HP:0004322 synonym:exact    hp.obo
#> 5               short stature    HP:0004322         label mondo.obo
#> 6              cardiomyopathy    HP:0001638         label    hp.obo
#> 7              cardiomyopathy    HP:0001638         label mondo.obo
#> 8              cardiomyopathy MONDO:0004994         label mondo.obo
#> 9              cardiomyopathy MONDO:0004994 synonym:exact mondo.obo
#> 10          diabetes mellitus    HP:0000819         label    hp.obo
#> 11          diabetes mellitus    HP:0000819         label mondo.obo
#> 12          diabetes mellitus MONDO:0005015         label mondo.obo
#> 13          diabetes mellitus MONDO:0005015 synonym:exact mondo.obo
```

The BebeLM bridge is typed as an embedding provider. The vectors below
come from the local GGUF model and are cached as RDS because they are
deterministic for the same model and pooling configuration.

``` r
model <- bebel_model_load(weights_file, num_threads = 2)
embedding_provider <- ducksemantics_bebel_embedding_provider(model, pooling = "mean")

embedding_terms <- c(
  "global developmental delay",
  "seizures",
  "short stature",
  "cardiomyopathy",
  "diabetes mellitus"
)

embeddings <- ducksemantics_cache_rds(
  file.path(cache_dir, "readme-bebel-embeddings.rds"),
  function() ducksemantics_embed(embedding_provider, embedding_terms)
)

data.frame(
  terms = nrow(embeddings),
  dimensions = ncol(embeddings),
  first_row_l2 = round(sqrt(sum(embeddings[1, ] ^ 2)), 4)
)
#>   terms dimensions first_row_l2
#> 1     5       2048            1
```

BebeLM judgment uses the same provider interface. The parser here accepts
BebeLM tool calls and JSON judgment payloads, then returns the rows
expected by the semantic store.

``` r
judgment_mentions <- data.frame(
  mention_id = "readme-judgment:000001",
  node_id = "HP:0004322",
  span = "short stature",
  start_offset = 26L,
  end_offset = 39L,
  score = 1,
  alias = "short stature",
  alias_kind = "label",
  source = "hp.obo",
  stringsAsFactors = FALSE
)

judgment_instructions <- c(
  "You adjudicate deterministic semantic grounding candidates.",
  "Return only JSON: an array of objects with mention_id, decision, confidence, evidence_span, short_reason.",
  "Use keep for a supported patient finding. Never invent identifiers."
)

judgment <- ducksemantics_cache_rds(
  file.path(cache_dir, "readme-bebel-judgment.rds"),
  function() {
    agent <- bebel_agent(model, greedy = TRUE, max_gen = 96, max_think = 0)
    ducksemantics_bebel_judge(
      agent,
      "The proband presents with short stature.",
      judgment_mentions,
      instructions = judgment_instructions,
      parser = ducksemantics_bebel_tool_judgment_parser(),
      record = FALSE
    )
  }
)

judgment[, c("subject_id", "object_id", "decision", "confidence", "model")]
#>               subject_id  object_id decision confidence   model
#> 1 readme-judgment:000001 HP:0004322     keep          1 Rbebelm
```

Benchmarks are ordinary R data flowing through pipes. The metrics below
use gold HPO phenotypes and expose the current lexical baseline before
model judgment removes negated or disease-level mentions.

``` r
suite <- ducksemantics_benchmark_cases(
  cases = data.frame(
    case_id = "readme-case-001",
    text = note,
    stringsAsFactors = FALSE
  ),
  gold = data.frame(
    case_id = "readme-case-001",
    node_id = c("HP:0001263", "HP:0001250", "HP:0004322", "HP:0001638"),
    stringsAsFactors = FALSE
  ),
  suite = "readme-hpo-mondo"
)

run <- suite |>
  ducksemantics_benchmark(conn)

run$metrics
#>     by tp fp fn precision recall        f1
#> 1 node  4  3  0 0.5714286      1 0.7272727
run$timings[, c("case_id", "seconds", "token_count", "prediction_count", "prediction_bytes")]
#>           case_id seconds token_count prediction_count prediction_bytes
#> 1 readme-case-001   0.086          15               13             6152
```

``` r
DBI::dbDisconnect(conn, shutdown = TRUE)
```
