#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, sync, below, above, send, recv, replica, event, draw
#import draw: *

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt)

#lamport-diagram(
  replicas: (replica("S", above, color: luma(0)), replica("A", below), replica("C", below)),
  events: (
    "S": (sync("boot"), send("c-reads"), sync("a-pushes"), recv("c-pushes"), sync("a-catches-up")),
    "C": (recv("c-reads"), event(id: "c1")[`C.1`], send("c-pushes")),
    "A": ([`A.1`], sync("boot"), event(id: "a2")[`A.2`], sync("a-pushes"), sync("a-catches-up")),
  ),
  overlays: (
    // The future cone of `A.2`: the part of the diagram that event can still reach.  It opens one
    // lane per column from where the event happened, and once it has taken in every replica there is
    // nothing left to open into, so it runs on as a band.  Over the backdrops, so the lanes do not
    // fade a stripe through it, and still under every timeline.
    backdrops: d => {
      let (column, point, replicas, span, ..) = d
      let (_, ends) = span
      let t = column("A", "a2")
      let lane = replicas.position(r => r == "A")
      let edge = replicas.len() - 1 - lane + 0.4
      let wash = red.transparentize(93%)
      line(
        point(t, lane),
        point(t + edge, lane - edge),
        point(t + edge, lane + edge),
        close: true,
        fill: wash,
        stroke: none,
      )
      rect(
        point(calc.min(t + edge, ends), lane - edge),
        point(ends, lane + edge),
        fill: wash,
        stroke: none,
      )
    },
    // Over the dot, under its label.
    marks: d => {
      let (mark, dot, mark-args, ..) = d
      let wash = red.transparentize(93%)

      circle(mark("A", "a2"), radius: dot * 3, stroke: red + 0.7pt)

      // Make the inners of the events have the same `wash` color of the future cone
      circle(..mark-args("S", 3), fill: wash)
      circle(..mark-args("S", 4), fill: wash)
      circle(..mark-args("S", 5), fill: wash)
      circle(..mark-args("A", 4), fill: wash)
      circle(..mark-args("A", 5), fill: wash)
      circle(..mark-args("C", 3), fill: wash)
    },
  ),
)
