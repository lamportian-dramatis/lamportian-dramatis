To do
=====

A review of ``lib.typ``, made on 2026-08-25 against commit
``ffcfe3cee2f91eb5db4783bea88e6db955adf60c``; every ``lib.typ:NNN`` below is a line of that
revision.  The question it set out to answer was whether the locators handed to an overlay and the
diagram's own drawing duplicate a lot of computation.  They do, structurally, and it costs nothing
at runtime: the reason to act on it is the shape of the code, not its speed.

What is computed more than once
-------------------------------

The locator has no second implementation of anything.  Every entry delegates to the closure the
drawing itself uses -- ``at``, ``mark-args-of``, ``shaft-of``, ``gap-span``, ``name-box`` -- and the
comments are explicit that this is how the two are kept in step.  The duplication is that sharing
happens by re-running those closures rather than by reading a table solved once.

- **A label is measured three times.**  ``extent-of`` (``lib.typ:1003``) calls ``measure``.  The
  reach loop at ``lib.typ:1033`` calls ``label-offset-of(it)``, which calls ``extent-of``, *and*
  then ``extent-of(it)`` itself; the labels pass calls ``label-offset-of`` again at
  ``lib.typ:1561`` and builds ``label-of(it)`` a fourth time for the ``content``.  Every label
  takes the ratio branch, because ``_resolve-defaults`` settles every displacement to ``0%``,
  ``first-displacement`` or the lane's own ratio -- ``0%`` included, where the extent is measured
  only to be multiplied by zero.

- **A point's position is recomputed about five times.**  ``t-at`` and ``at`` (``lib.typ:998-999``)
  are re-evaluated by the reach loop, the backdrop discs (``lib.typ:1499``), ``mark-args-of``
  (``lib.typ:1123-1127``), ``pip-args-of`` (``lib.typ:1262``), ``shaft-of`` (``lib.typ:1169-1170``)
  and the labels pass (``lib.typ:1561``), each time re-deriving ``offset-of`` from the item's type.

- **The arrows pass is two copies of one loop** (``lib.typ:1407-1429`` and ``lib.typ:1433-1454``),
  differing only in the ``mark:`` dictionary.  Both recompute the ``dx``, ``dy`` and ``len`` that
  ``shaft-of`` just computed and threw away, and both re-derive the midpoint that ``arrow-mid``
  (``lib.typ:1364``) computes too.  The documentation promises that ``arrow-mid`` is where the
  diagram sets an arrow's label; today that holds because the arithmetic is written twice, not
  because the two share it.

- **``runs-of(ri)`` is walked twice per lane**, once for the backdrop (``lib.typ:1493``) and once
  for the line (``lib.typ:1514``).

- **Five locator entries are the same two lines.**  ``mark``, ``column``, ``time``, ``mark-args``
  and ``pip-args`` (``lib.typ:1269-1294``) are each ``index-of`` followed by one delegate call.

Why it does not cost anything
-----------------------------

Typst memoizes ``measure``: 20 000 measures of one and the same content took 23 ms over an empty
loop, and 20 000 measures of distinct content 138 ms -- so a repeated measure is about a microsecond
and even a fresh one about seven.  Everything else above is a handful of float multiplications.  The
whole gallery, six diagrams, compiles in 1.6 s with process startup included (``make check``).
Nothing here is worth a memoization layer of the library's own, and no change below should be
argued for on speed.

What to change
--------------

- **Solve a per-point table once, right after ``ncols``, and make everything read from it.**  For
  each ``(ri, ii)``: ``t``, ``xy``, ``radius``, ``label`` (the built content, or ``none``),
  ``extent``, ``label-offset`` and ``halo-pad``.  One builder replaces ``t-at``, ``at``,
  ``extent-of``, ``label-offset-of``, ``label-halo-of``, ``mark-radius`` as a callable and most of
  ``mark-args-of`` and ``pip-args-of``.  The reach loop and the backdrop, marks and labels passes
  become field reads, and the five two-line locator entries become ``index-of`` and one field.
  Sharing then means "both read the same number", which is a stronger guarantee than "both call the
  same function" and needs no comment to defend it.  ``measure`` runs exactly once per label as a
  side effect.

