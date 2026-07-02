# Package index

## Python environment

Configure the reticulate environment used by the bindings.

- [`fast_hpo_cr_install()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_install.md)
  : Install the Python FastHPOCR dependency set
- [`fast_hpo_cr_available()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_available.md)
  : Test whether the FastHPOCR Python module can be imported
- [`fast_hpo_cr_config()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_config.md)
  : Show reticulate's active Python configuration
- [`fast_hpo_cr_use_env()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_use_env.md)
  : Select a named reticulate environment for FastHPOCR
- [`fast_hpo_cr_python_packages()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_python_packages.md)
  : Python packages required by RfastHPOCR

## Ontology downloads

Download and convert ontology source files used by FastHPOCR indexers.

- [`fast_hpo_cr_ontology_urls()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/fast_hpo_cr_ontology_urls.md)
  : Official ontology download URLs used by RfastHPOCR
- [`download_hpo_obo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_obo.md)
  [`download_mondo_obo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_obo.md)
  [`download_orphanet_product1_xml()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_obo.md)
  [`download_orphanet_product1_json()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_obo.md)
  : Download ontology source files for FastHPOCR indexing
- [`download_hpo_resource()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  [`download_hpo_json()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  [`download_hpo_owl()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  [`download_hpo_phenotype_hpoa()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  [`download_hpo_genes_to_phenotype()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  [`download_hpo_phenotype_to_genes()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  [`download_hpo_genes_to_disease()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md)
  : Download HPO ontology and annotation resources
- [`orphanet_product1_xml_to_json()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/orphanet_product1_xml_to_json.md)
  : Convert Orphanet product1 XML to FastHPOCR-compatible JSON

## Concept recognition

Create annotators, run FastHPOCR, and serialize annotations.

- [`hpo_annotator()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotator.md)
  : Create a FastHPOCR annotator
- [`hpo_annotate()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_annotate.md)
  : Annotate free text with a FastHPOCR index
- [`hpo_write_annotations()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_write_annotations.md)
  [`hpo_print_annotations()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_write_annotations.md)
  : Write or print FastHPOCR annotations

## Hybrid adjudication harness

Standardize candidates, prompts, adjudication JSON, and provider
comparison logs.

- [`hpo_harness_modes()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_harness_modes.md)
  : List supported HPO extraction harness modes
- [`hpo_candidate_table()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_candidate_table.md)
  : Convert FastHPOCR annotations to a harness candidate table
- [`hpo_extract_candidates()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_extract_candidates.md)
  : Extract FastHPOCR candidate tables for one or more cases
- [`hpo_adjudication_schema()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_adjudication_schema.md)
  : JSON schema for model adjudication of HPO candidates
- [`hpo_adjudication_prompt()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_adjudication_prompt.md)
  : Build a prompt for candidate-to-model HPO adjudication
- [`hpo_parse_adjudication()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_parse_adjudication.md)
  : Parse model adjudication JSON into a data frame
- [`hpo_adjudicate_candidates()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_adjudicate_candidates.md)
  : Run a candidates-to-model adjudication step

## Indexing

Build FastHPOCR indexes from ontology source files.

- [`hpo_index_config()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_index_config.md)
  : Build a FastHPOCR index configuration list
- [`hpo_real_index()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/hpo_real_index.md)
  : Download and build a cached full HPO FastHPOCR index
- [`index_hpo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_hpo.md)
  : Build a FastHPOCR HPO index
- [`index_mondo()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_mondo.md)
  : Build a FastHPOCR MONDO index
- [`index_orphanet()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_orphanet.md)
  : Build a FastHPOCR ORPHANET index
- [`index_snomed()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/index_snomed.md)
  : Build a FastHPOCR SNOMED index

## Package

- [`RfastHPOCR`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/RfastHPOCR-package.md)
  [`RfastHPOCR-package`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/RfastHPOCR-package.md)
  :

  R bindings to `FastHPOCR`
