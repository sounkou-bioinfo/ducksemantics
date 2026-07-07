# Package index

## Graph Store

- [`ducksemantics_connect()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_connect.md)
  : Connect to a DuckDB semantic store
- [`ducksemantics_init()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_init.md)
  : Initialize semantic graph tables
- [`ducksemantics_schema_sql()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_schema_sql.md)
  : DuckDB semantic graph schema
- [`ducksemantics_tables()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_tables.md)
  : Semantic graph table names
- [`ducksemantics_write_graph()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_write_graph.md)
  : Write graph rows into the semantic store
- [`ducksemantics_embedding_batch()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_batch.md)
  : Construct an embedding batch
- [`ducksemantics_write_embeddings()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_write_embeddings.md)
  : Store an embedding batch in DuckDB
- [`ducksemantics_token_embedding_batch()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_token_embedding_batch.md)
  : Construct a token embedding batch
- [`ducksemantics_write_token_embeddings()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_write_token_embeddings.md)
  : Store token embeddings for late-interaction scoring
- [`ducksemantics_embedding_query()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_query.md)
  : Construct an embedding search query
- [`ducksemantics_embedding_search()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_search.md)
  : Search embeddings with DuckDB vector functions
- [`ducksemantics_embedding_index_spec()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_index_spec.md)
  : Construct an embedding index specification
- [`ducksemantics_materialize_embedding_index()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_materialize_embedding_index.md)
  : Materialize a fixed-dimension embedding table
- [`ducksemantics_embedding_cluster_spec()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_cluster_spec.md)
  : Construct an embedding clustering specification
- [`ducksemantics_cluster_embeddings()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_cluster_embeddings.md)
  : Cluster embedding rows
- [`ducksemantics_embedding_cluster_summary()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_cluster_summary.md)
  : Summarize stored embedding clusters
- [`ducksemantics_embedding_cluster_graph_agreement()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_cluster_graph_agreement.md)
  : Compare embedding clusters with graph edges
- [`ducksemantics_projection_sql()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_projection_sql.md)
  : Project any edge-shaped source relation into graph shape
- [`ducksemantics_closure_sql()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_closure_sql.md)
  : Materialize transitive edge closure
- [`ducksemantics_index_stats()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_index_stats.md)
  : Summarize semantic index size
- [`DucksemanticsEmbeddingBatch()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingBatch.md)
  : Embedding batch for the semantic store
- [`DucksemanticsTokenEmbeddingBatch()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsTokenEmbeddingBatch.md)
  : Token embedding batch for late-interaction storage
- [`DucksemanticsEmbeddingQuery()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingQuery.md)
  : Embedding search query
- [`DucksemanticsEmbeddingIndexSpec()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingIndexSpec.md)
  : Embedding index specification
- [`DucksemanticsEmbeddingClusterSpec()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingClusterSpec.md)
  : Embedding clustering specification

## Value Types

- [`DucksemanticsScalarText()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsScalarText.md)
  : Non-empty scalar text
- [`DucksemanticsSqlIdentifier()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsSqlIdentifier.md)
  : SQL identifier
- [`DucksemanticsDbConnection()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsDbConnection.md)
  : DBI connection reference
- [`DucksemanticsTable`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsTable.md)
  : Data frame contract
- [`DucksemanticsEmbeddingMatrix()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingMatrix.md)
  : Embedding matrix contract

## Grounding

- [`ducksemantics_normalize()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_normalize.md)
  : Normalize text for semantic grounding
- [`ducksemantics_tokens()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_tokens.md)
  : Tokenize text for semantic grounding
- [`ducksemantics_index_aliases()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_index_aliases.md)
  : Build the lexical alias index
- [`ducksemantics_annotate()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_annotate.md)
  : Annotate text against the semantic alias index
- [`ducksemantics_record_judgments()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_record_judgments.md)
  : Record semantic judgments

## Interfaces

- [`DucksemanticsAnnotator`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsAnnotator.md)
  : Structural interface for text annotators
- [`DucksemanticsPromptRunner`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsPromptRunner.md)
  : Structural interface for prompt runners
- [`DucksemanticsJudgmentParser`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsJudgmentParser.md)
  : Structural interface for judgment parsers
- [`DucksemanticsEmbeddingProvider`](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsEmbeddingProvider.md)
  : Structural interface for embedding providers
- [`ducksemantics_run()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md)
  [`ducksemantics_embed()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md)
  [`ducksemantics_parse()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md)
  [`ducksemantics_ground()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_provider_generics.md)
  : Provider interface generics
- [`ducksemantics_embed_cached()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embed_cached.md)
  : Cache provider embeddings in durable chunks
- [`ducksemantics_lexical_annotator()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_lexical_annotator.md)
  : Create the default DuckDB lexical annotator
- [`ducksemantics_prompt_runner()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_prompt_runner.md)
  : Wrap a prompt function as a typed prompt runner
- [`ducksemantics_embedding_provider()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_embedding_provider.md)
  : Wrap an embedding function as a typed embedding provider
- [`ducksemantics_json_judgment_parser()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_json_judgment_parser.md)
  : Create the default JSON judgment parser
- [`ducksemantics_bebel_runner()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_bebel_runner.md)
  : Create a BebeLM prompt runner
- [`ducksemantics_bebel_embedding_provider()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_bebel_embedding_provider.md)
  : Create a BebeLM embedding provider
- [`ducksemantics_bebel_tool_judgment_parser()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_bebel_tool_judgment_parser.md)
  : Create a BebeLM tool-call judgment parser

## Model Judgment

- [`ducksemantics_default_judgment_instructions()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_default_judgment_instructions.md)
  : Default judgment instructions
- [`ducksemantics_judgment_prompt()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_judgment_prompt.md)
  : Build a semantic judgment prompt
- [`ducksemantics_judge()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_judge.md)
  : Judge mentions with a model runner
- [`ducksemantics_bebel_judge()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_bebel_judge.md)
  : Judge mentions with a BebeLM/Rbebelm agent

## Ontology Import

- [`ducksemantics_cache_file()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_cache_file.md)
  : Cache a source file
- [`ducksemantics_cache_rds()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_cache_rds.md)
  : Cache an R value on disk
- [`ducksemantics_read_obo()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_read_obo.md)
  : Read an OBO ontology into semantic graph rows
- [`ducksemantics_write_obo()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_write_obo.md)
  : Write an OBO ontology into the semantic store

## Benchmarking

- [`ducksemantics_benchmark_cases()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_benchmark_cases.md)
  : Define benchmark cases
- [`ducksemantics_benchmark()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_benchmark.md)
  : Run a grounding benchmark
- [`ducksemantics_benchmark_metrics()`](https://sounkou-bioinfo.github.io/ducksemantics/reference/ducksemantics_benchmark_metrics.md)
  : Compute benchmark precision and recall
