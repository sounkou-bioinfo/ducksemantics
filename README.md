
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# ducksemantics

`ducksemantics` is a DuckDB-native semantic graph and evidence-grounding
package for R. It stores ontology nodes, aliases, graph edges, dense
vectors, and native ColBERT document token vectors in one auditable
DuckDB database.

It uses the dedicated Rbebelm model surfaces rather than causal
generator hidden states:

- **EmbeddingGemma** provides dense, task-prompted vectors for broad
  retrieval and optional DuckDB HNSW candidate generation.
- **LFM2.5-ColBERT** provides exact late-interaction MaxSim reranking of
  stored candidate documents.
- **BebeLM** provides local structured judgment of deterministic
  candidates, including negation, uncertainty, family history, and
  subject context.

HPO, MONDO, ORPHANET, and local knowledge graphs are sources for the
same graph schema, not special-purpose APIs.

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

Use a retrieval-trained dense encoder for broad candidate generation.
Choose an EmbeddingGemma task deliberately: vectors are only comparable
when they use a compatible prompt contract. This chunk executes a real
native encoder when `EMBEDDING_GEMMA_WEIGHTS_FILE` names a local GGUF.

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

ColBERT document vectors are persisted once. A query is encoded with its
own native query contract; the DuckDB reranker computes the exact MaxSim
sum over the stored document vectors. For a very large corpus, use dense
HNSW, lexical, or graph candidates first, then restrict
`candidate_subject_id` for the MaxSim pass. The chunk is evaluated
during every render and runs the real native model when
`COLBERT_WEIGHTS_FILE` names a local GGUF.

``` r
if (have_colbert) {
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
} else {
  message("Set COLBERT_WEIGHTS_FILE to execute the native ColBERT example.")
}
#> Set COLBERT_WEIGHTS_FILE to execute the native ColBERT example.
```

The token rows contain native 128-dimensional ColBERT document vectors,
not BebeLM causal states. `duckdb-vss` can accelerate the EmbeddingGemma
dense stage, but it does not implement variable-length ColBERT MaxSim.

## BebeLM candidate judgment

The final local LLM stage only receives candidates and context already
grounded by deterministic retrieval. Its structured response can drop
negated, uncertain, historical, or wrong-subject mentions; it may only
replace a concept with an explicitly supplied candidate or graph
neighbor. This chunk executes a real BebeLM call when
`BEBELM_WEIGHTS_FILE` names a local GGUF.

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
#> 1 LFM2.5-8B-A1B 2026-07-20 23:39:36.933  <NA>
#> 2 LFM2.5-8B-A1B 2026-07-20 23:39:36.933  <NA>
```
