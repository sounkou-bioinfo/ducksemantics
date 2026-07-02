# JSON schema for model adjudication of HPO candidates

Returns the structured output contract for the hybrid
candidate-adjudication step. Token usage and reasoning-token counts
belong in run-level metadata; clinical auditability comes from explicit
`decision`, `evidence_span`, and `short_reason` fields.

## Usage

``` r
hpo_adjudication_schema(as_json = FALSE, pretty = TRUE)
```

## Arguments

- as_json:

  Return the schema as pretty JSON instead of an R list.

- pretty:

  Pretty-print JSON when `as_json = TRUE`.

## Value

An R list or JSON string containing a JSON Schema object.

## Examples

``` r
schema <- hpo_adjudication_schema()
names(schema)
#> [1] "$schema"              "title"                "type"                
#> [4] "additionalProperties" "required"             "properties"          
```