- **Merge the two arrow loops** into one over ``msgs.keys() + exchanges.keys()``, choosing the
  ``mark:`` by ``name in exchanges``.  Have ``shaft-of`` return the unit direction alongside the two
  ends, and place the label off ``arrow-mid`` itself, so the documented promise holds by
  construction.

- **Compute ``runs-of(ri)`` once per lane.**  It belongs in the same table, per lane, next to
  ``name-box``.

- **Then, as a separate change, pull the drawing and the locator out of ``lamport-diagram``.**  The
  function runs from ``lib.typ:836`` to ``lib.typ:1590`` -- 754 lines, nearly half the file -- and
  the ``context`` block alone is some 600 lines holding 24 nested closures and 13 locator lambdas.
  A solved-layout dictionary is the value that lets ``_locator(layout)`` and ``_draw(layout,
  layers)`` become top-level functions, each readable on its own.  The table is the step that makes
  the split possible, and the split should not ride along with it.

Verify each step with ``make check`` and by diffing the gallery PNGs against the committed ones: the
drawing must come out pixel-identical, since none of this changes what is drawn.

Noticed on the way
------------------

- ``_item`` (``lib.typ:482-513``) is a second source of truth for defaults that ``event``, ``send``,
  ``recv`` and ``sync`` already set -- ``halo: auto``, ``fill: auto``, ``at: auto`` and so on.  It
  is needed for bare content and for a bare ``gap`` or ``idle``, but a default changed in one place
  and not the other would diverge in silence.

- ``first-displacement`` applies to index 0 (``lib.typ:529``), not to the first *labeled* item.  A
  lane that opens with ``sync("boot")[Gets A.1]``, as ``S`` does in ``gallery/overlays.typ``, gets
  ``0%`` and sits against the replica name in exactly the way the nudge exists to avoid.  The
  comment at ``lib.typ:522-523`` justifies non-events passing through for their *side*; the
  displacement was carried along with it.  Decide whether that is intended.

- A few ``///`` blocks have ragged wrapping left over from edits: ``lib.typ:397-400``,
  ``lib.typ:404-407`` and ``lib.typ:1279``.


Label padding is narrower than what CeTZ takes
----------------------------------------------

Noticed on 2026-08-27, against commit ``4c9c4a279ddb3424df48c90ad6011a203afac25c``.  The
``lib.typ:NNN`` lines below are of that revision, not of the review above.

``label-padding`` reaches ``draw.content`` unchanged.  Nothing between the author and CeTZ reads
it, so it is the one label argument that has no frame of ours: it applies around the label's own
box, which never turns when the orientation does.

CeTZ accepts more shapes for a padding than we do.  ``util.as-padding-dict`` in CeTZ 0.5.2 takes a
scalar, a CSS-like array of two, three or four values, or a dictionary keyed the way `Typst's pad
<https://typst.app/docs/reference/layout/pad/>`_ is keyed -- ``left``, ``right``, ``top``,
``bottom``, ``x``, ``y`` and ``rest``.  ``_point-label-padding`` (``lib.typ:153``) narrows all of
that to ``auto``, ``none`` or one length.

The narrowing is what keeps the library correct today, because ``label-box`` (``lib.typ:1458``)
computes the padded box by hand:

.. code-block:: typ

   size.width / 1cm + 2 * pad,
   (size.height + slack) / 1cm + 2 * pad,

``2 * pad`` multiplies a number.  An array and a dictionary are not numbers, so the moment
``label-padding`` accepts what CeTZ accepts, this fails.  It fails loudly, with a type error, and
it is the only thing that fails.

What does not break, and must not be "fixed"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``hung-box`` (``lib.typ:1420``) is correct for an asymmetric pad, and it is worth writing down why,
because it does not look correct.

