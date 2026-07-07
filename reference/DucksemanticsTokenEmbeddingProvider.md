# Structural interface for token embedding providers

A token embedding provider accepts a character vector and returns one
token-embedding object per input text. Each object contains an
`embeddings` matrix and token metadata.

## Usage

``` r
DucksemanticsTokenEmbeddingProvider
```

## Format

An object of class `s7contract::s7_interface` (inherits from
`S7_object`) of length 1.
