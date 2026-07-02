if (!identical(tolower(Sys.getenv("RFASTHPOCR_TEST_PYTHON", "false")), "true")) {
  exit_file("Set RFASTHPOCR_TEST_PYTHON=true to run reticulate/FastHPOCR integration tests")
}

if (!fast_hpo_cr_available()) {
  exit_file("FastHPOCR Python package is not available")
}

index_json <- '{
  "clusters": {"C1": ["short"], "C2": ["stature"], "C3": ["seizures"]},
  "catDictionary": {"HP:0000118": "Phenotypic abnormality"},
  "termData": [
    {"uri": "HP:0004322", "categories": ["HP:0000118"], "labels": [{"tokenSet": ["C1", "C2"], "length": 2, "originalLabel": "Short stature", "native": true}]},
    {"uri": "HP:0001250", "categories": ["HP:0000118"], "labels": [{"tokenSet": ["C3"], "length": 1, "originalLabel": "Seizure", "native": true}]}
  ]
}'
index_file <- tempfile(fileext = ".json")
writeLines(index_json, index_file)

ann <- hpo_annotator(index_file)
hits <- hpo_annotate(ann, "The patient has short stature and seizures.", longest_match = TRUE)
expect_equal(hits$id, c("HP:0004322", "HP:0001250"))
expect_equal(hits$span, c("short stature", "seizures"))
expect_equal(hits$start_offset, c(16L, 34L))
expect_equal(hits$end_offset, c(29L, 42L))

work_dir <- tempfile("rfhpo-index-")
dir.create(work_dir)
obo <- file.path(work_dir, "tiny-hp.obo")
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
  "is_a: HP:0000119 ! Abnormality of the genitourinary system",
  "",
  "[Term]",
  "id: HP:0001250",
  "name: Seizure",
  "synonym: \"seizures\" EXACT []",
  "is_a: HP:0000707 ! Abnormality of the nervous system"
), obo)

idx_all <- index_hpo(
  obo,
  file.path(work_dir, "index-all"),
  root_concepts = c("HP:0000119", "HP:0000707"),
  include_top_level_category = TRUE
)
expect_true(file.exists(idx_all))
hits_all <- hpo_annotate(hpo_annotator(idx_all), "short stature and seizures")
expect_equal(hits_all$id, c("HP:0004322", "HP:0001250"))

idx_neuro <- index_hpo(
  obo,
  file.path(work_dir, "index-neuro"),
  root_concepts = "HP:0000707",
  include_top_level_category = TRUE
)
hits_neuro <- hpo_annotate(hpo_annotator(idx_neuro), "short stature and seizures")
expect_equal(hits_neuro$id, "HP:0001250")
