# Wrap a token embedding function as a typed token provider

Wrap a token embedding function as a typed token provider

## Usage

``` r
ducksemantics_token_embedding_provider(fun, label = "function-token")
```

## Arguments

- fun:

  Function accepting a character vector and returning one
  token-embedding object per input text.

- label:

  Provider label for stored token rows.

## Value

An object implementing `DucksemanticsTokenEmbeddingProvider`.
