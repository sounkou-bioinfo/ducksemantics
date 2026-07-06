# DuckDB semantic graph schema

Returns the core SQL DDL for the generic semantic graph and grounding
contract. The schema is intentionally not HPO-specific: ontology terms,
local concept graphs, memory nodes, and graph projections can all use
the same node, alias, edge, mention, and judgment tables.

## Usage

``` r
ducksemantics_schema_sql(prefix = "semantic")
```

## Arguments

- prefix:

  Prefix used for the generated table names.

## Value

A character vector of SQL statements.
