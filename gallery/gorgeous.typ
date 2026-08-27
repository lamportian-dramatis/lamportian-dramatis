#import "@preview/lamportian-dramatis:0.3.0": lamport-diagram, sync, below, above, send, recv, replica

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

// Every argument but the orientation, so that `vertical.typ` can draw this very diagram the other way
// about by importing this and overriding that one argument.  The sides named here -- `above` for S and
// `below` for the other two -- are the ones a horizontal diagram has room for; a vertical diagram has
// none for them and drops them back to its own default, which is what lets one declaration serve both.
#let diagram = arguments(
  replicas: (
    replica("S", above, color: luma(0)),
    replica("A", below),
    replica("C", below),
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

#lamport-diagram(..diagram)
