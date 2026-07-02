# List supported HPO extraction harness modes

Returns the named ablation modes discussed for hybrid FastHPOCR plus
model phenotyping experiments. The package directly implements the
deterministic candidate lane and a generic candidates-to-model
adjudication wrapper; the other modes can use the same schema and prompt
contracts through project specific model/tool runners.

## Usage

``` r
hpo_harness_modes()
```

## Value

A data frame with `mode`, `flow`, and `question` columns.

## Examples

``` r
hpo_harness_modes()
#>                           mode
#> 1                    tool_only
#> 2                   model_only
#> 3            model_tools_model
#> 4 model_candidates_tools_model
#> 5             candidates_model
#> 6       candidates_tools_model
#>                                                                  flow
#> 1                                 note -> FastHPOCR -> HPO candidates
#> 2                                         note -> model -> HPO output
#> 3               note -> model -> ontology tools -> model final output
#> 4 note -> model -> candidates -> ontology tools -> model final output
#> 5         note + FastHPOCR candidates -> model keep/drop adjudication
#> 6 note + FastHPOCR candidates -> ontology tools -> model adjudication
#>                                                                  question
#> 1                              What is the deterministic FastHPOCR floor?
#> 2              Can the model extract and map HPO terms without grounding?
#> 3                       Does ontology grounding fix model mapping errors?
#> 4 Does model-generated candidate expansion plus grounding improve recall?
#> 5                 Does model cleanup fix FastHPOCR context noise cheaply?
#> 6 Does ontology validation after candidate generation add useful hygiene?
```
