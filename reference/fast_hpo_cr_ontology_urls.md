# Official ontology download URLs used by RfastHPOCR

Returns the default source URLs used by the convenience download
helpers. HPO release assets are published at
<https://github.com/obophenotype/human-phenotype-ontology/releases>; the
OBO helper uses the stable OBO PURL for `hp.obo`.

## Usage

``` r
fast_hpo_cr_ontology_urls()
```

## Value

A named character vector of URLs.

## Examples

``` r
fast_hpo_cr_ontology_urls()
#>                                                             hpo_obo 
#>                            "https://purl.obolibrary.org/obo/hp.obo" 
#>                                                            hpo_json 
#>                           "https://purl.obolibrary.org/obo/hp.json" 
#>                                                             hpo_owl 
#>                            "https://purl.obolibrary.org/obo/hp.owl" 
#>                                                  hpo_phenotype_hpoa 
#>            "https://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa" 
#>                                              hpo_genes_to_phenotype 
#>    "https://purl.obolibrary.org/obo/hp/hpoa/genes_to_phenotype.txt" 
#>                                              hpo_phenotype_to_genes 
#>    "https://purl.obolibrary.org/obo/hp/hpoa/phenotype_to_genes.txt" 
#>                                                hpo_genes_to_disease 
#>      "https://purl.obolibrary.org/obo/hp/hpoa/genes_to_disease.txt" 
#>                                                       hpo_data_page 
#> "https://github.com/obophenotype/human-phenotype-ontology/releases" 
#>                                                           mondo_obo 
#>                         "https://purl.obolibrary.org/obo/mondo.obo" 
#>                                               orphanet_product1_xml 
#>                "https://www.orphadata.com/data/xml/en_product1.xml" 
```
