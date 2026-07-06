# Structural interface for text annotators

An annotator grounds text against the semantic store and returns mention
rows. The default implementation is the DuckDB lexical alias index.

## Usage

``` r
DucksemanticsAnnotator
```

## Format

An object of class `s7contract::s7_interface` (inherits from
`S7_object`) of length 1.
