
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# ducksemantics

`ducksemantics` is a DuckDB-native semantic graph and evidence-grounding
package for R. It stores ontology nodes, aliases, graph edges, dense
vectors, and ColBERT document token vectors in one auditable DuckDB
database.

It combines the Rbebelm retrieval and judgment APIs in one graph
workflow. EmbeddingGemma supplies task-prompted dense vectors for broad
retrieval and DuckDB HNSW candidate generation, LFM2.5-ColBERT supplies
exact late-interaction MaxSim reranking of stored candidate documents,
and BebeLM records structured judgments with negation, uncertainty,
family history, and subject context. HPO, MONDO, ORPHANET, and local
knowledge graphs load through the same graph schema.

## Build a semantic graph

The bundled HPO fixture is a small, attribution-preserving subset of the
real Human Phenotype Ontology. It keeps the README executable without
downloading an ontology during rendering.

``` r
library(ducksemantics)

conn <- ducksemantics_connect()
hpo <- ducksemantics_read_obo(
  system.file("extdata", "hpo-readme.obo", package = "ducksemantics", mustWork = TRUE),
  family = "HPO",
  source = "HPO README fixture"
)
ducksemantics_write_graph(
  conn,
  nodes = hpo$nodes,
  aliases = hpo$aliases,
  edges = hpo$edges,
  replace = TRUE
)

# Deterministic, explainable candidates. This intentionally includes negated
# mentions; BebeLM judgment decides whether the mention is a patient finding.
case_text <- "The proband has short stature and seizures but no diabetes mellitus."
mentions <- ducksemantics_annotate(
  conn,
  case_text,
  document_id = "case-001"
)
mentions
#>   document_id      mention_id    node_id          span start_offset end_offset
#> 1    case-001 case-001:000017 HP:0004322 short stature           16         29
#> 2    case-001 case-001:000031 HP:0001250      seizures           34         42
#>   score        method attrs trust         alias    alias_kind
#> 1  1.00 lexical_alias  <NA>  <NA> Short stature         label
#> 2  0.95 lexical_alias  <NA>  <NA>      Seizures synonym:exact
#>               source
#> 1 HPO README fixture
#> 2 HPO README fixture
```

## Dense retrieval with EmbeddingGemma

EmbeddingGemma provides the broad candidate stage. Choose its task
deliberately: vectors sharing a compatible prompt contract can be
compared directly. This example loads the local GGUF selected by
`EMBEDDING_GEMMA_WEIGHTS_FILE` and executes the native encoder.

``` r
library(Rbebelm)

embedding_model <- embeddinggemma_model_load(
  embeddinggemma_weights,
  num_threads = 2
)
dense_provider <- ducksemantics_embeddinggemma_provider(
  embedding_model,
  label = "embeddinggemma-hpo-v1",
  task = "semantic_similarity",
  dimensions = 256L
)

terms <- DBI::dbGetQuery(conn, "SELECT node_id, label FROM semantic_nodes WHERE family = 'HPO'")
vectors <- ducksemantics_embed_cached(
  terms$label,
  provider = dense_provider,
  cache_dir = file.path(tempdir(), "ducksemantics-embeddinggemma-hpo-cache")
)
ducksemantics_embedding_batch(
  vectors,
  subject_id = terms$node_id,
  subject_kind = "hpo_term",
  provider = "embeddinggemma-hpo-v1",
  text = terms$label
) |> ducksemantics_write_embeddings(conn, replace = TRUE)

# Exact DuckDB vector search is sufficient for this small example. An HNSW
# index is optional for a larger dense candidate collection.
dense_hits <- ducksemantics_embedding_query(
  ducksemantics_embed(dense_provider, "short height")[1L, ],
  provider = "embeddinggemma-hpo-v1",
  subject_kind = "hpo_term",
  top_k = 3L
) |> ducksemantics_embedding_search(conn)
dense_hits
#>   subject_id subject_kind              provider                   text dim
#> 1 HP:0004322     hpo_term embeddinggemma-hpo-v1          Short stature 256
#> 2 HP:0001252     hpo_term embeddinggemma-hpo-v1              Hypotonia 256
#> 3 HP:0000118     hpo_term embeddinggemma-hpo-v1 Phenotypic abnormality 256
#>       score
#> 1 0.9806611
#> 2 0.6952595
#> 3 0.6600621
```

