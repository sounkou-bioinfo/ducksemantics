# Convert Orphanet product1 XML to FastHPOCR-compatible JSON

Converts the `OrphaCode`, English disorder `Name`, and `SynonymList`
fields from Orphadata's `en_product1.xml` into the JSON shape consumed
by upstream `FastHPOCR.IndexORPHANET`.

## Usage

``` r
orphanet_product1_xml_to_json(
  xml_file,
  json_file = sub("\\.xml$", ".json", xml_file),
  overwrite = FALSE
)
```

## Arguments

- xml_file:

  Path to `en_product1.xml`.

- json_file:

  Output JSON path. Defaults to replacing `.xml` with `.json`.

- overwrite:

  Replace an existing JSON file.

## Value

The normalized output JSON path.

## Examples

``` r
xml <- tempfile(fileext = ".xml")
writeLines(c(
  '<JDBOR><DisorderList><Disorder>',
  '<OrphaCode>1</OrphaCode><Name lang="en">Demo</Name>',
  '<SynonymList><Synonym lang="en">Demo synonym</Synonym></SynonymList>',
  '</Disorder></DisorderList></JDBOR>'
), xml)
orphanet_product1_xml_to_json(xml, tempfile(fileext = ".json"))
#> [1] "/tmp/Rtmp9Ilfew/file19971e8661ce.json"
```
