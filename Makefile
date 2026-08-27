TYPST ?= typst
UNIVERSE ?= $(HOME)/src/github.com/typst/universe

# The documentation toolchain, pinned and run through `uvx`: there is nothing to install, and the
# site a contributor builds is the site the published pages are built from.
SPHINX_VERSION := 9.1.0
FURO_VERSION := 2025.12.19
AUTOBUILD_VERSION := 2025.8.25
SPHINX := uvx --from sphinx==$(SPHINX_VERSION) --with furo==$(FURO_VERSION) sphinx-build
SPHINX_SERVE := uvx --from sphinx-autobuild==$(AUTOBUILD_VERSION) \
  --with sphinx==$(SPHINX_VERSION) --with furo==$(FURO_VERSION) sphinx-autobuild

NAME := $(shell sed -n 's/^name = "\(.*\)"/\1/p' typst.toml)
VERSION := $(shell sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)

# What a submission is made of, in the three groups typst/packages asks for.
#
# Required: without these the package does not work, or does not carry its own license and its own
# minimal offline documentation.  They go in the archive users download.
DIST := typst.toml src README.md LICENSE

# Documentation: whatever the README links to, so that those links resolve on Typst Universe.  These
# are committed alongside the package and kept out of the downloaded archive by `exclude` in
# typst.toml.  The list is read out of the README rather than written here, so a link added there is
# published without anybody having to remember this line.
# Braces, not parentheses: make balances `(` and `)` inside a `$(shell ..)`, and the `)` in the
# expression below would close it early.
README-LINKS := ${shell grep -oE ']\([^)]+\)' README.md \
  | sed -e 's/^](//' -e 's/)$$//' | grep -vE '^[a-z][a-z0-9+.-]*:' | sort -u}
LINKED := $(filter-out $(DIST),$(wildcard $(README-LINKS)))

# Everything else -- the Makefile, the documentation, and every example the README does not link --
# is development scaffolding and must not reach the Universe repository at all.  A reader has no way
# to open a file that is neither in the archive nor linked from the page.

SOURCES := $(wildcard gallery/*.typ)
IMAGES := $(SOURCES:.typ=.png)

DATA_HOME := $(if $(XDG_DATA_HOME),$(XDG_DATA_HOME),$(HOME)/.local/share)
LOCAL := $(DATA_HOME)/typst/packages/preview/$(NAME)/$(VERSION)

.PHONY: all gallery check install uninstall manifest publish docs preview icon clean

all: gallery

## Shadow @preview/$(NAME):$(VERSION) with the working tree.  The gallery examples import the package
## by its published spec, the way CeTZ's own examples do and the way the Universe linter wants, so
## nothing here compiles until the working tree answers to that name.  Local packages win over
## anything downloaded from Typst Universe, so remember `make uninstall` once you are done.
install:
	@rm -rf "$(LOCAL)" && mkdir -p "$(LOCAL)" && cp -r $(DIST) "$(LOCAL)/"

uninstall:
	@rm -rf "$(LOCAL)" && echo "removed $(LOCAL)"

## Recompile the README's images.
gallery: $(IMAGES)

$(IMAGES): | install

gallery/%.png: gallery/%.typ src/*.typ
	$(TYPST) compile --root . --format png --ppi 200 $< $@

## Compile every example without writing anything: silence means the library still works.
check: install
	@for f in $(SOURCES); do $(TYPST) compile --root . --format png $$f /dev/null || exit 1; done

## Build the documentation, and hand the HTML to the repository that serves it.  The sources are
## here, under docs/; `site` is the lamportian-dramatis.github.io submodule and holds nothing but the
## build.  `.nojekyll` is what stops GitHub Pages running Jekyll over `_static` and `_images`, whose
## leading underscores it would otherwise take for its own.  Commit and push inside site/, then commit
## the moved submodule pointer here, so a revision of this repository names the pages that went with
## it.
docs: gallery
	@test -d site || { echo "site/ is empty -- run: git submodule update --init"; exit 1; }
	@mkdir -p docs/gallery && cp $(IMAGES) docs/gallery/
	$(SPHINX) -b html -d .doctrees docs site
	@touch site/.nojekyll
	@git -C site status --short

## Watch the sources and serve the result at http://localhost:4983, rebuilding on every save.  It
## builds into .preview/ rather than into site/, so an afternoon's editing does not leave the
## submodule holding a hundred half-finished builds.
preview: gallery
	@mkdir -p docs/gallery && cp $(IMAGES) docs/gallery/
	$(SPHINX_SERVE) --port 4983 docs .preview

## Render the favicon from its drawing.  Each size is rendered from the vector rather than resampled
## from the next one up, because a 16 px entry downscaled from 48 is a smudge and a 16 px entry drawn
## at 16 is not.  Both files are committed, the way the gallery's images are, so an ordinary docs
## build needs neither of these tools -- only a change to the SVG does, which is why `docs` does not
## depend on this.
icon: docs/_static/favicon.ico

docs/_static/favicon.ico: docs/_static/favicon.svg
	@command -v rsvg-convert >/dev/null && command -v magick >/dev/null || \
	  { echo "rsvg-convert and magick are needed to rebuild the favicon"; exit 1; }
	@tmp=$$(mktemp -d) && trap 'rm -rf "$$tmp"' EXIT && \
	for s in 16 32 48; do rsvg-convert -w $$s -h $$s $< -o "$$tmp/$$s.png" || exit 1; done && \
	magick "$$tmp/16.png" "$$tmp/32.png" "$$tmp/48.png" $@ && echo "$@"

## List what `publish` would stage, without touching anything.
manifest:
	@printf 'required:\n'; for f in $(DIST); do echo "  $$f"; done
	@printf 'linked from the README:\n'; for f in $(LINKED); do echo "  $$f"; done

## Stage the package into a clone of github.com/typst/packages, ready to commit and open a PR.
publish: check gallery
	@test -d "$(UNIVERSE)/packages/preview" || \
	  { echo "not a typst/packages clone: $(UNIVERSE)"; exit 1; }
	@dest="$(UNIVERSE)/packages/preview/$(NAME)/$(VERSION)"; \
	rm -rf "$$dest"; \
	for f in $(DIST) $(LINKED); do \
	  mkdir -p "$$dest/$$(dirname "$$f")" && cp "$$f" "$$dest/$$f" || exit 1; \
	done; \
	echo "staged in $$dest:"; \
	(cd "$$dest" && find . -type f | sed 's|^\./|  |' | sort)

clean:
	rm -f $(IMAGES)
	rm -rf .preview docs/gallery
