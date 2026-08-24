#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, vertical
#import "overlays.typ": diagram

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt, font: ("CaskaydiaMono NF", "Adwaita Mono", "Cascadia Code"))

// The diagram `overlays.typ` declares, turned, drawing and all.  One argument is the whole difference:
// the cone is stated in columns and lanes, so it turns with the lanes instead of having to be redrawn
// for them.
#lamport-diagram(..diagram, orientation: vertical)
