# lamportian-dramatis

Lamport diagrams for replicated systems: one timeline per replica, local events as dots on that timeline, and arrows for the messages that carry events from one replica to another.  The axis the timelines run along is logical time, in the sense of the clocks of [Time, Clocks, and the Ordering of Events in a Distributed System](https://lamport.azurewebsites.net/pubs/time-clocks.pdf); [`orientation`](https://lamportian-dramatis.github.io/reference#orientation) says which way it points, and the replicas stack across it.

> **Pre-1.0.**  This is young and still changing a lot.  Nothing here is a stable API until 1.0.0, so expect breaking changes between 0.x releases — argument names, defaults and the shape of what the helpers return are all still open.  A Typst import names an exact version, so nothing breaks under you: upgrading is always a deliberate edit.

![A diagram with each of its parts named: a sync between two replicas, a local event, a send and the receive it feeds, an elided stretch of time, and a timeline of its own](gallery/legend.png)

That is [`gallery/legend.typ`](gallery/legend.typ), a complete standalone document and one of the worked examples that ship with the package.  The callouts are drawn with [overlays](https://lamportian-dramatis.github.io/overlays); the diagram under them is just:

```typ
#import "@preview/lamportian-dramatis:0.3.0": lamport-diagram, sync, send, recv, replica, gap, below

#set page(width: 13cm, height: auto, margin: 0.4cm)
#set text(size: 10pt)

#lamport-diagram(
  replicas: (replica("R1", label:"replica 1"), replica("R2", below), "D"),
  events: (
    "R1": (
      sync("t0", displacement: 0.5cm)[sync],
      "event",
      gap,
      send("t1")[send],
    ),
    "R2": (
      sync("t0", displacement: 0.5cm),
      recv("t1")[receive],
      "A",
    ),
    "D": (),
    overlays: (..),
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

From a clone of the [repository](https://github.com/lamportian-dramatis/package):

```sh
make check     # compile every gallery example; silence means the library still works
make gallery   # recompile the README's images
make docs      # build the documentation into site/, ready to commit and push there
make preview   # watch the sources and serve the site at http://localhost:4983
make publish   # stage the package into a clone of github.com/typst/packages
make uninstall # stop shadowing the published package (see below)
```

The documentation is written in reStructuredText under [`docs/`](https://github.com/lamportian-dramatis/package/tree/main/docs), and built with [Sphinx](https://www.sphinx-doc.org/) and the [Furo](https://pradyunsg.me/furo/) theme.  Both are pinned in the Makefile and run through [`uvx`](https://docs.astral.sh/uv/), so there is nothing to install and the site you build is the site that gets published.  `make preview` watches the sources and serves them at [localhost:4983](http://localhost:4983), rebuilding on every save; `make docs` writes the finished HTML into `site/`.

`site/` is the [`lamportian-dramatis.github.io`](https://github.com/lamportian-dramatis/lamportian-dramatis.github.io) repository, carried here as a submodule, and holds nothing but that build — GitHub Pages serves it verbatim, which is what the `.nojekyll` file in it is for.  Clone with `--recurse-submodules`, or run `git submodule update --init` in an existing clone.  Commit and push inside `site/` first, then commit the moved submodule pointer here, so that a revision of this repository names the pages that went with it.

The gallery examples import the package by its published spec rather than by a relative path, which is what the Universe linter asks for.  So `check`, `gallery` and `publish` all first run `install`, which copies the working tree over `@preview/lamportian-dramatis:0.3.0` in your [local package directory](https://github.com/typst/packages?tab=readme-ov-file#local-packages).  That copy shadows whatever Typst Universe would otherwise serve, so run `make uninstall` when you are done working on the package.

## License

MIT — see [LICENSE](LICENSE).
