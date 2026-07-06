# Materialize transitive edge closure

Returns DuckDB SQL that computes
`target_table(from_id, predicate, to_id)` as the transitive closure of
`source_table` for the supplied predicates. This is the same
graph-as-SQL primitive used for ontology ancestors, partonomy, memory
walks, and arbitrary declared transitive graph relations.

## Usage

``` r
ducksemantics_closure_sql(
  transitive_predicates,
  source_table = "semantic_edges",
  target_table = "semantic_entailed_edges"
)
```

## Arguments

- transitive_predicates:

  Character vector of predicates to close.

- source_table:

  Source edge table.

- target_table:

  Target closure table.

## Value

A single SQL statement.
