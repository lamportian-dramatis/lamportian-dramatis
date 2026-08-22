# lamportian-dramatis

Lamport diagrams for replicated systems: one timeline per replica, local events as dots on that timeline, and arrows for the messages that carry events from one replica to another.  The axis the timelines run along is logical time, in the sense of the clocks of [Time, Clocks, and the Ordering of Events in a Distributed System](https://lamport.azurewebsites.net/pubs/time-clocks.pdf); [`orientation`](#orientation) says which way it points, and the replicas stack across it.

> **Pre-1.0.**  This is young and still changing a lot.  Nothing here is a stable API until 1.0.0, so expect breaking changes between 0.x releases — argument names, defaults and the shape of what the helpers return are all still open.  A Typst import names an exact version, so nothing breaks under you: upgrading is always a deliberate edit.

![A fictional scenario showing a convergence bug in a fictional system](gallery/gorgeous.png)

That is [`gallery/gorgeous.typ`](gallery/gorgeous.typ), a complete standalone document and the worked example that ships with the package:

```typ
#import "@preview/lamportian-dramatis:0.1.0": lamport-diagram, sync, below, above, send, recv, replica

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt)

#lamport-diagram(
  replicas: (
    replica("S", above, color: luma(0)),
    replica("A", below),
    replica("C", below),
  ),
  events: (
    "S": (
      sync("boot"),
      send("c-reads"),
      sync("a-pushes"),
      recv("c-pushes"),
      sync("a-catches-up"),
    ),
    "C": (
      recv("c-reads"),
      [`C.1`],
      send("c-pushes"),
    ),
    "A": (
      [`A.1`],
      sync("boot"),
      [`A.2`],
      sync("a-pushes"),
      sync("a-catches-up")[Bug: A #sym.eq.not C],
    ),
  ),
)
```

## Columns are (mostly) solved, not authored

You list each replica's local events in order and name the messages.  The layout then puts every event in the earliest column that keeps it after its predecessor on the same replica *and* after the send of every message it receives.

Two things follow.  A diagram stays correct while you insert events — nothing needs re-padding, because no position along the time axis was ever written by hand.  And a receive that would land before its own send is a causal cycle, which fails compilation instead of quietly drawing a backwards arrow.

## Reading a diagram

| Mark | Meaning |
| --- | --- |
| Solid dot | A purely local step. |
| Hollow dot | The replica touches the network here; the attached arrow says in which direction, and a two-headed one says both. |
| Small hollow dot | A send, drawn smaller than the receive it feeds, so the two ends of a message stay tellable apart without tracing the arrow.  The two ends of a `sync` are the same size, because neither of them is the sender. |
| Dotted timeline | Elided time — events the diagram does not show. |

A receive is drawn by default a centimetre further along in time than its send, so every message arrow follows the direction of time without the diagram needing padding put in by hand.  `recv(..., displacement: none)` puts it in the send's own column instead, for an arrow that runs straight across the lanes.

Labels are centred on their own mark and sit on the orientation's default side — `above` a horizontal timeline, `right` of a vertical one — except a lane's opening label, nudged forward in time so it does not read as belonging to the replica name just before it.  `event` overrides both for one event, `replica` for a whole lane.

Arrows are drawn first and everything else on top, so an arrow that crosses a lane it has no endpoint on passes *under* that lane rather than striking through it.  A lane erases across the whole strip it occupies, marks included: each mark clears the same annulus that an arrow landing on it would stop short of, so a passing arrow breaks around a dot instead of running into its edge.  Labels knock out the arrow behind them for the same reason.

## Reference

### `lamport-diagram`

```typ
lamport-diagram(
  caption: none,
  replicas: (),
  events: (:),
  orientation: horizontal,
  col-gap: 2.0,
  row-gap: 1.5,
  text-size: 0.62em,
  dot: 0.095,
  message-stroke: 0.9pt + luma(110),
)
```

`replicas` fixes the lane order — top to bottom in a horizontal diagram, left to right in a vertical one.  Each entry is an id string, a [`replica`](#replica) — which also carries that lane's event defaults — or a bare dictionary of the same fields.

`events` maps each replica id to that replica's local history in order.  An entry is bare content or a bare string for a local event, or one of [`event`](#event), [`send`](#send-and-recv), [`recv`](#send-and-recv), [`sync`](#sync), [`idle`](#idle) and [`gap`](#gap).  Every replica must have an entry, and every entry must name a declared replica.

`orientation` says which way logical time runs; see [`orientation`](#orientation) below.

With a `caption` the result is a `figure`; without one it is the bare drawing, to place inside a `figure` of your own.  `col-gap` is the spacing between two columns of logical time and `row-gap` that between two lanes, both in canvas centimetres, and they are the knobs for a diagram that reads too cramped or too sparse.

### `orientation`

```typ
horizontal   // = rightwards
vertical     // = downwards
rightwards   leftwards   downwards   upwards
```

Which way logical time runs.  `rightwards` and `leftwards` lay the timelines out as rows and stack the replicas downwards; `downwards` and `upwards` lay them out as columns and stack the replicas rightwards.  `horizontal` and `vertical` are the two that need no thinking about, and are `rightwards` and `downwards` under a shorter name.  These are plain strings, so `orientation: "vertical"` works without importing anything.

The orientation decides which sides a label may sit on, and which one it sits on by default:

| Orientation | Sides | Default |
| --- | --- | --- |
| `horizontal`, `rightwards`, `leftwards` | `above`, `below` | `above` |
| `vertical`, `downwards`, `upwards` | `left`, `right` | `right` |

A side the orientation has no room for — `above` on a vertical diagram, `left` on a horizontal one — is *not* an error: it is dropped back to that default and otherwise ignored, so flipping a finished diagram from horizontal to vertical stays one edit rather than a compile error on every lane that named a side.  It passes in silence, which is not the ideal: the ideal is a compiler warning, and Typst gives user code no way to raise one.  Printing the complaint into the document instead would put it in front of the reader rather than the author, which is worse than saying nothing.

![The same scenario as above, drawn vertically](gallery/vertical.png)

That is [`gallery/vertical.typ`](gallery/vertical.typ).

### `replica`

```typ
replica(name, ..defaults)
```

A replica lane, and the defaults the local events on it fall back on.  `name` is the id that the `events` dictionary keys on.

- `label` — what the diagram prints for the lane.  Defaults to `name`.
- `color` — the lane's colour.  Defaults to the next entry of `default-palette`, cycled over `replicas` in order.
- `position` — the side of the timeline this lane's event labels sit on: `above` or `below` on a horizontal diagram, `left` or `right` on a vertical one.
- `size` — the text size of this lane's event labels.
- `displacement` — how far along the timeline this lane's event labels slide off their own dot.
- `first-displacement` — the same, for the lane's opening event, the one that would otherwise crowd the replica name.

`label`, `color` and `position` may also be given positionally, in any order: they are told apart by type, so `replica("A", below, red)` and `replica("B", red, below)` are the same lane.  The rest must be named.

None of these defaults reach a `send` or `recv` label: those keep their own arguments, and their side is chosen to stay clear of the message arrow.

### `event`

```typ
event(..args)
```

A local event on a replica's timeline.  Its body is the label — content or a plain string.

- `position` — the side of the timeline the label sits on: `above` or `below` on a horizontal diagram, `left` or `right` on a vertical one.
- `size` — the label's text size.
- `displacement` — slides the label along the timeline, out of being centred on its own dot.  A ratio is taken against the label's own extent along that timeline — its width when the timelines are rows, its height when they are columns — so `+50%` leaves the label's trailing edge over the dot and `-50%` its leading edge, while a length is an exact offset and `0` (or `0%`) centres it.
- `width` — wraps the label to a fixed width instead of letting it run along the timeline on one line, which is what keeps a long label from crowding its neighbours.  **Named only**: a bare length is read as a `displacement`, that being the far commoner one to reach for.  The box is centred on the mark like any other label, and its contents are left to you — wrap the body in `align(center, ..)` if centred lines read better than the ragged right edge.
- `halo` — how far the label's backdrop reaches past the label's own box, which is what breaks an arrow crossing the lane so it does not crowd the glyphs.  `auto` (the default) matches the reach of the disc under a mark, so a label and a dot break an arrow by the same amount; a length sets an exact reach, and `none` drops the backdrop, letting whatever is behind show through.

The dot itself never moves: it is the event's place in time, which the layout solves for.

Arguments are told apart by type, so they may come in any order and every one of them is optional: `event(below, +50%)[AddFile1]` and `event(+50%, below, "AddFile1")` are the same event.  For the common case of a label and nothing else, bare content or a bare string in an `events` array is shorthand, so `[AddFile1]`, `"AddFile1"` and `event[AddFile1]` are the same event too.

### `send` and `recv`

```typ
send(name, ..args)
recv(name, ..args)
```

The points where the message `name` leaves one replica and is applied on another.  Exactly one `send` and one `recv` must exist for each name.

An optional label for the point goes positionally — `send("push")[pushed]`, `recv("pull")[now duplicated]` — or as `body`, with `size` setting its text size and `at` overriding the side it sits on.

Both take `displacement`, which nudges the point off the column it is solved into, in either direction.  A ratio is taken against the column gap.  Only the defaults differ:

- on a `recv` it is `1cm` — how far past its `send` in time the point lands whenever nothing on its own replica pushes it further, and enough to lean the arrow forward.  `recv(..., displacement: none)` leaves it on its column, drawing an arrow straight across the lanes when the receiving replica has nothing else competing for that column.
- on a `send` it is `none` — a send sits on its own column unless you say otherwise, since it is the receive that leans a message forward.  Reach for it to tilt an arrow away from whatever a straight run across the lanes would otherwise cross, or to separate two sends the solver put in one column.

`send` also takes:

- `label` — labels the arrow itself rather than the point, and keeps its own styling.
- `delay` — the minimum number of columns the matching `recv` is pushed forward.  `0` (the default) leaves the two in one column, where the receive's own `displacement` is what leans the arrow forward; `1` or more buys the message a whole column of flight.

The nudge is a drawing offset the column solver knows nothing about, so a negative one wide enough to put a point visually behind its own counterpart does *not* trip the causal-cycle check.  It is equally outside what the drawing sizes itself to, so a displacement large enough to push a bodiless mark left of where its lane starts will leave it overhanging the replica name.

### `sync`

```typ
sync(name, ..args)
```

One end of a two-way exchange.  In a single round trip each side gives the other the events it lacks, so both ends come out of the exchange holding the same events — which is not the same as holding the same state, so each end takes its own label.  A `send`/`recv` pair is the one-way message by comparison.

Exactly two `sync` points must carry the same name, and they must sit on two different replicas.  The pair is drawn as one arrow with a head at each end, and the two ends share a column: neither side can finish the exchange before the other one starts it.  A name cannot be both a `sync` and a `send`/`recv` message.

An optional label for the point goes positionally — `sync("push")[rolled back]` — or as `body`, with `size` setting its text size and `at` forcing the side the label sits on.  `label` instead labels the arrow itself; either end may carry it, and the first one given wins.  `displacement` nudges this end off the shared column, which tilts the arrow away from whatever a straight run across the lanes would otherwise cross; it is a drawing offset and says nothing about the order.

```typ
#lamport-diagram(
  replicas: ("Client A", replica("Server", below), replica("Client B", below)),
  events: (
    "Client A": ([Edit], sync("first", label: "round trip"), idle(2), sync("third")[has both edits]),
    "Server": (sync("first"), sync("second"), idle(1), sync("third")),
    "Client B": (idle(1), [Edit], sync("second")[has both edits]),
  ),
)
```

### `idle`

```typ
idle
idle(n)
```

Spacing to convey idle time passing: `n` columns of ordinary timeline with nothing drawn on them.  The specific semantics are for the author to explain.  The solver counts them, so the next event on this lane lands `n` columns later.

Usable bare or called, so `idle`, `idle()` and `idle(2)` are the same thing: two columns is enough for the stretch to read as a pause rather than as the ordinary spacing between two events.

`gap` is the sibling that *shows* the stretch, with dots, for time the diagram elides; `idle` shows nothing, because nothing happened.

### `gap`

```typ
gap
gap(size)
```

Elided time: a stretch of dotted timeline standing for events the diagram does not show, taking one column of its own.  The size is how much of that column the dots span — `"small"`, `"medium"` (the default) or `"large"`, or a length or a ratio of the column gap for an exact span, which past a full column runs into the neighbouring marks.

Usable bare or called, so `gap`, `gap()` and `gap("medium")` are the same thing.

### `above`, `below`, `left` and `right`

`above` and `below` are `top` and `bottom` under names that read better for a diagram of one horizontal line per replica, and they *are* those same values, so either spelling works wherever a side is asked for.  `left` and `right` are the built-in alignments of those names, re-exported for the vertical orientations so that one import line covers every side a diagram may ask for.

### `default-palette`

The lane colours, cycled over `replicas` in order.  Override per replica with `replica("A", red)`.

## Figures and cross-references

Attach the `<label>` *after* the call.  With a `caption` the function returns a `figure`, so the reference resolves to it and it numbers alongside the document's other figures.

```typ
#lamport-diagram(
  caption: [`DeleteFile1` can be applied twice under concurrency],
  replicas: ("B", replica("A", below)),
  events: (
    "B": ([AddFile1], send("push"), [DeleteFile1], recv("pull", size: 0.8em)[now duplicated]),
    "A": (recv("push", displacement: none), [DeleteFile1], send("pull")),
  ),
) <fig-duplicated-delete>

As @fig-duplicated-delete shows, ...
```

## Dependencies

Drawing is done with [CeTZ](https://typst.app/universe/package/cetz/) 0.5.2.  The minimum Typst compiler is 0.14.0.

## Development

From a clone of the [repository](https://github.com/mvaled/lamportian-dramatis):

```sh
make check     # compile every gallery example; silence means the library still works
make gallery   # recompile the README's images
make docs      # refresh the images the documentation site serves
make publish   # stage the package into a clone of github.com/typst/packages
make uninstall # stop shadowing the published package (see below)
```

The documentation site at [lamportian-dramatis.github.io](https://lamportian-dramatis.github.io/) is the `docs/` submodule — the [`lamportian-dramatis.github.io`](https://github.com/lamportian-dramatis/lamportian-dramatis.github.io) repository, which GitHub Pages builds with its own Jekyll.  Clone with `--recurse-submodules`, or run `git submodule update --init` in an existing clone.  Prose is edited in place under `docs/` and committed there; `make docs` is what carries the gallery images across.  Commit the moved submodule pointer here too, so that a revision of this repository names the documentation that went with it.

The gallery examples import the package by its published spec rather than by a relative path, which is what the Universe linter asks for.  So `check`, `gallery` and `publish` all first run `install`, which copies the working tree over `@preview/lamportian-dramatis:0.1.0` in your [local package directory](https://github.com/typst/packages?tab=readme-ov-file#local-packages).  That copy shadows whatever Typst Universe would otherwise serve, so run `make uninstall` when you are done working on the package.

## License

MIT — see [LICENSE](LICENSE).
