# h/t @jimhester and @yihui for the DESCRIPTION parse block.
PKGNAME := $(shell sed -n 's/Package: *\([^ ]*\)/\1/p' DESCRIPTION)
PKGVERS := $(shell sed -n 's/Version: *\([^ ]*\)/\1/p' DESCRIPTION)

all: check

# regenerate man/ + NAMESPACE from roxygen2 tags
rd:
	R -e 'roxygen2::roxygenize(load_code = "source")'

build: install_deps
	R CMD build .

check: build
	R CMD check --as-cran --no-manual $(PKGNAME)_$(PKGVERS).tar.gz

install_deps:
	R \
	-e 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")' \
	-e 'remotes::install_deps(dependencies = TRUE)'

install: build
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

install2:
	R CMD INSTALL --no-configure .

install3:
	R CMD INSTALL .

clean:
	@rm -rf $(PKGNAME)_$(PKGVERS).tar.gz $(PKGNAME).Rcheck ..Rcheck README.html docs

dev-install:
	R CMD INSTALL --preclean .

test1:
	R -e "tinytest::test_package('$(PKGNAME)', testdir = 'inst/tinytest', ncpu = 1L)"

test2:
	R -e "tinytest::test_package('$(PKGNAME)', testdir = 'inst/tinytest', ncpu = 2L)"

test0:
	R -e "tinytest::test_package('$(PKGNAME)', testdir = 'inst/tinytest')"

test: install
	R -e "tinytest::test_package('$(PKGNAME)', testdir = 'inst/tinytest')"

# render README.md from README.Rmd
rdm: install
	R -e "rmarkdown::render('README.Rmd')" && rm -f README.html

# render README.md and opt into the full real-HPO stress test
rdm-real-hpo: install
	RFASTHPOCR_README_REAL_HPO=true R -e "rmarkdown::render('README.Rmd')" && rm -f README.html

# build or reuse a cached full real-HPO index
index-real-hpo: install
	R -e 'library(RfastHPOCR); cache <- Sys.getenv("RFASTHPOCR_REAL_HPO_DIR", file.path(tools::R_user_dir("RfastHPOCR", "cache"), "real-hpo")); dir.create(cache, recursive = TRUE, showWarnings = FALSE); hp <- file.path(cache, "hp.obo"); if (!file.exists(hp)) hp <- download_hpo_obo(cache); idx_dir <- file.path(cache, "index"); idx <- file.path(idx_dir, "hp.index"); if (!file.exists(idx)) idx <- index_hpo(hp, idx_dir, root_concepts = "HP:0000118", include_top_level_category = TRUE, compress_index = FALSE); print(idx); print(file.info(idx)[, c("size", "mtime")])'

# build the pkgdown site into docs/
site: install
	R -e "pkgdown::build_site()"

.PHONY: all rd build check install_deps install install2 install3 clean dev-install test1 test2 test0 test rdm rdm-real-hpo index-real-hpo site
