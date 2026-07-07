# ClinVar XML Projection

Checked against `https://ftp.ncbi.nlm.nih.gov/pub/clinvar/xml/` on 2026-07-07.
NCBI now publishes separate VCV and RCV XML releases. The current monthly files
are:

- `ClinVarVCVRelease_00-latest.xml.gz`: 5,824,540,370 bytes, released
  2026-07-02.
- `RCV_release/ClinVarRCVRelease_00-latest.xml.gz`: 5,979,514,688 bytes,
  released 2026-07-02.

The sample VCV XML has the shape we need: `VariationArchive`, `SimpleAllele`,
`GeneList`, `SequenceLocation`, `HGVS`, `XRefList`, `RCVList`, `TraitSet`,
`ClinicalAssertionList`, `TraitMappingList`, and deleted SCVs. That is not just
an XML document. It is a versioned clinical-variant assertion graph.

## Existing DuckDB Work

The community extension scan found related work but no ClinVar projection:

- `webbed` / `duckdb_webbed`: generic XML/HTML reading, XPath extraction,
  schema inference, and SAX streaming. It is useful for samples, diagnostics,
  and possibly early record extraction. It is not enough as the primary
  representation because ClinVar needs several normalized outputs per
  `VariationArchive`, stable identifiers, assertion provenance, ontology
  cross-reference semantics, and release-level reproducibility. The current
  VCV and RCV files are also larger than whole-document XML paths should assume.
- `rdf`: reads and writes RDF triples, including experimental RDF/XML. ClinVar
  XML is not RDF/XML; RDF can be an export target after projection.
- `duckpgq` and `onager`: graph query and graph analytics layers. They can
  consume projected node/edge tables, not parse ClinVar XML.
- `duckhts`: strong genomics precedent for typed native readers and row kernels,
  especially for locations, variant keys, and interval operations. It does not
  read ClinVar XML.
- `miint`: bioinformatics readers and some NCBI access. It does not expose a
  ClinVar VCV/RCV assertion graph.

Conclusion: a ClinVar-native DuckDB extension would not duplicate existing
community-extension work. It should reuse lessons from `webbed` and `duckhts`,
but own the ClinVar projection.

## Native Table Functions

The extension should expose one relation per stable projection, not a single
wide inferred XML table:

```sql
read_clinvar_releases(path_or_url)
read_clinvar_variants(path_or_url)
read_clinvar_alleles(path_or_url)
read_clinvar_locations(path_or_url)
read_clinvar_genes(path_or_url)
read_clinvar_traits(path_or_url)
read_clinvar_trait_mappings(path_or_url)
read_clinvar_assertions(path_or_url)
read_clinvar_xrefs(path_or_url)
read_clinvar_deleted_accessions(path_or_url)
read_clinvar_nodes(path_or_url)
read_clinvar_edges(path_or_url)
```

Implementation should stream `.xml.gz` records. C/C++ can use libxml2
`xmlTextReader` or SAX with per-parser error contexts. A Rust extension can use
a streaming XML reader and the DuckDB C API. The important property is record
streaming by `VariationArchive` / RCV record, not whole-document materialization.

## Graph Identifiers

Use deterministic, prefixed node ids:

```text
clinvar:vcv/VCV000091629
clinvar:variation/91629
clinvar:allele/97106
clinvar:rcv/RCV000077146
clinvar:scv/SCV003995313
ncbigene:672
hgnc:1100
dbsnp:rs80358152
medgen:C0677776
mondo:MONDO:0003582
orphanet:145
so:SO:0001575
```

Semantic projection then becomes ordinary `semantic_nodes` and
`semantic_edges`, while normalized ClinVar tables keep high-cardinality facts.

## Core Edges

Projected edges should include:

```text
clinvar:vcv/...        clinvar:has_variation       clinvar:variation/...
clinvar:variation/...  clinvar:has_allele          clinvar:allele/...
clinvar:variation/...  clinvar:located_on          clinvar:location/...
clinvar:variation/...  clinvar:affects_gene        ncbigene:...
clinvar:variation/...  clinvar:has_consequence     so:...
clinvar:variation/...  clinvar:has_rcv             clinvar:rcv/...
clinvar:variation/...  clinvar:has_scv             clinvar:scv/...
clinvar:scv/...        clinvar:asserts_trait       medgen:... | mondo:... | orphanet:...
clinvar:scv/...        clinvar:submitted_by        clinvar:submitter/...
clinvar:trait/...      owl:sameAs                  mondo:... | orphanet:... | medgen:...
```

Classification, review status, dates, assembly, HGVS expression, submitter, and
release provenance belong in typed columns plus `attrs` JSON on projected edges
where the graph needs to preserve the fact.

## First Package-Level Use

Before the native extension exists, `ducksemantics` can define the target schema
and benchmark questions:

- Can ClinVar trait xrefs recover MONDO/ORPHANET/HPO neighborhoods already in
  the semantic graph?
- Do variant/gene/trait assertion neighborhoods cluster coherently with BebeLM
  pooled embeddings?
- Which assertion texts or trait names need late interaction rather than pooled
  embeddings?
- How much memory does full-release graph projection need under DuckDB storage
  versus external allocation for matrices?

Those benchmarks should use the full VCV/RCV release or explicit documented
subsets, never toy XML as evidence.
