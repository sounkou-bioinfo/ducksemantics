cfg <- hpo_index_config(
  root_concepts = c("HP:0000119", "HP:0000707"),
  allow_3_letter_acronyms = TRUE,
  include_top_level_category = FALSE,
  allow_duplicate_entries = TRUE,
  compress_index = TRUE,
  customKey = "custom"
)

expect_equal(cfg$rootConcepts, c("HP:0000119", "HP:0000707"))
expect_true(cfg$allow3LetterAcronyms)
expect_false(cfg$includeTopLevelCategory)
expect_true(cfg$allowDuplicateEntries)
expect_true(cfg$compressIndex)
expect_equal(cfg$customKey, "custom")
expect_error(RfastHPOCR:::merge_index_config(list("bad"), list()))
expect_error(hpo_index_config(compress_index = NA))

pkgs <- fast_hpo_cr_python_packages()
expect_true("FastHPOCR>=0.1.4" %in% pkgs)
expect_true("pronto" %in% pkgs)
expect_true("tqdm" %in% pkgs)
expect_true("FastHPOCR" %in% fast_hpo_cr_python_packages(min_version = NULL))
