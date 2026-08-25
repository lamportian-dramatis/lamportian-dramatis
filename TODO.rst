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

Checked and sound
-----------------

No correctness bugs were found.  The solver's round bound in ``_columns`` leaves room for the
confirming pass; ``idle`` advances are counted into ``ncols``; a name used by both a sync and a
message is rejected; and a receive that would precede its own send fails on the causal-cycle
assertion rather than drawing backwards.
