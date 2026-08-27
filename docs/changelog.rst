Changelog
=========

All notable changes to this package are recorded here.  The format follows `Keep a Changelog
<https://keepachangelog.com/en/1.1.0/>`__, and the versions follow `Semantic Versioning
<https://semver.org/spec/v2.0.0.html>`__ -- with the caveat that this is pre-1.0, so a ``0.x`` bump
may break anything.  A Typst import names an exact version, so nothing breaks under you: upgrading
is always a deliberate edit.

0.3.0 -- Unreleased
-------------------

Added
~~~~~

- One API for all four kinds of point.  `event`:func:, `send`:func:, `recv`:func: and `sync`:func:
  now take the same nine arguments -- ``body``, ``id``, ``label-position``, ``label-displacement``,
  ``mark-displacement``, ``label-size``, ``label-width``, ``label-padding`` and ``label-backdrop`` --
  and read them the same way.  The three that carry an arrow take ``label`` on top of those.  The
  renames this cost are in the table under Changed, below.

- Positional arguments are told apart by type on all four, so they may come in any order:
  ``send("push", below, +50%)[pushed]`` is as good as naming each one.  Previously only an
  `event`:func: read its arguments this way.

- ``mark-displacement`` on `event`:func:, which nudges an event's dot off the column the layout
  solved it into.  An event's dot could not be moved at all before.

- ``label-width`` and ``id`` on `send`:func:, `recv`:func: and `sync`:func:.  An ``id`` given there
  replaces the message name an `overlay <overlays>`:doc: would otherwise address the point by.

- ``label`` on `recv`:func:, which labels the message arrow.  Either end of a message may carry it
  now, and the first one given wins -- the rule a `sync`:func: already used.

- ``label-padding`` and ``label-backdrop`` on all four, which set how far a label's backdrop reaches
  past the label's own box and what it is painted with.

- New locators:

  - `arrow-mid(name) <arrow-mid>`:locator:
  - `gap-rect(replica, index) <gap-rect>`:locator:
  - `lane(replica) <lane>`:locator:
  - `lane-rect(lane) <lane-rect>`:locator:
  - `message-args(from, to) <message-args>`:locator:
  - `message-mid(from, to) <message-mid>`:locator:
  - `names-rect`:locator:
  - `pip-args(replica, id-or-index) <pip-args>`:locator:
  - `time(replica, id-or-index) <time>`:locator:

- ``messages`` on `lamport-diagram`:func:, holding `message`:func: items.


Changed
~~~~~~~

- Every argument that acts on a point's own label now says so, and ``displacement`` alone is no
  longer a parameter of anything: it named the label on an `event`:func: and the mark on the other
  three.

  .. list-table::
     :header-rows: 1

     * - Was
       - Is
       - On
     * - ``position``
       - ``label-position``
       - `event`:func:
     * - ``displacement``
       - ``label-displacement``
       - `event`:func:
     * - ``displacement``
       - ``mark-displacement``
       - `send`:func:, `recv`:func:, `sync`:func:
     * - ``size``
       - ``label-size``
       - all four
     * - ``width``
       - ``label-width``
       - `event`:func:
     * - ``halo``
       - ``label-padding``
       - all four
     * - ``fill``
       - ``label-backdrop``
       - all four

- A `replica's <replica>`:func: point defaults move under ``defaults``, and take the name of the
  point argument each one stands for: ``defaults: (label-position: .., label-size: ..,
  label-displacement: .., first-label-displacement: ..)``.  The lane's own ``label`` is the name the
  diagram prints for the lane, and grouping the defaults is what keeps the two from reading as one.
  A side and a color are still positional on the lane itself.

- A lane's ``label-size``, ``label-displacement`` and ``first-label-displacement`` defaults now reach
  a `send`:func:, a `recv`:func: and a `sync`:func: too.  They reached local events only.  A lane
  that opens on one of those three therefore takes the orientation's ``first-label-displacement``,
  and its label no longer crowds the replica name.

  ``label-position`` is the one default that still reaches local events only: the other three points
  each have an arrow to stay clear of, and their label takes the side that clears it.

- A displacement is ``0`` where it used to be ``none``: ``recv(.., mark-displacement: 0)`` says what
  ``recv(.., displacement: none)`` said.  Both displacements now take the same four values --
  ``auto``, ``0``, a ratio or a length.

- Either end of a `sync`:func: is drawn with a dot inside its ring.  Previously, a `recv`:func: and
  a `sync`:func: had the same mark.

- ``at`` is now ``label-position`` on `send`:func:, `recv`:func: and `sync`:func:, so that it
  matches the "position" naming in other functions and the documentation.

- Every arrowhead is curved: a message, both ends of a `sync`:func:, and the head each timeline ends
  with.

Removed
~~~~~~~

- ``delay`` on `send`:func:.  A message no longer pushes its receive into a later column; reserve
  that column on the receiving lane with `idle(1) <idle>`:func: instead.

- ``none`` as a displacement.  ``0`` is what says "do not move" now, on both displacements.


.. _020--2026-08-23:

0.2.0 -- 2026-08-23
-------------------

A diagram is no longer bound to run left to right, and it can be drawn into.

Nothing an 0.1.0 document says means anything different: a horizontal diagram renders byte for byte
what 0.1.0 renders for it.  The two arguments whose defaults changed are spelled differently and
resolve to the same numbers there.

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

Changed
~~~~~~~

- `col-gap <lamport-diagram.col-gap>`:param: and `row-gap <lamport-diagram.row-gap>`:param: take
  ``none`` by default, meaning the spacing that suits the orientation rather than one pair of
  numbers for all four.  A horizontal diagram gets the ``2.0`` and ``1.5`` it always had; a vertical
  one gets them the other way about and wider, because what a gap makes room for is text, and text
  runs across the page however the diagram runs.  Give either a number and it is used as before.

- A ratio ``displacement`` is taken against the label's extent *along its timeline* -- its width
  where the timelines are rows, its height where they are columns.  On a horizontal diagram that is
  what it always was.

Fixed
~~~~~

- A lower lane's timeline could paint over an upper lane's label where the two overlapped, the lower
  lane having been drawn later.  The lanes are drawn in three passes now -- every timeline, then
  every mark, then every label -- so every label is above every line.  This is also what makes
  ``timelines``, ``marks`` and ``labels`` layers an overlay can reach.

.. _010--2026-08-06:

0.1.0 -- 2026-08-06
-------------------

Initial release.

- `lamport-diagram`:func:, with columns solved rather than authored: every event lands in the
  earliest column that keeps it after its predecessor on the same replica and after the send of
  every message it receives, and a receive that would precede its own send fails compilation instead
  of drawing a backwards arrow.

- `replica`:func: for a lane and its event defaults, `event`:func: for a local step,
  `send`:func:/`recv`:func: for a one-way message, `sync`:func: for a two-way exchange, `gap`:func:
  for elided time and `idle`:func: for time in which nothing happened.

- `above`:value: and `below`:value: for label sides, and `default-palette`:value: for the lane
  colors.
