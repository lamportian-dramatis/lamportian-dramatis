Changelog
=========

All notable changes to this package are recorded here.  The format follows `Keep a Changelog
<https://keepachangelog.com/en/1.1.0/>`__, and the versions follow `Semantic Versioning
<https://semver.org/spec/v2.0.0.html>`__ — with the caveat that this is pre-1.0, so a ``0.x`` bump
may break anything.  A Typst import names an exact version, so nothing breaks under you: upgrading
is always a deliberate edit.

Unreleased
----------

Added
~~~~~

- ``fill`` on `event`:func:, `send`:func:, `recv`:func: and `sync`:func:, which paints the backdrop
  under a point's label.  \ ``auto`` keeps the white that has always broken whatever runs behind the
  label; a paint is used as given, so a label standing in a wash an overlay laid down can be given
  that same wash and read as part of it instead of as a hole punched in it; ``none`` leaves the
  backdrop unpainted, which is ``halo: none`` with the label's box kept.
- Rectangles round a diagram's own parts, for an overlay to draw against: `lane-rect(lane)
  <lane-rect>`:locator: for a whole timeline, `gap-rect(replica, index) <gap-rect>`:locator: for the
  stretch one `gap`:func: elides, `names-rect() <names-rect>`:locator: — or `names-rect(replica)
  <names-rect>`:locator: — for the strip the replica names are set in, and `arrow-rect(name)
  <arrow-rect>`:locator: for a message or a sync together with the two marks it runs between.  Each
  answers with the two corners ``rect`` takes, so it spreads straight into one, and each takes a
  ``pad`` that grows it: one number for every side, or a pair said in the diagram's own axes — how
  far along the timelines, how far across them — so that a padded box turns with the diagram like
  everything else an overlay is given.
- `time(replica, id-or-index) <time>`:locator:, the time a point's mark was drawn at, in columns —
  its column plus whatever ``displacement`` leant it off that column.  The locator could answer with
  the column the solver settled on and with the coordinate the mark landed on, but not with the time
  between the two, so a drawing that wanted to line something up with a displaced mark *across* the
  lanes had no way to say so.
- `pip-args(replica, id-or-index) <pip-args>`:locator:, the dot inside a point's ring, as arguments
  ready to spread into ``circle`` — ``none`` for every kind but a `sync`:func:, that being the only
  one that carries one.  The diagram draws that dot from it, the way it already draws the ring from
  `mark-args`:locator:, so an overlay restating an end of an exchange has both halves of it to hand.
- `arrow-mid(name) <arrow-mid>`:locator:, the middle of that arrow's shaft, which is where the
  diagram sets an arrow's own label before stepping it off the shaft — so a note hung there hangs
  where a label would have.
- ``halo`` on `send`:func:, `recv`:func: and `sync`:func:.  It was already on `event`:func:, and the
  drawing has always read it from every point — only the three constructors refused to pass it on,
  so a message label could not be let off its white rectangle.

Changed
~~~~~~~

- Either end of a `sync`:func: is drawn with a dot inside its ring.  Previously, a `recv`:func: and
  a `sync`:func: had the same mark.

.. _020--2026-08-23:

0.2.0 — 2026-08-23
------------------

A diagram is no longer bound to run left to right, and it can be drawn into.

Nothing an 0.1.0 document says means anything different: a horizontal diagram renders byte for byte
what 0.1.0 renders for it.  The two arguments whose defaults changed are spelled differently and
resolve to the same numbers there.

.. _added-1:

Added
~~~~~

- `orientation`:arg: on `lamport-diagram`:func:, which says which way logical time runs:
  `rightwards`:value:, `leftwards`:value:, `downwards`:value: or `upwards`:value:, with
  `horizontal`:value: and `vertical`:value: as shorter names for the first and third.  The
  horizontal pair lays the timelines out as rows and stacks the replicas downwards; the vertical
  pair lays them out as columns and stacks the replicas rightwards.  They are plain strings, so
  ``orientation: "vertical"`` needs no import.

- `left`:value: and `right`:value: alongside `above`:value: and `below`:value:, one import line
  covering every side a diagram may ask for.  Which two are legal follows from the orientation, and
  a side it has no room for is dropped back to that orientation's default rather than failing, so
  turning a finished diagram is one edit and not a compile error on every lane that named a side.
  It is dropped in silence: Typst gives user code no way to raise a compiler warning, and printing
  one into the document would put it in front of the reader rather than the author.

- `overlays`:arg: on `lamport-diagram`:func:, for drawing your own CeTZ into a diagram, addressing
  the diagram's own points by name, at a layer of your choosing.  A diagram is drawn in passes;
  ``layers`` names them, bottom to top, and a drawing given for one is appended to that pass.  The
  layer that earns the design is ``backdrops``: a wash put under the arrows comes out striped by the
  translucent band each lane lays down, and the same wash put over those bands comes out whole and
  still behind the timelines.

- With it, `event(id: ..) <event>`:func: for naming an event so a drawing can address it,
  `color-of(replica) <color-of>`:locator: and `mark-args(replica, id-or-index) <mark-args>`:locator:
  so a drawing can match a lane or restate one of its marks without restating the library's own
  choices, and ``draw``, re-exporting the CeTZ module the diagram draws with so a caller needs no
  second dependency to reach ``rect`` and ``circle``.

- A documentation site at `lamportian-dramatis.github.io
  <https://lamportian-dramatis.github.io/>`__, which the README now defers to for the reference.

.. _changed-1:

Changed
~~~~~~~

- `col-gap <lamport-diagram.col-gap>`:param: and `row-gap <lamport-diagram.row-gap>`:param: take
  ``none`` by default, meaning the spacing that suits the orientation rather than one pair of
  numbers for all four.  A horizontal diagram gets the ``2.0`` and ``1.5`` it always had; a vertical
  one gets them the other way about and wider, because what a gap makes room for is text, and text
  runs across the page however the diagram runs.  Give either a number and it is used as before.

- A ratio ``displacement`` is taken against the label's extent *along its timeline* — its width
  where the timelines are rows, its height where they are columns.  On a horizontal diagram that is
  what it always was.

Fixed
~~~~~

- A lower lane's timeline could paint over an upper lane's label where the two overlapped, the lower
  lane having been drawn later.  The lanes are drawn in three passes now — every timeline, then
  every mark, then every label — so every label is above every line.  This is also what makes
  ``timelines``, ``marks`` and ``labels`` layers an overlay can reach.

.. _010--2026-08-06:

0.1.0 — 2026-08-06
------------------

Initial release.

- `lamport-diagram`:func:, with columns solved rather than authored: every event lands in the
  earliest column that keeps it after its predecessor on the same replica and after the send of
  every message it receives, and a receive that would precede its own send fails compilation instead
  of drawing a backwards arrow.

- `replica`:func: for a lane and its event defaults, `event`:func: for a local step,
  `send`:func:/`recv`:func: for a one-way message, `sync`:func: for a two-way exchange, `gap`:func:
  for elided time and `idle`:func: for time in which nothing happened.

- `above`:value: and `below`:value: for label sides, and `default-palette`:value: for the lane
  colours.
