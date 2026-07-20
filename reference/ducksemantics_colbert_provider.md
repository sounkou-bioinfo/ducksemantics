# Create a native ColBERT token-vector provider

`role = "document"` is for ontology labels, definitions, and candidate
passages stored in DuckDB. `role = "query"` is for text being searched.
The native encoder owns the distinct prefixes, token limits, projection,
and L2 normalization required by the model; no causal BebeLM hidden
states are used.

## Usage

``` r
ducksemantics_colbert_provider(
  model,
  role = c("document", "query"),
  label = "Rbebelm ColBERT"
)
```

## Arguments

- model:

  A `Rbebelm` `ColbertModel` object.

- role:

  Whether this provider encodes retrieval `"query"` or `"document"`
  text.

- label:

  Provider label. Document rows and their query must share it.

## Value

An object implementing
[DucksemanticsTokenEmbeddingProvider](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsTokenEmbeddingProvider.md).
