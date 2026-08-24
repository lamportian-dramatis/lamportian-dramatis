# lamportian-dramatis

Lamport diagrams for replicated systems: one timeline per replica, local events as dots on that timeline, and arrows for the messages that carry events from one replica to another.  The axis the timelines run along is logical time, in the sense of the clocks of [Time, Clocks, and the Ordering of Events in a Distributed System](https://lamport.azurewebsites.net/pubs/time-clocks.pdf); [`orientation`](https://lamportian-dramatis.github.io/reference#orientation) says which way it points, and the replicas stack across it.

> **Pre-1.0.**  This is young and still changing a lot.  Nothing here is a stable API until 1.0.0, so expect breaking changes between 0.x releases — argument names, defaults and the shape of what the helpers return are all still open.  A Typst import names an exact version, so nothing breaks under you: upgrading is always a deliberate edit.

![A diagram with each of its parts named: a sync between two replicas, a local event, a send and the receive it feeds, an elided stretch of time, and a timeline of its own](gallery/legend.png)

That is [`gallery/legend.typ`](gallery/legend.typ), a complete standalone document and one of the worked examples that ship with the package.  The callouts are drawn with [overlays](https://lamportian-dramatis.github.io/overlays); the diagram under them is just:

```typ
#import "@preview/lamportian-dramatis:0.2.0": lamport-diagram, sync, send, recv, replica, gap, below

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt)

#lamport-diagram(
  replicas: (replica("R1"), replica("R2", below), "D"),
  events: (
    "R1": (sync("t0", displacement: 0.5cm)[sync], "event", gap, send("t1")[send]),
    "R2": (sync("t0", displacement: 0.5cm), recv("t1")[receive], "A"),
    "D": (),
  ),
)
```

## Documentation

The reference lives at **[lamportian-dramatis.github.io](https://lamportian-dramatis.github.io/)**, and is the place to look up any of it:

- **[Guide](https://lamportian-dramatis.github.io/guide)** — how to read the marks, how the columns are solved, and how a diagram becomes a cross-referenced figure.
- **[Reference](https://lamportian-dramatis.github.io/reference)** — every function and every argument: `lamport-diagram`, `orientation`, `replica`, `event`, `send`, `recv`, `sync`, `idle`, `gap`, the label sides and the palette.
- **[Overlays](https://lamportian-dramatis.github.io/overlays)** — drawing your own CeTZ into a diagram, addressing its own points, at a layer of your choosing.
- **[Gallery](https://lamportian-dramatis.github.io/gallery)** — every example that ships with the package, each a complete document, with its source.
- **[Changelog](https://lamportian-dramatis.github.io/changelog)** — what each release changed.

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

The gallery examples import the package by its published spec rather than by a relative path, which is what the Universe linter asks for.  So `check`, `gallery` and `publish` all first run `install`, which copies the working tree over `@preview/lamportian-dramatis:0.2.0` in your [local package directory](https://github.com/typst/packages?tab=readme-ov-file#local-packages).  That copy shadows whatever Typst Universe would otherwise serve, so run `make uninstall` when you are done working on the package.

## License

MIT — see [LICENSE](LICENSE).
