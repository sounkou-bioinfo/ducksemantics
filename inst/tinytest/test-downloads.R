urls <- fast_hpo_cr_ontology_urls()
expect_true("hpo_obo" %in% names(urls))
expect_true(grepl("hp\\.obo$", urls[["hpo_obo"]]))
expect_true("hpo_json" %in% names(urls))
expect_true("hpo_phenotype_hpoa" %in% names(urls))
expect_true("mondo_obo" %in% names(urls))
expect_true("orphanet_product1_xml" %in% names(urls))

src <- tempfile(fileext = ".obo")
writeLines("format-version: 1.2", src)
dest_dir <- tempfile("downloads-")
out <- download_hpo_obo(dest_dir = dest_dir, url = src, quiet = TRUE)
expect_true(file.exists(out))
expect_equal(readLines(out), "format-version: 1.2")

out2 <- download_hpo_obo(dest_dir = dest_dir, url = src, quiet = TRUE)
expect_equal(out2, out)
expect_equal(RfastHPOCR:::hpo_resource_meta()$json$filename, "hp.json")

if (!requireNamespace("xml2", quietly = TRUE) || !requireNamespace("jsonlite", quietly = TRUE)) {
  exit_file("xml2/jsonlite not available for Orphanet conversion test")
}

xml <- tempfile(fileext = ".xml")
writeLines(
  '<JDBOR><DisorderList><Disorder><OrphaCode>166024</OrphaCode><Name lang="en">Demo disorder</Name><SynonymList><Synonym lang="en">Demo synonym</Synonym></SynonymList></Disorder></DisorderList></JDBOR>',
  xml
)
json <- orphanet_product1_xml_to_json(xml, tempfile(fileext = ".json"))
expect_true(file.exists(json))
parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)
entry <- parsed$JDBOR[[1]]$DisorderList[[1]]$Disorder[[1]]
expect_equal(entry$OrphaCode, "166024")
expect_equal(entry$Name[[1]]$label, "Demo disorder")
expect_equal(entry$SynonymList[[1]]$Synonym[[1]]$label, "Demo synonym")
