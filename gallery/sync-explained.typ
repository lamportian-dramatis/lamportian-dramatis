#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, sync, send, recv, replica, gap, event

#set page(width: 10cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

#let outline = color => (paint: color, thickness: 0.5pt, dash: "densely-dotted")
#let diagram = (
  replicas: ("node", "server"),
  events: (
    "node": (
      send("http-request", label-displacement: 20%)[HTTP POST],
      event(displacement: 30%)[Local DB update]
    ),
    "server": (
      recv("http-request", label-displacement: 30%)[
        HTTP atomic request\
        Update DB before returning
      ],
    )
  ),
  overlays: (
    foreground: d => {
      let (message-args, message-mid, draw , ..) = d
      let note = (at, ink, body) => draw.content(
        at,
        anchor: "west",
        padding: 0.2,
        text(size: 0.8em, fill: ink, body),
      )

      // The reply the sync hides, drawn the way the diagram draws a message of its own.
      let back-channel = (("server", "http-request"), ("node", -1))
      let response = message-args(..back-channel)
      let response-mark = (..response.at("mark"), fill: luma(150))
      draw.line(..response, stroke: outline(luma(150)), mark: response-mark)
      let mp = message-mid(..back-channel)
      note(mp, luma(100))[
        server already\
        committed its DB
      ]
    }
  )
)

#lamport-diagram(..diagram)