``hung-box`` centers the box across the anchor axis, as ``x - w / 2``.  CeTZ does the same.  In
``draw/shapes.typ`` the padding grows the totals only::

   let width = calc.max(0, bounds-width + padding.left + padding.right)
   let height = calc.max(0, bounds-height + padding.top + padding.bottom)

and every anchor is then ``bounds-center`` plus or minus ``width / 2`` or ``height / 2``.  A pad of
``left: 5mm`` and ``right: 0mm`` therefore makes the frame wider and leaves it centered on the
anchor.  It moves the glyphs inside the frame; it does not move the frame.  ``names-rect`` hands
out the frame, which is what it says it hands out, so the two still agree.

What to change
~~~~~~~~~~~~~~

Resolve the padding to the dictionary CeTZ will resolve it to, and read the four sides:

- ``_point-label-padding`` (``lib.typ:153``) accepts anything ``cetz.util.as-padding-dict`` accepts,
  and rejects nothing else.

- ``label-padding-of`` (``lib.typ:1176``) answers that dictionary, with each side resolved to canvas
  units the way ``resolve-number`` resolves it: a length divided by ``1cm``, a number as it stands.
  ``cetz.util`` is exported, so the shape logic is CeTZ's and never a second copy of it.

- ``label-box`` adds ``left + right`` to the width and ``top + bottom`` to the height.

Do not wrap the label in `Typst's pad <https://typst.app/docs/reference/layout/pad/>`_.  CeTZ never
does: it measures the bare content and adds the four numbers itself.  Wrapping would apply the pad
twice unless CeTZ's own ``padding`` went to zero, and ``pad`` takes no array, so it cannot express
the CSS-like forms that CeTZ accepts.

When to do it
~~~~~~~~~~~~~

This is refactor work, not a fix to land on its own.  It belongs with the per-point table above:
``label-padding-of`` becomes a field of that table, holding the resolved dictionary, and
``label-box`` becomes a read of it.  Widening the argument first and building the table second
would write the four-side arithmetic twice.

``label-padding`` is also the clearest example of a *pass-through* value: the author hands it to
CeTZ and no code of ours reasons about it.  ``label-backdrop`` and a ``message``'s ``stroke``,
``size`` and ``padding`` are the others.  The refactor should carry them as one bundle rather than
thread each one through ``_item`` and ``_resolve-defaults`` field by field.  Widening
``label-padding`` is the first case that makes the field-by-field handling actually break, so it is
the right one to design the bundle around.

One thing to keep as it is
~~~~~~~~~~~~~~~~~~~~~~~~~~

``extent-of`` (``lib.typ:1163``) measures the label *unpadded*, and a ratio ``label-displacement``
is taken against that.  ``docs/reference.rst`` says the ratio is against the label's own extent, so
unpadded is the documented reading.  Keep it, and say so in a comment, or the next reader will make
the two agree and change what a ratio means.

Checked and sound
-----------------

No correctness bugs were found.  The solver's round bound in ``_columns`` leaves room for the
confirming pass; ``idle`` advances are counted into ``ncols``; a name used by both a sync and a
message is rejected; and a receive that would precede its own send fails on the causal-cycle
assertion rather than drawing backwards.


Labels do not line up along a lane
----------------------------------

Noticed on 2026-08-27, against commit ``4c9c4a279ddb3424df48c90ad6011a203afac25c``.  The
``lib.typ:NNN`` lines below are of that revision.

``gallery/kaiko.png`` shows it.  ``Download`` and ``Upload`` are on one lane, on one side of it, at
one text size, and their baselines are 4 pixels apart in a render 1024 pixels wide.  The one thing
that separates the two words is the ``p``: ``Upload`` has a glyph that reaches below the baseline,
and ``Download`` has none.

Why
~~~

CeTZ hangs a label off the box it measures, and that box runs from the cap height down to the
bottom of the ink, not down to the baseline.  ``content`` in CeTZ 0.5.2 measures the drop below the
baseline as ``baseline-offset`` (``draw/shapes.typ:1152-1157``) and adds it to the height of the
box.  A label with a descender therefore gets a taller box than a label without one: 0.22 em
taller in Libertinus, which is 2.2 pt at a text size of 10 pt.

