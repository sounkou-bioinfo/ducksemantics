records <- list(
  list(
    span = "short stature",
    id = "HP:0004322",
    label = "Short stature",
    start = 1L,
    end = 13L,
    start_offset = 0L,
    end_offset = 13L,
    categories = list(list(uri = "HP:0000118", label = "Phenotypic abnormality"))
  ),
  list(
    span = "seizures",
    id = "HP:0001250",
    label = "Seizure",
    start = 19L,
    end = 26L,
    start_offset = 18L,
    end_offset = 26L,
    categories = list()
  )
)

df <- RfastHPOCR:::records_to_data_frame(records)
expect_true(is.data.frame(df))
expect_equal(nrow(df), 2L)
expect_equal(df$span, c("short stature", "seizures"))
expect_equal(df$start, c(1L, 19L))
expect_equal(df$end_offset, c(13L, 26L))
expect_equal(df$categories[[1]][[1]]$uri, "HP:0000118")

lines <- RfastHPOCR:::format_annotation_lines(df, include_categories = FALSE)
expect_equal(lines[[1]], "[0:13]\tHP:0004322\tShort stature\tshort stature")
expect_equal(lines[[2]], "[18:26]\tHP:0001250\tSeizure\tseizures")

lines_with_categories <- RfastHPOCR:::format_annotation_lines(df, include_categories = TRUE)
expect_true(grepl("HP:0000118 \\(Phenotypic abnormality\\)", lines_with_categories[[1]]))
expect_equal(lines_with_categories[[2]], lines[[2]])

out <- tempfile()
hpo_write_annotations(df, out, include_categories = TRUE)
expect_equal(readLines(out), lines_with_categories)

printed <- capture.output(hpo_print_annotations(df))
expect_equal(printed, lines)
expect_error(hpo_write_annotations(list(list(span = "x")), tempfile()))
