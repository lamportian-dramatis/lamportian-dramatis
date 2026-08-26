#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, sync, send, recv, replica, gap, above, below

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

#let annotation = luma(50)
#let outline = color => (paint: color, thickness: 0.5pt, dash: "densely-dotted")


#lamport-diagram(
  replicas: (replica("R1", label:"replica 1"), replica("R2", below), "D"),
  events: (
    "R1": (
      sync("t0", displacement: 0.5cm)[sync],
      "event",
      gap,
      send("t1")[send],
    ),
    "R2": (
      sync("t0", displacement: 0.5cm),
      recv("t1")[receive],
      "A",
    ),
    "D": (),
  ),
  overlays: (
    marks: d => {
      let (mark, dot, draw, color-of, ..) = d
      draw.circle(mark("R1", 2), radius: dot * 3, stroke: outline(annotation) )
    },
    foreground: d => {
      let (names-rect, gap-rect, arrow-rect, arrow-mid, lane-rect, color-of, span, draw, ..) = d
      let note = (at, anchor, color, body) => draw.content(
        at,
        anchor: anchor,
        padding: 0.07,
        text(size: 0.8em, fill: color, body),
      )

      draw.rect(..arrow-rect("t0", pad: 0.12), stroke: outline(annotation), name: "sync")
      note("sync.south", "north", annotation, [an exchange])

      draw.rect(..gap-rect("R1", 3, pad: (0, 0.14)), stroke: outline(annotation), name: "elided")
      note("elided.south", "north", annotation, [elided time])

      let (mx, my) = arrow-mid("t1")
      note((mx + 0.05, my), "west", annotation, [a one-way message])

      draw.rect(..lane-rect("D", pad: 0.05), stroke: outline(annotation), name: "timeline")
      note("timeline.south", "north", annotation, [a timeline; the arrow indicates the direction of local time])

      draw.rect(..names-rect(pad: 0.15), stroke: outline(annotation), name: "replicas")
      note("replicas.south", "north", luma(50), [replica labels])

      draw.rect(..names-rect("R2", -1, pad: 0.04), stroke: outline(annotation), name: "event-label")
      note("event-label.east", "west", luma(50), [event label])

   },
  ),
)
