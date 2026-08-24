#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, vertical
#import "gorgeous.typ": diagram

#set page(width: 8cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

// The diagram `gorgeous.typ` declares, turned.  One argument is the whole difference between the two
// pictures: the timelines lay out as columns, the replicas stack rightwards, and every label takes a
// side that a vertical lane has room for.
#lamport-diagram(..diagram, orientation: vertical)
