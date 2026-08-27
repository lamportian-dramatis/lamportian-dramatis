#import "@preview/lamportian-dramatis:0.3.0": lamport-diagram, sync, send, recv, replica, gap, below

#set page(width: 12cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

// One ink per kind a locator answers in, and one for the guide that is both a column and a time.
#let column-ink = rgb("#490062")
#let time-ink = rgb("#00596b")
#let lane-ink = rgb("#611300")
#let both-ink = luma(90)

#let guide = ink => (paint: ink, thickness: 0.6pt, dash: "densely-dotted")

#lamport-diagram(
  replicas: (replica("R1"), replica("R2", below)),
  events: (
    // No labels on the two ends of the message: what the guides are drawn to say is where those two
    // marks stand, and a label beside either of them would sit across a guide to say it.
    "R1": (sync("t0"), "E", gap, send("t1")),
    "R2": (sync("t0"), recv("t1")),
  ),
  overlays: (
    // The guides go at `timelines`: over each lane's own line, under every mark, so a dotted line
    // crossing a lane passes behind the dots on it rather than through them.
    timelines: d => {
      let (point, column, time, span, draw, ..) = d
      let (starts, ends) = span
// A guide across the lanes runs a little outside the first and the last of them; the pair at the
      // message runs further, to leave room under the diagram for the gap between them to be measured.
      let before = -0.45
      let across = (t, ink, to: 1.45) => draw.line(point(t, before), point(t, to), stroke: guide(ink))

      // Column 1 is time 1: on a whole number the two kinds name the same place.
      across(1, both-ink)
      // And here they part.  The solver put both ends of the message in one column; the drawing leant
      // the receiving end off it, so the mark stands at a time that is no column at all.
      let (settled, drawn) = (column("R2", "t1"), time("R2", "t1"))
      across(settled, column-ink, to: 1.9)
      across(drawn, time-ink, to: 1.9)
      draw.line(
        point(settled, 1.78),
        point(drawn, 1.78),
        stroke: (paint: both-ink, thickness: 0.6pt),
        mark: (start: "stealth", end: "stealth", fill: both-ink, scale: 0.5),
      )

      // A lane is a position too, and a fractional one is between two replicas rather than on either.
      draw.line(point(starts, 0.5), point(ends, 0.5), stroke: guide(lane-ink))
    },
    // The notes go last, so each reads over whatever its guide crossed.
    foreground: d => {
      let (point, column, time, span, draw, ..) = d
      let (starts, ends) = span
      let note = (at, anchor, ink, body) => draw.content(
        at,
        anchor: anchor,
        padding: 0.05,
        text(size: 0.8em, fill: ink, body),
      )

      note(point(1.05, -0.45), "south-west", both-ink, [column 1 = time 1])
      let (settled, drawn) = (column("R2", "t1"), time("R2", "t1"))
      note(point(settled - 0.05, -0.45), "south-east", column-ink, [column 3])
      note(point(drawn + 0.05, -0.45), "south-west", time-ink, [time 3.5])
      note(point((settled + drawn) / 2, 1.9), "north", both-ink, [mark-displacement: 1cm])
      // Centred along the guide it names: between the two lanes there is nothing else to dodge.
      note(point((starts + ends) / 2, 0.5), "south", lane-ink, [lane 0.5])
    },
  ),
)
