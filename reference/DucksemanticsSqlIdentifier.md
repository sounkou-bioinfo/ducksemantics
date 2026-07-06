# SQL identifier

S7 value object for table and column identifiers used when constructing
DuckDB SQL.

## Usage

``` r
DucksemanticsSqlIdentifier(value = character(0), qualified = logical(0))
```

## Arguments

- value:

  Identifier text.

- qualified:

  Whether `value` may contain schema/table qualification.

## Value

A `DucksemanticsSqlIdentifier` object.
