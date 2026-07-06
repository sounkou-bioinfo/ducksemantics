# Ducksemantics Direction

`ducksemantics` is the package. It owns a DuckDB-native semantic graph and
grounding layer now: schema creation, graph writes, alias indexing, mention
grounding, closure SQL, typed model-provider interfaces, and benchmark
measurement.

HPO, MONDO, ORPHANET, study notes, memory, run ledgers, and local concept maps
are graph sources that project into the same tables. A future DuckDB extension
can optimize hot paths, but the package API is not waiting on it.

## Concrete Sources Being Abstracted

The abstraction closes over these existing shapes:

- Ontology label/synonym sources: aliases are normalized into a lexical index
  and returned as text spans plus concept identifiers.
- pi-bio-agent: `bio_edges`, `entailed_edge`, graph projection profiles,
  ontology terms, memory links, and as-of observations are graph-as-SQL.
- SemanticSQL: `statements`, `prefix`, generated `edge` views, and
  `entailed_edge` provide an ontology interchange shape.
- Rbebelm/bebelm: local CPU model judgment and embedding can enrich, reject,
  or explain deterministic candidates without owning the graph schema.

## Core Tables

The minimal graph/grounding contract is:

```sql
semantic_nodes(
  node_id TEXT PRIMARY KEY,
  family TEXT NOT NULL,
  label TEXT,
  description TEXT,
  attrs TEXT,
  trust TEXT
);

semantic_aliases(
  node_id TEXT NOT NULL,
  alias TEXT NOT NULL,
  alias_kind TEXT NOT NULL,
  source TEXT,
  weight DOUBLE,
  attrs TEXT
);

semantic_alias_index(
  node_id TEXT NOT NULL,
  alias TEXT NOT NULL,
  alias_kind TEXT NOT NULL,
  source TEXT,
  weight DOUBLE,
  attrs TEXT,
  normalized_alias TEXT NOT NULL,
  token_count INTEGER NOT NULL
);

semantic_edges(
  from_id TEXT NOT NULL,
  predicate TEXT NOT NULL,
  to_id TEXT NOT NULL,
  attrs TEXT,
  trust TEXT
);

semantic_entailed_edges(
  from_id TEXT NOT NULL,
  predicate TEXT NOT NULL,
  to_id TEXT NOT NULL
);

semantic_mentions(
  document_id TEXT,
  mention_id TEXT NOT NULL,
  node_id TEXT NOT NULL,
  span TEXT NOT NULL,
  start_offset INTEGER NOT NULL,
  end_offset INTEGER NOT NULL,
  score DOUBLE,
  method TEXT NOT NULL,
  attrs TEXT,
  trust TEXT
);

semantic_judgments(
  judgment_id TEXT NOT NULL,
  subject_id TEXT NOT NULL,
  predicate TEXT NOT NULL,
  object_id TEXT,
  value_json TEXT,
  decision TEXT NOT NULL,
  confidence DOUBLE,
  evidence TEXT,
  model TEXT,
  recorded_at TIMESTAMP,
  attrs TEXT
);
```

## Interfaces

Provider extension points are structural S7 interfaces, following the
`s7contract` style:

- `DucksemanticsAnnotator`: grounds text against a semantic store.
- `DucksemanticsPromptRunner`: sends a prompt to a model and returns text.
- `DucksemanticsJudgmentParser`: parses model text into judgment rows.
- `DucksemanticsEmbeddingProvider`: maps text to a numeric embedding matrix.

Concrete providers can be BebeLM/Rbebelm, a test fixture, a cloud model, a
future Rust index, or a different local embedding model. The consuming code
depends on the interface, not the provider.

## HPO/MONDO/ORPHANET Role

The old HPO-specific functions become import profiles and benchmark suites, not
the public abstraction:

```text
hp.obo              -> semantic_nodes + semantic_aliases + semantic_edges
mondo.obo           -> semantic_nodes + semantic_aliases + semantic_edges
orphanet product1   -> semantic_nodes + semantic_aliases + semantic_edges
SemanticSQL SQLite  -> statements/prefix/edge -> semantic_* / bio_edges
pi-bio graph tables -> semantic_* or direct bio_edges projection
```

The stable API is graph-first:

```r
ducksemantics_schema_sql()
ducksemantics_init()
ducksemantics_write_graph()
ducksemantics_index_aliases()
ducksemantics_annotate()
ducksemantics_judge()
suite |> ducksemantics_benchmark(conn)
```

## Benchmarking

Benchmarking belongs to the package API. It should measure deterministic
candidate generation, graph coverage, synonym handling, memory pressure,
latency, embedding cost, and model-assisted judgment. The lexical DuckDB matcher
sets the transparent floor; benchmark failures decide where synonym expansion,
vector reranking, negation, uncertainty, and family-history adjudication
actually improve HPO and MONDO tasks.
