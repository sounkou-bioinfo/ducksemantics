if (!identical(tolower(Sys.getenv("RFASTHPOCR_TEST_REAL_HPO")), "true")) {
  exit_file("Set RFASTHPOCR_TEST_REAL_HPO=true to run the full real-HPO stress test")
}

idx <- hpo_real_index()

note <- paste(
  "The patient is a 6-year-old boy referred for genetics evaluation. He has global developmental delay, autism spectrum disorder, intellectual disability, brachydactyly, one hypomelanotic macule on the trunk, and one café-au-lait macule on the neck. Echocardiogram showed cardiomyopathy and a septal cardiac defect.",
  "He has no seizures, no hypotonia, no ataxia, and no hearing loss. There is no short stature and no microcephaly.",
  "Family history is notable for a brother with thrombocytosis and autism and a maternal aunt with cardiomyopathy. These findings are not present in the proband.",
  "Earlier notes described the child as floppy in infancy and not talking yet at 3 years of age. Teachers report that he learns slowly. Parents also describe occasional staring spells.",
  sep = "\n\n"
)

ann <- hpo_annotator(idx)
hits <- hpo_annotate(ann, note, longest_match = TRUE)
ids <- unique(hits$id)

expected_patient <- c(
  "HP:0001263", # global developmental delay
  "HP:0000729", # autism spectrum disorder
  "HP:0001249", # intellectual disability
  "HP:0001156", # brachydactyly
  "HP:0009719", # hypomelanotic macules
  "HP:0000957", # cafe-au-lait macules
  "HP:0001638", # cardiomyopathy
  "HP:0001671"  # heart septal defect
)
expected_negated <- c(
  "HP:0001250", # seizure
  "HP:0001252", # hypotonia
  "HP:0001251", # ataxia
  "HP:0000365", # hearing loss
  "HP:0004322", # short stature
  "HP:0000252"  # microcephaly
)
expected_family <- c(
  "HP:0001894", # thrombocytosis
  "HP:0000717"  # autism in brother
)

expect_true(all(expected_patient %in% ids))
expect_true(all(expected_negated %in% ids))
expect_true(all(expected_family %in% ids))
expect_true(sum(hits$id == "HP:0001638") >= 2L) # proband + maternal aunt

candidates <- hpo_candidate_table(hits, case_id = "hpo-stress-001")
expect_equal(nrow(candidates), nrow(hits))
expect_true(all(grepl("^hpo-stress-001:", candidates$candidate_id)))