## Exact late interaction with native ColBERT

ColBERT document vectors are persisted once, and each query is encoded
with the model’s query contract. DuckDB then computes the exact MaxSim
sum over stored document vectors. Large corpora can send dense HNSW,
lexical, or graph candidates to this stage through
`candidate_subject_id`. This example loads the local GGUF selected by
`COLBERT_WEIGHTS_FILE` and uses Rbebelm’s native LFM2.5-ColBERT encoder.

``` r
colbert_model <- colbert_model_load(colbert_weights, num_threads = 2)
colbert_documents <- ducksemantics_colbert_provider(
  colbert_model,
  role = "document",
  label = "lfm2.5-colbert-350m-q4km"
)

ducksemantics_token_embedding_batch_from_provider(
  terms$label,
  provider = colbert_documents,
  subject_id = terms$node_id,
  subject_kind = "hpo_term"
) |> ducksemantics_write_token_embeddings(conn, replace = TRUE)

hits <- ducksemantics_colbert_query(
  colbert_model,
  "developmental delay with seizures",
  provider = "lfm2.5-colbert-350m-q4km",
  subject_kind = "hpo_term",
  top_k = 25L
) |> ducksemantics_late_interaction_search(conn)
hits
#> <ducksemantics late-interaction result>
#>   blocks: 4
#>   top score: 29.7243
```

The token table holds 128-dimensional LFM2.5-ColBERT document vectors
for variable-length MaxSim scoring. `duckdb-vss` can accelerate the
fixed-width EmbeddingGemma candidate stage while DuckDB evaluates the
token-level reranker.

## BebeLM candidate judgment

BebeLM reviews candidates together with the retrieved context and
records a structured decision for negated, uncertain, historical, and
subject-specific mentions. Replacement concepts come from the supplied
candidates and graph neighbors, preserving a direct evidence trail. This
example loads the local GGUF selected by `BEBELM_WEIGHTS_FILE` and
executes a BebeLM judgment.

``` r
generation_model <- bebel_model_load(bebel_weights, num_threads = 2)
agent <- bebel_agent(generation_model, greedy = TRUE, max_gen = 256L, max_think = 0L)

judgments <- ducksemantics_bebel_judge(
  agent,
  text = case_text,
  mentions = mentions,
  conn = conn,
  parser = ducksemantics_bebel_tool_judgment_parser(),
  model = "LFM2.5-8B-A1B"
)
judgments
#>                judgment_id      subject_id                   predicate
#> 1 judgment:case-001:000017 case-001:000017 semantic:grounding_decision
#> 2 judgment:case-001:000031 case-001:000031 semantic:grounding_decision
#>    object_id
#> 1 HP:0004322
#> 2 HP:0001250
#>                                                                                                                                                                                                                                                                                                        value_json
#> 1 {"mention_id":"case-001:000017","decision":"keep","confidence":1,"patient_context":"The proband has short stature and seizures but no diabetes mellitus.","evidence_span":"short stature","short_reason":"Mention directly states short stature in proband.","replacement_node_id":null,"node_id":"HP:0004322"}
#> 2        {"mention_id":"case-001:000031","decision":"keep","confidence":0.95,"patient_context":"The proband has short stature and seizures but no diabetes mellitus.","evidence_span":"seizures","short_reason":"Mention directly states seizures in proband.","replacement_node_id":null,"node_id":"HP:0001250"}
#>   decision confidence
#> 1     keep       1.00
#> 2     keep       0.95
#>                                                                                                                                                                                        evidence
#> 1 {"evidence_span":"short stature","short_reason":"Mention directly states short stature in proband.","patient_context":"The proband has short stature and seizures but no diabetes mellitus."}
#> 2           {"evidence_span":"seizures","short_reason":"Mention directly states seizures in proband.","patient_context":"The proband has short stature and seizures but no diabetes mellitus."}
#>           model             recorded_at attrs
#> 1 LFM2.5-8B-A1B 2026-07-21 09:54:58.447  <NA>
#> 2 LFM2.5-8B-A1B 2026-07-21 09:54:58.447  <NA>
```
