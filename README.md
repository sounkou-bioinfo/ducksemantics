
<!-- README.md is generated from README.Rmd. Please edit that file -->

# RfastHPOCR

<!-- badges: start -->

[![R-CMD-check](https://github.com/sounkou-bioinfo/RfastHPOCR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sounkou-bioinfo/RfastHPOCR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`RfastHPOCR` is a reticulate-backed R binding to Tudor Groza’s
[`FastHPOCR`](https://github.com/tudorgroza/fast_hpo_cr) Python package
for fast concept recognition over Human Phenotype Ontology terms in free
text.

The package keeps the upstream Python implementation as the execution
engine and adds R-oriented helpers for:

- declaring and installing the Python dependency set (`FastHPOCR`,
  `pronto`, and `tqdm`),
- downloading ontology source files,
- building HPO, MONDO, ORPHANET, and SNOMED indexes,
- loading a FastHPOCR annotator from an index file, and
- converting annotation objects to R data frames with explicit offset
  columns.

## Installation

Install from GitHub with
`remotes::install_github("sounkou-bioinfo/RfastHPOCR")`.

For ordinary use, `RfastHPOCR` follows current reticulate package
practice: `library(RfastHPOCR)` declares the Python requirements with
`reticulate::py_require()`, and reticulate can resolve them in an
ephemeral virtual environment when Python is first initialized.

``` r
library(RfastHPOCR)
fast_hpo_cr_python_packages()
#> [1] "FastHPOCR>=0.1.4" "pronto"           "tqdm"
fast_hpo_cr_available()
#> [1] TRUE
```

`FastHPOCR` 0.1.4 on PyPI does not currently declare all runtime
dependencies, so `RfastHPOCR` requests `pronto` and `tqdm` explicitly.

If you prefer a persistent named environment, create it and select it
before Python is initialized:

For a persistent environment, run
`fast_hpo_cr_install(envname = "r-fast-hpo-cr", method = "virtualenv")`,
restart R, and then call
`fast_hpo_cr_use_env("r-fast-hpo-cr", method = "virtualenv")` before the
first Python import.

To install from the upstream GitHub repository instead of PyPI:

To install the Python dependency from the upstream GitHub repository
instead of PyPI, use
`fast_hpo_cr_install(source = "github", ref = "main")`.

If Python was already initialized before selecting or installing an
environment, restart R so reticulate can bind to the intended
environment.

## Ontology downloads

HPO is the primary target. HPO release assets are published at
<https://github.com/obophenotype/human-phenotype-ontology/releases>. The
`hp.obo` helper uses the stable OBO PURL and is the source file used by
FastHPOCR’s HPO indexer. Additional HPO JSON, OWL, HPOA, and
gene/phenotype tables are exposed for validation and audit workflows.

``` r
fast_hpo_cr_ontology_urls()[grep("^hpo_", names(fast_hpo_cr_ontology_urls()))]
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
```

For a real HPO analysis, use `download_hpo_obo("ontologies")` to fetch
the indexing source, plus optional audit resources such as
`download_hpo_json()`, `download_hpo_phenotype_hpoa()`, and
`download_hpo_genes_to_phenotype()`.

MONDO and Orphanet download helpers are present for the other upstream
FastHPOCR indexers, but they are not the focus of this package. MONDO
release assets are published at
<https://github.com/monarch-initiative/mondo/releases>.

The rest of this README is not a mock API sketch: it creates a tiny
HPO-style OBO file, runs the same HPO download helper through a local
file source, indexes it multiple ways with the Python FastHPOCR engine,
annotates text, and writes the annotation table. The local file source
keeps README rendering fast and network-independent while still
exercising the real download, indexing, re-indexing, annotation, and
serialization code paths.

## End-to-end HPO indexing and annotation

Create a tiny HPO-like ontology fixture. It contains the HPO root needed
by FastHPOCR (`HP:0000118`), two top-level abnormality categories, and
two concrete phenotype terms.

``` r
work_dir <- file.path(tempdir(), "RfastHPOCR-readme")
unlink(work_dir, recursive = TRUE)
dir.create(work_dir, recursive = TRUE)

source_obo <- file.path(work_dir, "source-hp.obo")
writeLines(c(
  "format-version: 1.2",
  "ontology: hp",
  "",
  "[Term]",
  "id: HP:0000001",
  "name: All",
  "",
  "[Term]",
  "id: HP:0000118",
  "name: Phenotypic abnormality",
  "is_a: HP:0000001 ! All",
  "",
  "[Term]",
  "id: HP:0000119",
  "name: Abnormality of the genitourinary system",
  "is_a: HP:0000118 ! Phenotypic abnormality",
  "",
  "[Term]",
  "id: HP:0000707",
  "name: Abnormality of the nervous system",
  "is_a: HP:0000118 ! Phenotypic abnormality",
  "",
  "[Term]",
  "id: HP:0004322",
  "name: Short stature",
  "synonym: \"short height\" EXACT []",
  "is_a: HP:0000119 ! Abnormality of the genitourinary system",
  "",
  "[Term]",
  "id: HP:0001250",
  "name: Seizure",
  "synonym: \"seizures\" EXACT []",
  "is_a: HP:0000707 ! Abnormality of the nervous system"
), source_obo)

hp_obo <- download_hpo_obo(
  dest_dir = file.path(work_dir, "downloads"),
  url = source_obo,
  quiet = TRUE
)
basename(hp_obo)
#> [1] "hp.obo"
```

Index both concrete phenotype branches and annotate a sentence.

``` r
index_all <- index_hpo(
  hpo_file = hp_obo,
  output_dir = file.path(work_dir, "index-all"),
  root_concepts = c("HP:0000119", "HP:0000707"),
  include_top_level_category = TRUE,
  compress_index = FALSE
)
#>  - Preprocessing HPO terms ...
#>  - Processing labels ...
#>  - Collected 2 terms.
#>  - Found 0 duplicated labels.
#>  - Indexing HPO terms ...
#>  - Serializing index ...
#>  - HPO index created in 0.35s
file.exists(index_all)
#> [1] TRUE

ann_all <- hpo_annotator(index_all)
hits_all <- hpo_annotate(
  ann_all,
  "The patient has short stature and seizures.",
  longest_match = TRUE
)
hits_all[, c("span", "id", "label", "start", "end", "start_offset", "end_offset")]
#>            span         id         label start end start_offset end_offset
#> 1 short stature HP:0004322 Short stature    17  29           16         29
#> 2      seizures HP:0001250      seizures    35  42           34         42
```

Re-index the same ontology restricted to the nervous-system branch. This
is a real second FastHPOCR indexing pass; the genitourinary
`Short stature` term is not present in this restricted index.

``` r
index_neuro <- index_hpo(
  hpo_file = hp_obo,
  output_dir = file.path(work_dir, "index-neuro"),
  root_concepts = "HP:0000707",
  include_top_level_category = TRUE,
  compress_index = FALSE
)
#>  - Preprocessing HPO terms ...
#>  - Processing labels ...
#>  - Collected 1 terms.
#>  - Found 0 duplicated labels.
#>  - Indexing HPO terms ...
#>  - Serializing index ...
#>  - HPO index created in 0.22s

ann_neuro <- hpo_annotator(index_neuro)
hpo_annotate(
  ann_neuro,
  "The patient has short stature and seizures.",
  longest_match = TRUE
)[, c("span", "id", "label")]
#>       span         id    label
#> 1 seizures HP:0001250 seizures
```

Re-index again with an external synonym file. The phrase `small stature`
is not in the tiny OBO file; it comes from the external synonym file
passed through to FastHPOCR.

``` r
syn_file <- file.path(work_dir, "external-synonyms.txt")
writeLines("HP:0004322=small stature", syn_file)

index_external <- index_hpo(
  hpo_file = hp_obo,
  output_dir = file.path(work_dir, "index-external"),
  root_concepts = c("HP:0000119", "HP:0000707"),
  external_syn_file = syn_file,
  include_top_level_category = TRUE,
  compress_index = FALSE
)
#>  - Preprocessing HPO terms ...
#>  - Processing labels ...
#>  - Collected 2 terms.
#>  - Found 0 duplicated labels.
#>  - Indexing HPO terms ...
#>  - Serializing index ...
#>  - HPO index created in 0.35s

ann_external <- hpo_annotator(index_external)
hpo_annotate(ann_external, "Small stature was noted.")[, c("span", "id", "label")]
#>            span         id         label
#> 1 Small stature HP:0004322 small stature
```

Serialize the R annotation table with the same tab-separated shape used
by the upstream Python package.

``` r
out_tsv <- file.path(work_dir, "annotations.tsv")
hpo_write_annotations(hits_all, out_tsv, include_categories = TRUE)
readLines(out_tsv)
#> [1] "[16:29]\tHP:0004322\tShort stature\tshort stature\t[HP:0000119 (Abnormality of the genitourinary system)]"
#> [2] "[34:42]\tHP:0001250\tseizures\tseizures\t[HP:0000707 (Abnormality of the nervous system)]"
```

## Role in the hybrid HPO extraction pipeline

The intended split is:

- **FastHPOCR**: deterministic extractor/linker baseline for explicit
  phenotype mentions.
- **Small local model**: phrase cleanup, paraphrase normalization, and
  candidate phenotype suggestions.
- **piknit / Pi**: auditable orchestration in R Markdown or Quarto,
  including local tool calls, model calls, and report generation.

In that design this package owns the deterministic FastHPOCR lane: text
in, candidate HPO rows out, with provenance and offsets preserved.

## Development

This package follows the same lightweight R package workflow as the
surrounding packages in this workspace:

``` sh
make rd       # roxygen2 docs + NAMESPACE
make test     # tinytest
make rdm      # render README.md from README.Rmd
make site     # pkgdown site
make check    # R CMD check --as-cran --no-manual
```
