#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, sync, left, right, send, recv, replica, vertical

#set page(width: 8cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

#lamport-diagram(
  orientation: vertical,
  replicas: (
    replica("S", color: luma(0)),
    replica("A"),
    replica("C"),
  ),
  events: (
    "S": (
      sync("boot")[Gets A.1],
      send("c-reads"),
      sync("a-pushes"),
      recv("c-pushes"),
      sync("a-catches-up"),
    ),
    "C": (
      recv("c-reads"),
      "C.1",
      send("c-pushes"),
    ),
    "A": (
      "A.1",
      sync("boot"),
      "A.2",
      sync("a-pushes"),
      sync("a-catches-up")[Bug: A $!=$ C],
    ),
  ),
)
