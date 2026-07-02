# RfastHPOCR

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
practice:
[`library(RfastHPOCR)`](https://github.com/sounkou-bioinfo/RfastHPOCR)
declares the Python requirements with
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html),
and reticulate can resolve them in an ephemeral virtual environment when
Python is first initialized.

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
[`download_hpo_json()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md),
[`download_hpo_phenotype_hpoa()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md),
and
[`download_hpo_genes_to_phenotype()`](https://sounkou-bioinfo.github.io/RfastHPOCR/reference/download_hpo_resource.md).

MONDO and Orphanet download helpers are present for the other upstream
FastHPOCR indexers, but they are not the focus of this package. MONDO
release assets are published at
<https://github.com/monarch-initiative/mondo/releases>.

The rest of this README is not a pseudo API sketch: it creates a tiny
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

index_all_log <- capture.output({
  index_all <- index_hpo(
    hpo_file = hp_obo,
    output_dir = file.path(work_dir, "index-all"),
    root_concepts = c("HP:0000119", "HP:0000707"),
    include_top_level_category = TRUE,
    compress_index = FALSE
  )
})
grep("Collected|Indexing HPO terms|Serializing index", index_all_log, value = TRUE)
#> [1] " - Collected 2 terms."     " - Indexing HPO terms ..."
#> [3] " - Serializing index ..."
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

index_neuro_log <- capture.output({
  index_neuro <- index_hpo(
    hpo_file = hp_obo,
    output_dir = file.path(work_dir, "index-neuro"),
    root_concepts = "HP:0000707",
    include_top_level_category = TRUE,
    compress_index = FALSE
  )
})
grep("Collected|Indexing HPO terms|Serializing index", index_neuro_log, value = TRUE)
#> [1] " - Collected 1 terms."     " - Indexing HPO terms ..."
#> [3] " - Serializing index ..."

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

index_external_log <- capture.output({
  index_external <- index_hpo(
    hpo_file = hp_obo,
    output_dir = file.path(work_dir, "index-external"),
    root_concepts = c("HP:0000119", "HP:0000707"),
    external_syn_file = syn_file,
    include_top_level_category = TRUE,
    compress_index = FALSE
  )
})
grep("Collected|Indexing HPO terms|Serializing index", index_external_log, value = TRUE)
#> [1] " - Collected 2 terms."     " - Indexing HPO terms ..."
#> [3] " - Serializing index ..."

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
  including local tool calls, model calls, and report generation. See
  <https://github.com/sounkou-bioinfo/piknit>.

In that design this package owns the deterministic FastHPOCR lane: text
in, candidate HPO rows out, with provenance and offsets preserved.

## Hybrid adjudication harness primitives

The package now also provides the small, model-agnostic pieces needed to
compare hybrid configurations without making `RfastHPOCR` depend on any
one LLM provider. The main practical arm is:

``` text
note + FastHPOCR candidates -> model keep/drop adjudication
```

FastHPOCR still generates deterministic candidates. The model is asked
only for short auditable fields: `decision`, `evidence_span`, and
`short_reason`. Reasoning-token counts, when a provider exposes them,
are stored only as run metadata.

``` r

review_text <- "Short stature was noted. No seizures were reported."
review_hits <- hpo_annotate(ann_all, review_text, longest_match = TRUE)
review_candidates <- hpo_candidate_table(review_hits, case_id = "readme-case-001")
review_candidates[, c("case_id", "candidate_id", "candidate_span", "hpo_id", "hpo_label")]
#>           case_id         candidate_id candidate_span     hpo_id     hpo_label
#> 1 readme-case-001 readme-case-001:0001  Short stature HP:0004322 Short stature
#> 2 readme-case-001 readme-case-001:0002       seizures HP:0001250      seizures
```

The harness modes are explicit so that `tool_only`, `model_only`, and
hybrid arms can be compared with the same term-level schema.

``` r

hpo_harness_modes()[, c("mode", "question")]
#>                           mode
#> 1                    tool_only
#> 2                   model_only
#> 3            model_tools_model
#> 4 model_candidates_tools_model
#> 5             candidates_model
#> 6       candidates_tools_model
#>                                                                  question
#> 1                              What is the deterministic FastHPOCR floor?
#> 2              Can the model extract and map HPO terms without grounding?
#> 3                       Does ontology grounding fix model mapping errors?
#> 4 Does model-generated candidate expansion plus grounding improve recall?
#> 5                 Does model cleanup fix FastHPOCR context noise cheaply?
#> 6 Does ontology validation after candidate generation add useful hygiene?
```

The prompt embeds the candidate rows and a strict JSON schema. The
README prints only the beginning of the prompt to keep the rendered
document short.

``` r

prompt <- hpo_adjudication_prompt(review_text, review_candidates)
cat(paste(head(strsplit(prompt, "\n", fixed = TRUE)[[1]], 16), collapse = "\n"))
#> You are adjudicating candidate Human Phenotype Ontology (HPO) extractions from de-identified clinical text.
#> Return only valid JSON matching the schema. Do not include markdown fences or explanatory prose outside JSON.
#> Do not provide hidden chain-of-thought. The clinical audit fields are decision, evidence_span, and short_reason.
#> Reasoning-token counts, if available from the API, are run metadata and are not a clinical audit field.
#> 
#> Prompt version: rfasthpocr-candidates-model-v1
#> Case id: readme-case-001
#> 
#> Decision rules:
#> - Return exactly one decision for each supplied candidate_id.
#> - decision = 'keep' only if the phenotype is present for the patient in the note.
#> - decision = 'drop' if the mention is negated, family-history-only, uncertain/not established, not about the patient, too generic, duplicated by a more specific kept candidate, or unsupported.
#> - patient_context must be one of: patient, family_history, negated, uncertain.
#> - evidence_span should be the shortest exact quote from the note that supports the decision, including negation or family-history wording when relevant.
#> - short_reason should be one concise sentence; do not include chain-of-thought.
#> - If the supplied HPO term is wrong but a better HPO term is obvious from the same evidence, keep decision='drop' and fill replacement_hpo_id/replacement_hpo_label.
```

A live model response is expected to be JSON. The real `piknit` / Pi
call is shown in the full-HPO stress test below; no hand-written
adjudication response is used in this README.

## Real-HPO clinical stress test

The tiny ontology above keeps the basic FastHPOCR example fast, but the
real harness should also be exercised against the current full HPO. The
helper below downloads `hp.obo` and builds a cached FastHPOCR index
under `RFASTHPOCR_REAL_HPO_DIR` or the R user cache directory. A fresh
full-HPO build can take several minutes; subsequent renders reuse the
index.

``` r

real_index <- hpo_real_index()

data.frame(
  hp_obo = basename(attr(real_index, "hpo_file")),
  hpo_index = basename(real_index),
  index_size_mb = round(file.info(real_index)$size / 1024^2, 1),
  stringsAsFactors = FALSE
)
#>   hp_obo hpo_index index_size_mb
#> 1 hp.obo  hp.index         132.7
```

``` r

stress_note <- paste(
  "The patient is a 6-year-old boy referred for genetics evaluation. He has global developmental delay, autism spectrum disorder, intellectual disability, brachydactyly, one hypomelanotic macule on the trunk, and one café-au-lait macule on the neck. Echocardiogram showed cardiomyopathy and a septal cardiac defect.",
  "He has no seizures, no hypotonia, no ataxia, and no hearing loss. There is no short stature and no microcephaly.",
  "Family history is notable for a brother with thrombocytosis and autism and a maternal aunt with cardiomyopathy. These findings are not present in the proband.",
  "Earlier notes described the child as floppy in infancy and not talking yet at 3 years of age. Teachers report that he learns slowly. Parents also describe occasional staring spells.",
  sep = "\n\n"
)

real_ann <- hpo_annotator(real_index)
stress_hits <- hpo_annotate(real_ann, stress_note, longest_match = TRUE)
stress_candidates <- hpo_candidate_table(
  stress_hits,
  case_id = "hpo-stress-001",
  source = "FastHPOCR-real-HPO"
)

stress_candidates[, c(
  "candidate_span", "hpo_id", "hpo_label", "start_offset", "end_offset"
)]
#>                candidate_span     hpo_id                   hpo_label
#> 1  global developmental delay HP:0001263 Developmental delay, global
#> 2    autism spectrum disorder HP:0000729    Autism spectrum disorder
#> 3                      autism HP:0000717                      Autism
#> 4     intellectual disability HP:0001249     Intellectual disability
#> 5               brachydactyly HP:0001156               Brachydactyly
#> 6        hypomelanotic macule HP:0009719       Hypomelanotic macules
#> 7         café-au-lait macule HP:0000957        Cafe-au-lait macules
#> 8              cardiomyopathy HP:0001638              Cardiomyopathy
#> 9              cardiomyopathy HP:0001638              Cardiomyopathy
#> 10      septal cardiac defect HP:0001671         Heart septal defect
#> 11                   seizures HP:0001250                     Seizure
#> 12                  hypotonia HP:0001252                   Hypotonia
#> 13                     ataxia HP:0001251                      Ataxia
#> 14               hearing loss HP:0000365                Hearing loss
#> 15              short stature HP:0004322               Short stature
#> 16               microcephaly HP:0000252                Microcephaly
#> 17             thrombocytosis HP:0001894              Thrombocytosis
#>    start_offset end_offset
#> 1            73         99
#> 2           101        125
#> 3           492        498
#> 4           127        150
#> 5           152        165
#> 6           171        191
#> 7           214        233
#> 8           269        283
#> 9           524        538
#> 10          290        311
#> 11          324        332
#> 12          337        346
#> 13          351        357
#> 14          366        378
#> 15          392        405
#> 16          413        425
#> 17          473        487
```

The real HPO candidate layer deliberately captures both true proband
findings and context traps: negated terms, family-history terms, and
duplicate mentions. That is exactly why the model layer should produce
explicit keep/drop decisions with an evidence quote.

``` r

pi_runner <- function(prompt) {
  usage <- list()
  reply <- piknit::pi_stream(
    prompt,
    provider = "openai-codex",
    model = "gpt-5.3-codex-spark",
    timeout = 300,
    on_delta = NULL,
    on_event = function(event) {
      if (identical(event$type, "turn_end") && !is.null(event$message$usage)) {
        usage <<- event$message$usage
      }
    }
  )
  attr(reply, "usage") <- usage
  reply
}

stress_run <- hpo_adjudicate_candidates(
  stress_note,
  stress_candidates,
  runner = pi_runner,
  provider = "openai-codex",
  model = "gpt-5.3-codex-spark",
  run_id = "hpo-stress-readme"
)

stress_run$adjudication[, c(
  "candidate_span", "hpo_id", "decision", "patient_context",
  "evidence_span", "short_reason"
)]
#>                candidate_span     hpo_id decision patient_context
#> 1  global developmental delay HP:0001263     keep         patient
#> 2    autism spectrum disorder HP:0000729     keep         patient
#> 3                      autism HP:0000717     drop  family_history
#> 4     intellectual disability HP:0001249     keep         patient
#> 5               brachydactyly HP:0001156     keep         patient
#> 6        hypomelanotic macule HP:0009719     keep         patient
#> 7         café-au-lait macule HP:0000957     keep         patient
#> 8              cardiomyopathy HP:0001638     keep         patient
#> 9              cardiomyopathy HP:0001638     drop  family_history
#> 10      septal cardiac defect HP:0001671     keep         patient
#> 11                   seizures HP:0001250     drop         negated
#> 12                  hypotonia HP:0001252     drop         negated
#> 13                     ataxia HP:0001251     drop         negated
#> 14               hearing loss HP:0000365     drop         negated
#> 15              short stature HP:0004322     drop         negated
#> 16               microcephaly HP:0000252     drop         negated
#> 17             thrombocytosis HP:0001894     drop  family_history
#>                             evidence_span
#> 1              global developmental delay
#> 2                autism spectrum disorder
#> 3  brother with thrombocytosis and autism
#> 4                 intellectual disability
#> 5                           brachydactyly
#> 6   one hypomelanotic macule on the trunk
#> 7     one café-au-lait macule on the neck
#> 8                          cardiomyopathy
#> 9     a maternal aunt with cardiomyopathy
#> 10                a septal cardiac defect
#> 11                            no seizures
#> 12                           no hypotonia
#> 13                              no ataxia
#> 14                        no hearing loss
#> 15                       no short stature
#> 16                        no microcephaly
#> 17          a brother with thrombocytosis
#>                                                                                                 short_reason
#> 1                                  The patient is explicitly described as having global developmental delay.
#> 2                                     The note directly lists autism spectrum disorder as a patient finding.
#> 3  Autism is only mentioned in the family-history sentence for the brother, not as a finding in the proband.
#> 4                                          The patient is explicitly stated to have intellectual disability.
#> 5                                          Brachydactyly is explicitly documented in the patient's findings.
#> 6                                         The note explicitly states the patient has a hypomelanotic macule.
#> 7                                          The patient is explicitly reported to have a café-au-lait macule.
#> 8                                   Echocardiogram findings directly document cardiomyopathy in the patient.
#> 9               This cardiomyopathy mention refers to the maternal aunt and is not a finding in the proband.
#> 10                                       The note explicitly states the patient has a septal cardiac defect.
#> 11                                       The clinician explicitly negates seizures in the review of systems.
#> 12                                           The note explicitly states the patient does not have hypotonia.
#> 13                                                              Ataxia is explicitly denied for the patient.
#> 14                                                              Hearing loss is explicitly listed as absent.
#> 15                                                                The note states there is no short stature.
#> 16                                               Microcephaly is explicitly denied in the physical findings.
#> 17                                       Thrombocytosis is reported only in the brother, not in the proband.

stress_run$run_log[, c(
  "provider", "model", "input_tokens", "output_tokens", "total_tokens",
  "reasoning_tokens", "estimated_cost_usd", "latency_seconds", "parse_success"
)]
#>       provider               model input_tokens output_tokens total_tokens
#> 1 openai-codex gpt-5.3-codex-spark         2896          5330        12322
#>   reasoning_tokens estimated_cost_usd latency_seconds parse_success
#> 1             3227          0.0804048        16.32628          TRUE
```

The real-HPO test also shows the boundary between the deterministic
candidate layer and the model-expansion arms: phrases such as “floppy in
infancy”, “not talking yet”, “learns slowly”, and “staring spells” may
require `model_only` or `model_candidates_tools_model` runs if we want
inferred or paraphrased phenotype recovery.

## Development

This package follows the same lightweight R package workflow as the
surrounding packages in this workspace:

``` sh
make rd             # roxygen2 docs + NAMESPACE
make test           # tinytest
make index-real-hpo # download/build a cached full HPO index
make rdm            # render README.md with the full real-HPO + Pi stress test
make rdm-real-hpo   # alias for make rdm
make site           # pkgdown site
make check          # R CMD check --as-cran --no-manual
```
