# Known bugs

This file records the defects that we know about and have not fixed.  Each entry says what you see, how to repeat it, and why it happens.  `docs/changelog.rst` records what each release fixed; this file records what it did not.

The entries below apply to version 0.3.0.

## A `gap` at the start of a lane runs into the replica name

Found on 2026-08-27.  Not fixed.

### What you see

A lane that starts with a `gap` draws its dotted stretch too far back.  The dots run into the replica name.  A short solid line also appears to the left of the dots.  The lane reads as if it starts before its own name.

The defect grows with the span:

| `gap` span | half-span at `col-gap: 2.0` | result |
| --- | --- | --- |
| `"small"` | 0.35 | stays clear of the name |
| `"medium"` (the default) | 0.60 | touches the name |
| `"large"` | 0.85 | runs through the name |

A wider `col-gap` makes the defect worse.  At `col-gap: 1.0` a `"medium"` gap stays clear.  At `col-gap: 4.0` the same gap runs deep into the name.

### How to repeat it

```typ
#lamport-diagram(
  replicas: ("small", "medium", "large", "none"),
  events: (
    "small": (gap("small"), [a], [b]),
    "medium": (gap, [a], [b]),
    "large": (gap("large"), [a], [b]),
    "none": ([a], [b]),
  ),
)
```

The last lane carries no gap.  It shows where a lane starts when the defect does not apply.

### Why it happens

A `gap` takes one column, the same as an event.  It draws a dotted stretch over `t ± span / 2`, and the middle of that stretch sits on the time of its column.  `span` is a fraction of `col-gap`: `0.35` for `"small"`, `0.6` for `"medium"` and `0.85` for `"large"`.  The stretch therefore stays inside its own column, which is what `_gap-spans` in `src/lib.typ` asks of it.

That rule holds only where the column has half a column of room on each side.  The first column does not.  To the left of it the lane leads in by `lane-start`, which is `-0.18` canvas centimeters, and the replica name follows.

The drawing works out the room it gives the name from `back-reach` and `fore-reach` in `src/lib.typ`.  `back-reach` moves only for an item that carries a label.  `fore-reach` moves only for a mark.  A `gap` carries neither, so neither number knows that the gap is there.  The name then goes at `back-reach - 0.3`, which is `-0.48` when no label reaches further back.  A `"medium"` gap draws ink from `-0.60`, so the ink and the name ask for the same space.

Two units meet here and only one of them scales.  The span of a `gap` scales with `col-gap`.  Both `lane-start` and the offset of `0.3` are fixed canvas centimeters.  A wider `col-gap` moves the ink further back and leaves the name where it was.

### A second defect, from the same cause

`runs-of` in `src/lib.typ` cuts a timeline into the runs that the line is drawn in, one cut at each `gap`.  It starts a cursor at `lane-start`, and pushes a run from that cursor to the start of the gap.  A leading gap puts the start of the gap before the cursor.  The run then ends before it starts, and the drawing draws it backwards.  That is the short solid line to the left of the dots.

The same code has the same defect at the other end of a lane.  A trailing `gap` can move the cursor past `lane-end`, and the last run reverses.  The arrowhead of the timeline then points backwards.  The three named spans stay under the limit, so an explicit span is necessary to see it:

```typ
#lamport-diagram(
  replicas: ("A",),
  events: ("A": ([a], [b], gap(120%))),
)
```

### How to fix it

The two defects are independent.  Each one needs its own fix.

- Fold the stretch of each `gap` into `back-reach` and `fore-reach`.  The name and the end of the lane then go around the ink instead of through it.

- Make `runs-of` drop a run that ends before it starts.  A reversed run is wrong whatever the two reaches say.

Do not fix this by refusing a `gap` its column.  A leading gap says that time passed before the first event that the diagram shows, which is a thing an author needs to say.

### A related case that the documentation already accepts

`docs/reference.rst` says this of `mark-displacement`: a nudge large enough to push a mark with no label left of where its lane starts "will leave it overhanging the replica name".  That is the same missing term, reached by a different route.  The documentation accepts it there, because the author asks for it.  A `gap` reaches the same state without the author asking for anything.
