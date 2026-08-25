"""A code block that lexes whole and shows part.

Pygments lexes Typst, not fragments of it: ``"A": (event(id: "bad"),)`` outside any call is not a
thing the language has, and the lexer says so by leaving it as plain text.  Wrapping the fragment in
the call it belongs to fixes the highlighting and buries the point of the example in scaffolding.

So the block is written whole, lexed whole, and only the lines worth reading are shown::

    .. typst-code::
       :only-lines: 2
       :dedent:

       #lamport-diagram(events: (
         "A": ([`A.1`], event(id: "bad")[`A.2`], sync("a-pushes")),
       ))

``only-lines`` counts the block's own lines from ``1`` and takes what `literalinclude`'s ``lines``
takes -- ``2``, ``2-4``, ``1,3-5``.  ``dedent`` strips the indentation the shown lines share, or the
number of columns given.  Neither reaches the lexer: it always sees the whole block, which is the
point.

`literalinclude` cannot do this.  Its ``start-at`` and ``lines`` cut the text out before Pygments
sees it, which lands back on the fragment Pygments cannot read.
"""

from docutils import nodes
from docutils.parsers.rst import directives
from sphinx.highlighting import PygmentsBridge
from sphinx.util.docutils import SphinxDirective


def parse_ranges(spec, count):
    """`2,4-6` over `count` lines, as a set of 0-based indices."""
    wanted = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            start, _, end = part.partition("-")
            first = int(start) if start.strip() else 1
            last = int(end) if end.strip() else count
        else:
            first = last = int(part)
        wanted.update(range(first - 1, last))
    return {i for i in wanted if 0 <= i < count}


def drop_leading_spaces(line, columns):
    """Remove `columns` leading spaces from a highlighted line, leaving its markup alone."""
    out, removed, i = [], 0, 0
    while i < len(line) and removed < columns:
        if line[i] == "<":
            j = line.index(">", i) + 1
            out.append(line[i:j])
            i = j
        elif line[i] == " ":
            removed += 1
            i += 1
        else:
            break
    out.append(line[i:])
    return "".join(out)


class TypstCode(SphinxDirective):
    has_content = True
    optional_arguments = 1
    final_argument_whitespace = False
    option_spec = {
        "only-lines": directives.unchanged_required,
        "dedent": directives.unchanged,
    }

    def run(self):
        language = self.arguments[0] if self.arguments else "typst"
        lines = list(self.content)
        source = "\n".join(lines)

        shown = parse_ranges(self.options["only-lines"], len(lines)) if "only-lines" in self.options else set(
            range(len(lines))
        )

        bridge = PygmentsBridge("html", self.env.config.pygments_style)
        highlighted = bridge.highlight_block(source, language, location=self.get_location())

        opening, _, rest = highlighted.partition("<pre>")
        body, closing, tail = rest.rpartition("</pre>")
        out = body.split("\n")
        while out and not out[-1].strip():
            out.pop()

        # Pygments writes one output line per source line, so the two line up -- unless a token spans
        # a line break, which nothing here does.  If they ever disagree, show the block whole rather
        # than hide the wrong lines.
        if len(out) == len(lines):
            # A range that opens or closes on a blank line would show it as a gap the reader has no
            # way to account for, the line it belonged to being hidden.
            visible = sorted(shown)
            while visible and not lines[visible[0]].strip():
                visible.pop(0)
            while visible and not lines[visible[-1]].strip():
                visible.pop()
            kept = [line for i, line in enumerate(out) if i in set(visible)]
            columns = self.dedent_columns([lines[i] for i in visible])
            if columns:
                kept = [drop_leading_spaces(line, columns) for line in kept]
            body = "\n".join(kept)

        node = nodes.raw("", f"{opening}<pre>{body}\n{closing}{tail}", format="html")
        self.set_source_info(node)
        return [node]

    def dedent_columns(self, shown_lines):
        """How far to unindent: what was asked for, or what the shown lines have in common."""
        if "dedent" not in self.options:
            return 0
        given = self.options["dedent"].strip()
        if given:
            return int(given)
        indents = [len(l) - len(l.lstrip(" ")) for l in shown_lines if l.strip()]
        return min(indents) if indents else 0


def setup(app):
    app.add_directive("typst-code", TypstCode)
    return {"version": "0.2", "parallel_read_safe": True, "parallel_write_safe": True}
