# `overlay` and `underlay`

> **Status: proposed.**  Nothing on this page is implemented yet.  It is the API we agreed on before writing any of it, and it is here to be argued with while that is still cheap.

Two escape hatches for drawing arbitrary [CeTZ](https://typst.app/universe/package/cetz/) into a diagram, in the diagram's own coordinates, addressing the diagram's own points.

```typ
lamport-diagram(
  caption: none,
  replicas: (),
  events: (:),
  orientation: horizontal,
  underlay: none,
  overlay: none,
  ...
)
```

Each takes `none`, a bare CeTZ body, or a function of one argument — the *locator* — returning a CeTZ body:

```typ
overlay: { grid((0, 0), (8, -3)) }        // bare body, for when you need no points
overlay: d => circle(d.at("A", "bad"))    // a function, for when you do
```

Both are spliced into the diagram's own `cetz.canvas`, so a coordinate is a canvas centimetre and every CeTZ coordinate form — `rel:`, `to:`, anchors on your own named elements — works as it does anywhere else.  Both run inside the same `context` block the diagram uses, so `measure` is available.

## Layers

Bottom to top:

| | |
| --- | --- |
| 1 | **`underlay`** |
| 2 | message arrows and their labels |
| 3 | `sync` arrows and their labels |
| 4 | lane backdrops — the halos that erase an arrow crossing a lane |
| 5 | lane timelines, their marks and their labels |
| 6 | **`overlay`** |

`underlay` sits below the arrows rather than between them and the lanes.  The tempting slot is 3½, but the halo is five points of near-white along every lane, so anything drawn there gets a pale stripe washed through it at each lane.

One consequence to know about: a background band drawn in the `underlay` still picks up that faint stripe wherever a lane crosses it, because the halos are above it.  That reads as the lane being in front, which is the same depth story the arrows already tell — but it is worth a look at a render before committing to a heavy fill.

## Addressing a point

Every point on a lane is `(replica, id)`.  Ids only have to be unique *within their own lane*, which is what lets a `sync`'s two ends and a message's two ends share the name that pairs them:

```typ
d.at("A", "bad")        // an event, by the id it was given
d.at("S", "a-pushes")   // this end of the sync;  d.at("A", "a-pushes") is the other
d.at("C", "c-pushes")   // the send;  d.at("S", "c-pushes") is its recv
```

`send`, `recv` and `sync` already carry a name, and that name is their id.  A local `event` has none, so it takes one:

```typ
"A": ([`A.1`], event(id: "bad")[`A.2`], sync("a-pushes")),
```

Ids are opt-in on purpose.  The alternative — addressing an event by its position, `A.0`, `A.1`, … — would put back exactly the fragility that solving the columns removed: insert one event and every overlay below it silently points at the wrong dot.  An id you wrote survives the insert.

Two points on one lane may not share an id, and that is an error at compile time, not a silent win for whichever came first.

### By index

Where naming a one-off is not worth it, an integer addresses the lane positionally, **1-based**, counting *every* item in the lane's array including `gap` and `idle`:

```typ
d.at("A", 1)     // the lane's opening item
d.at("A", 3)
d.at("A", -1)    // the last item -- the one index that survives an insert
```

Ids are strings and indices are integers, so the two never need telling apart by hand.

## The locator

| | |
| --- | --- |
| `d.at(replica, id)` | The **coordinate** of that point's mark, including the sub-column `displacement` that leans its arrow.  Where to draw. |
| `d.col-of(replica, id)` | The **column** the solver put that point in, as an integer.  A moment in logical time, with no lane and no displacement attached. |
| `d.point(col, lane)` | The coordinate of a column on a lane.  `col` may be fractional, so `2.5` is halfway between two columns; `lane` is a replica id or its index. |
| `d.lane(replica)` | The two endpoints of that replica's drawn timeline, as `(start, end)` — where the line actually begins and ends, which is a nudge before the first column and a fraction of `col-gap` past the last mark. |
| `d.lanes` | The replica ids, in order. |
| `d.ncols` | How many columns the diagram was solved into. |

`at` and `col-of` differ by type, and that is the whole distinction.  You need the integer whenever what you are drawing spans lanes, because `at` bakes in the lane of the replica you asked about:

```typ
underlay: d => {
  let a = d.col-of("C", "c-reads")
  let b = d.col-of("A", "a-catches-up")
  rect(d.point(a, 0), d.point(b, -1), fill: yellow.transparentize(85%), stroke: none)
}
```

`d.at("C", "c-reads")` cannot start that rectangle: it sits on C's lane, not on the first one.  So the two compose — `col-of` gets the moment, `point` puts it on whichever lane you meant.

`col-of` is also what to reach for when you want to *reason* rather than draw.  `d.col-of("A", "x") == d.col-of("B", "y")` is "the solver found nothing ordering these two", which is a real question to ask of a Lamport diagram.

## Staying orientation-independent

`d.point(col, lane)` is stated in the diagram's own axes — columns of logical time, and lanes across them — so an overlay written in terms of it survives a flip from `horizontal` to `vertical`.  One written against raw `(x, y)` arithmetic does not.  Prefer:

```typ
overlay: d => line(d.point(2, "A"), d.point(2, "C"))         // flips cleanly
overlay: d => line((4, 0), (4, -3))                          // does not
```

`d.lane` hands back two plain coordinates rather than trying to be clever about sides, for the same reason a caller usually wants to nudge them:

```typ
underlay: d => {
  let (s, e) = d.lane("B")
  line((rel: (0, -0.12), to: s), (rel: (0, -0.12), to: e), stroke: (dash: "dashed"))
}
```

The nudge is not optional decoration — a line drawn exactly on a lane is covered by the lane's own stroke, halo or no halo.

## Errors

- An unknown replica id, an unknown point id, or an index past the end of a lane fails compilation, naming what was asked for and what that lane actually holds.
- Two points on one lane sharing an id fails compilation.
- An `overlay` or `underlay` that is neither `none`, a function of one argument, nor a CeTZ body fails compilation.

## Worked example

```typ
#lamport-diagram(
  replicas: (replica("S", above, color: luma(0)), replica("A", below), replica("C", below)),
  events: (
    "S": (sync("boot"), send("c-reads"), sync("a-pushes"), recv("c-pushes"), sync("a-catches-up")),
    "C": (recv("c-reads"), event(id: "c1")[`C.1`], send("c-pushes")),
    "A": ([`A.1`], sync("boot"), event(id: "a2")[`A.2`], sync("a-pushes"), sync("a-catches-up")),
  ),
  underlay: d => {
    // The window in which the two clients disagree.
    let from = d.col-of("C", "c1")
    let to = d.col-of("A", "a-catches-up")
    rect(
      d.point(from, 0),
      d.point(to, -1),
      fill: red.transparentize(93%),
      stroke: none,
    )
  },
  overlay: d => {
    circle(d.at("A", "a2"), radius: 0.3, stroke: red + 0.7pt)
    line(
      (rel: (0, 0.9), to: d.at("A", "a2")),
      d.at("A", "a2"),
      stroke: red,
      mark: (end: "stealth"),
    )
  },
)
```

## Open questions

- Is a `d.band(from, to)` convenience — the rectangle above, across every lane — worth having, or is `point` twice clear enough?
- Should the locator also expose the *labels* rather than only the marks, so an overlay can box or point at one?  That needs each label's laid-out size, which the diagram measures anyway.