``label-at`` (``lib.typ:1444``) steps the label ``side-step`` off its lane and hands that point to
``content`` under the ``south`` anchor (``side-anchor``, ``lib.typ:1073``, and the labels pass,
``lib.typ:1857``).  The anchor is the bottom edge of the box, so it is the bottom of the ink that
lands ``side-step`` off the lane.  The baseline lands wherever the height of the box leaves it.

The library already measures that drop.  ``label-box`` computes it as ``slack`` (``lib.typ:1466``),
because the box it gives out has to be the box on the page.  Placement does not read it.

Which sides are wrong
~~~~~~~~~~~~~~~~~~~~~

- ``above``, which anchors ``south``, is the side the gallery shows.  The label is out by the whole
  slack.

- ``below``, which anchors ``north``, is right as it stands.  The top edge of the box is the cap
  height, which is a metric of the font and does not depend on the glyphs the label holds.

- ``left`` and ``right``, which anchor ``east`` and ``west``, are out by half the slack, and they
  are out along the timeline rather than across it.  Those two anchors sit at the middle of an
  edge, so a taller box moves the glyphs half a slack up the page.

- The replica names are out the same way, and for the same reason.  ``name-anchor`` is ``east`` or
  ``west`` on a horizontal diagram (``lib.typ:65`` and ``lib.typ:76``), and ``lib.typ:1437`` hangs
  the name off it.  A lane named ``pyp`` sits half a slack higher against its line than a lane
  named ``oxo``; measured, that is 3 pixels of a 300 ppi render at 10 pt.

What to change
~~~~~~~~~~~~~~

Move the point the label is set at, and let the box follow it there as it already does.

- Lift ``slack`` out of ``label-box`` so that ``label-at`` reads the one number the box reads.  It
  belongs in the per-point table above, next to ``extent``.

- ``label-at`` then moves its point down the page: by the whole slack under ``south``, by half of
  it under ``east`` and ``west``, and by nothing under ``north``.  Down the page is a subtraction,
  since ``y`` grows upward on a CeTZ canvas.  The correction is in page terms, as ``side-offset``
  and ``side-anchor`` already are, so it does not turn with the orientation.

- ``label-box`` keeps hanging its box off ``label-at``, so ``names-rect`` still gives out the box
  the label went in.

- Do the same for the name box at ``lib.typ:1437``, which needs the half-slack step of an ``east``
  or ``west`` anchor.  ``name-content`` (``lib.typ:1434``) has no ``label-padding`` to reason
  about, so the slack is the whole of it.

``label-padding`` also sits between the anchor and the baseline, and this must not absorb it.  Two
labels with two paddings are meant to stand at two steps off their lane, because it is the edge of
the backdrop that has to keep clear of the line.  Labels that share a padding are the ones that
have to line up.  Only the slack is the defect.

One question to settle first
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``extent-of`` (``lib.typ:1163``) measures the label with ``measure``, and Typst measures from the
cap height to the baseline.  CeTZ boxes that height plus the slack.  The two agree on the width, so
a horizontal diagram is not affected; on a vertical one, a ratio ``label-displacement`` is taken
against a height that is not the height on the page.

So decide what "the label's own extent" in ``docs/reference.rst`` names: the extent of the type,
which is what the code measures today, or the extent of the ink, which is what the reader sees.
Whichever it names, say it in a comment next to the one at ``lib.typ:1160-1162``.

When to do it
~~~~~~~~~~~~~

This is a fix, not a refactor, and it can land on its own: it is one number and three additions.
The per-point table above is the better home for it, because ``slack`` then has one place to live
and ``label-at`` and ``label-box`` read the same field.  Either order works, as long as the table
does not drop the correction on the way.

This is also the one change in this file that must **not** come out pixel-identical.  Every gallery
image with a label that has a descender moves, by design.  Read the new images before committing
them, and do not diff them against the old ones for a pass.
