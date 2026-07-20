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

``` r

library(ducksemantics)

conn <- ducksemantics_connect("semantic.duckdb")
hpo <- ducksemantics_read_obo("hp.obo", family = "HPO", source = "hp.obo")
ducksemantics_write_graph(
  conn,
  nodes = hpo$nodes,
  aliases = hpo$aliases,
  edges = hpo$edges,
  replace = TRUE
)

# Deterministic, explainable candidates. This intentionally includes negated
# mentions; BebeLM judgment decides whether the mention is a patient finding.
mentions <- ducksemantics_annotate(
  conn,
  "The proband has short stature and seizures but no diabetes mellitus.",
  document_id = "case-001"
)
```

## Dense retrieval with EmbeddingGemma

Use a retrieval-trained dense encoder for broad candidate generation.
Choose an EmbeddingGemma task deliberately: vectors are only comparable
when they use a compatible prompt contract.

``` r

library(Rbebelm)

embedding_model <- embeddinggemma_model_load(
  Sys.getenv("EMBEDDING_GEMMA_WEIGHTS_FILE"),
  num_threads = 8
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
  cache_dir = "embeddinggemma-hpo-cache"
)
ducksemantics_embedding_batch(
  vectors,
  subject_id = terms$node_id,
  subject_kind = "hpo_term",
  provider = "embeddinggemma-hpo-v1",
  text = terms$label
) |> ducksemantics_write_embeddings(conn, replace = TRUE)

# An HNSW index is optional. Exact DuckDB vector search also works.
dense_index <- ducksemantics_embedding_index_spec(
  dimensions = ncol(vectors),
  provider = "embeddinggemma-hpo-v1",
  subject_kind = "hpo_term",
  hnsw = TRUE
) |> ducksemantics_materialize_embedding_index(conn)
```

## Exact late interaction with native ColBERT

ColBERT document vectors are persisted once. A query is encoded with its
own native query contract; the DuckDB reranker computes the exact MaxSim
sum over the stored document vectors. For a very large corpus, use dense
HNSW, lexical, or graph candidates first, then restrict
`candidate_subject_id` for the MaxSim pass.

``` r

colbert_model <- colbert_model_load(
  Sys.getenv("COLBERT_WEIGHTS_FILE"),
  num_threads = 8
)
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
```

The token rows contain native 128-dimensional ColBERT document vectors,
not BebeLM causal states. `duckdb-vss` can accelerate the EmbeddingGemma
dense stage, but it does not implement variable-length ColBERT MaxSim.

## BebeLM candidate judgment

The final local LLM stage only receives candidates and context already
grounded by deterministic retrieval. Its structured response can drop
negated, uncertain, historical, or wrong-subject mentions; it may only
replace a concept with an explicitly supplied candidate or graph
neighbor.

``` r

generation_model <- bebel_model_load(Sys.getenv("BEBELM_WEIGHTS_FILE"), num_threads = 8)
agent <- bebel_agent(generation_model, greedy = TRUE, max_gen = 192L, max_think = 0L)

judgments <- ducksemantics_bebel_judge(
  agent,
  text = "The proband has short stature and no diabetes mellitus.",
  mentions = mentions,
  conn = conn,
  parser = ducksemantics_bebel_tool_judgment_parser(),
  model = "LFM2.5-8B-A1B"
)
```
