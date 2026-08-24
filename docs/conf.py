import pathlib
import sys

# The documentation at https://lamportian-dramatis.github.io/.
#
# Sphinx is pinned and run through `uvx` -- see the `docs` target in the Makefile -- so the site a
# contributor builds is the site the published pages are built from, without anybody installing
# anything.  The built HTML goes to `site/`, which is the lamportian-dramatis.github.io repository
# carried here as a submodule; nothing but the HTML lives there.

project = "lamportian-dramatis"
author = "Manuel Vázquez Acosta"
copyright = "2026, Manuel Vázquez Acosta"

# `autosectionlabel` is what lets one page point at a section of another by its title, which is how
# the pages already cross-reference each other.  Prefixing with the document name keeps two pages
# from claiming the same section title.
# `_ext` carries the Typst domain: the library's own functions, values and locator entries are
# documented as objects rather than as sections, which is what gives them signatures, argument fields
# and a cross-reference target.  Making it the primary domain lets a page write :func:`sync` without
# spelling the domain out every time, and :any:`sync` resolves through it as well.
sys.path.insert(0, str(pathlib.Path(__file__).parent / "_ext"))

extensions = ["sphinx.ext.autosectionlabel", "typstdomain"]
primary_domain = "typst"

# A ten-argument signature does not belong on one line; past this many characters Sphinx
# breaks one argument per line instead.
maximum_signature_line_length = 70

# A cross-reference that resolves to nothing renders as plain text and says nothing about it, which
# is how a reference to a renamed object rots unnoticed.  Nitpicky mode turns every one of them into
# a warning, which is what a rename needs in order to be finished rather than merely started.
nitpicky = True
autosectionlabel_prefix_document = True
# The changelog repeats "Added" and "Changed" under every version; labelling those would be
# ambiguous and nothing points at them.  Two levels reaches every section that is referenced.
autosectionlabel_maxdepth = 2

exclude_patterns = ["_build"]

# Typst is a Pygments lexer as of 2.21, so the examples highlight without a plugin.  The alias is
# `typst`; `typ` is the file extension and not a lexer name.
highlight_language = "typst"

# That lexer does not accept `import draw: *`, which is valid Typst and appears in four of the
# examples; Sphinx falls back to relaxed lexing and highlights them anyway.  The warning is worth
# silencing rather than learning to ignore -- a build with four expected warnings in it is a build
# nobody reads.
suppress_warnings = ["misc.highlighting_failure"]

html_theme = "furo"
html_title = "lamportian-dramatis"
html_static_path = ["_static"]

# The published site is the build and nothing else: the sources live in the package repository, so
# copying them in beside the HTML would only be a second, staler copy.
html_copy_source = False
html_show_sourcelink = False

# The favicon is the diagram at the one size a favicon is ever seen: two timelines running to their
# arrowheads, an event on each.  `favicon.svg` is the drawing and `favicon.ico` is rendered from it
# by `make icon`, at 16, 32 and 48 px -- each rendered from the vector rather than resampled from
# the next size up, which is what keeps the 16 px entry crisp.
#
# Two files rather than one because Safari has been the laggard on SVG favicons, and Sphinx emits a
# single favicon <link>.  So the `.ico`, which every browser reads, is the one Sphinx names, and
# `_templates/layout.html` adds the SVG beside it for the browsers that would rather have the vector.
templates_path = ["_templates"]
html_favicon = "_static/favicon.ico"

# Sphinx emits a real <link> for an absolute URL, so the faces are fetched rather than merely named
# in a stack that falls through to whatever the reader happens to have.
html_css_files = [
    "https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400..700"
    "&family=Literata:opsz,wght@7..72,300..700&family=Inconsolata:wght@400..700&display=swap",
    "custom.css",
]

# Furo takes its fonts as CSS variables.  Headings are Fraunces, a Garalde with an optical-size axis
# that gives the page a voice; the text they head is Literata, which was drawn for reading on screens
# and keeps a large x-height and unambiguous letterforms at body sizes.  Code is Inconsolata.
#
# Fonts do not change with the colour scheme, so they are set once, in the light block: Furo's dark
# block overrides only what it lists.
html_theme_options = {
    "light_css_variables": {
        "font-stack": "Literata, Georgia, 'Times New Roman', serif",
        "font-stack--headings": "Fraunces, Georgia, serif",
        "font-stack--monospace": "Inconsolata, 'Roboto Mono', ui-monospace, monospace",
        # Code sits a little under the prose it explains: 18px against the body's 20.8.  Furo sizes
        # every listing and every inline snippet from this one variable, and `rem` pins it to the root
        # rather than to whatever it happens to be nested in.
        "code-font-size": "0.865rem",
    },
}
