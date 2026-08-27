#import "@preview/iconify:0.5.3": icon, provide-icons
#import "@preview/lamportian-dramatis:0.3.0": lamport-diagram, sync, below, above, send, recv, replica, event, gap

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))
#provide-icons(json("lucide.json"))

#let wash = red.transparentize(93%)
#let diagram = arguments(
  replicas: (
    replica("vessel", above)[
      vessel
      #icon("lucide:ship", y: -0.5em, height: 1.5em)
    ],
    replica("server", below)[
      server
      #icon("lucide:server", y: -0.5em, height: 1.5em)
    ],
  ),
  events: (
    "vessel": (recv("download", label-displacement: -10%)[Download], event(label-position: below)[inspection], gap, send("upload")[Upload],),
    "server": (send("download"), gap, recv("upload"),),
  ),
)

#lamport-diagram(..diagram)
