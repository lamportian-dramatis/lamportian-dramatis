#import "@preview/lamportian-dramatis:0.3.0": lamport-diagram, sync, send, recv, replica, gap, event, message

#set page(width: 10cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

#let outline = color => (paint: color, thickness: 0.5pt, dash: "densely-dotted")
#let diagram = (
  replicas: ("node", "server"),
  events: (
    "node": (
      send("http-request", label-displacement: 20%)[HTTP POST],
      event(displacement: 30%, position: left)[Local DB update]
    ),
    "server": (
      recv("http-request", label-displacement: 30%)[
        HTTP atomic request\
        Update DB before returning
      ],
    )
  ),
  messages: (
    message(("server", "http-request"), ("node", -1), stroke: outline(luma(100)))[
        server already\
        committed its DB
    ],
  )
)

#lamport-diagram(..diagram)
