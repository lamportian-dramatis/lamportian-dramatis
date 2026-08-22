TYPST ?= typst
UNIVERSE ?= $(HOME)/src/github.com/typst/universe

NAME := $(shell sed -n 's/^name = "\(.*\)"/\1/p' typst.toml)
VERSION := $(shell sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)

# The files the package is made of.  Everything else in this repository -- the Makefile above all --
# is development scaffolding and must not reach the Universe repository.
DIST := typst.toml lib.typ README.md CHANGELOG.md LICENSE gallery

SOURCES := $(wildcard gallery/*.typ)
IMAGES := $(SOURCES:.typ=.png)

DATA_HOME := $(if $(XDG_DATA_HOME),$(XDG_DATA_HOME),$(HOME)/.local/share)
LOCAL := $(DATA_HOME)/typst/packages/preview/$(NAME)/$(VERSION)

.PHONY: all gallery check install uninstall publish clean

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

gallery/%.png: gallery/%.typ lib.typ
	$(TYPST) compile --root . --format png --ppi 200 $< $@

## Compile every example without writing anything: silence means the library still works.
check: install
	@for f in $(SOURCES); do $(TYPST) compile --root . --format png $$f /dev/null || exit 1; done

## Stage the package into a clone of github.com/typst/packages, ready to commit and open a PR.
publish: check gallery
	@test -d "$(UNIVERSE)/packages/preview" || \
	  { echo "not a typst/packages clone: $(UNIVERSE)"; exit 1; }
	@dest="$(UNIVERSE)/packages/preview/$(NAME)/$(VERSION)"; \
	rm -rf "$$dest" && mkdir -p "$$dest" && cp -r $(DIST) "$$dest/" && echo "staged in $$dest"

clean:
	rm -f $(IMAGES)
