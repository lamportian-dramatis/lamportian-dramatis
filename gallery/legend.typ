#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, sync, send, recv, replica, gap, above, below

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

#let event-color=rgb("#490062")
#let gap-color=rgb("#611300")
#let replica-color=rgb("#004533")
#let sync-color=rgb("#8b0069")
#let send-color=rgb("#8b0069")
#let recv-color=rgb("#0b4151")


#lamport-diagram(
  replicas: (replica("R1"), replica("R2", below), "D"),
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
      draw.circle(mark("R1", 2), radius: dot * 3, stroke: event-color + 1.2pt )
      draw.circle(mark("R1", 4), radius: dot * 3, stroke: send-color + 1.2pt)
      draw.circle(mark("R2", 2), radius: dot * 3, stroke: recv-color + 1.2pt)
    },
    // The callouts: a box round each part of the diagram and a note hung off that box.  A rectangle
    // comes back as the two corners `rect` takes, so a named `rect` leaves CeTZ holding the anchors
    // the note is placed against and nothing here has to know where anything landed on the page.
    foreground: d => {
      let (names-rect, gap-rect, arrow-rect, arrow-mid, lane-rect, color-of, draw, ..) = d
      let note = (at, anchor, color, body) => draw.content(
        at,
        anchor: anchor,
        padding: 0.07,
        text(size: 0.8em, fill: color, body),
      )
      let outline = color => (paint: color, thickness: 0.5pt, dash: "densely-dotted")

      draw.rect(..arrow-rect("t0", pad: 0.12), stroke: outline(sync-color), name: "sync")
      note("sync.south-east", "north", sync-color, [an exchange, both ways at once])

      draw.rect(..gap-rect("R1", 3, pad: (0, 0.14)), stroke: outline(gap-color), name: "elided")
      note("elided.north", "south", gap-color, [elided time])

      let (mx, my) = arrow-mid("t1")
      note((mx - 0.18, my), "east", send-color, [a message])

      draw.rect(..lane-rect("D", pad: (0.05, 0.12)), stroke: outline(color-of("D")), name: "lane")
      note("lane.north", "south", color-of("D"), [a timeline; the arrow indicates the direction of local time])
    },
  ),
)
