Guide
=====

Reading a diagram
-----------------

.. image:: gallery/legend.png
   :alt: A diagram with each of its parts named: a sync between two replicas, a local event, a send
         and the receive it feeds, an elided stretch of time, and a timeline of its own

In following is table, each mark is accompany by some *intended* meaning; but authors might choose
different semantics [#sync-semantics]_.

.. list-table::
   :header-rows: 1

   * - Mark
     - Meaning
   * - Solid dot
     - A local event, that happens at specific moment in the replica's timeline.
   * - Hollow dot
     - The replica receives events or messages from another replica.
   * - Small hollow dot
     - A replica sends events or messages to another.
   * - Hollow dot with a dot inside it
     - One end of a `sync`:func: where two replicas exchanges messages, possibly reaching some
       consensus.
   * - Dotted timeline
     - Elided time and or local events.  To convey *hidden*, not relevant events.

Conventions of the placements
-----------------------------

Time flows in the direction of the arrows of the timeline.  A `recv`:func: event is usually drawn a
centimeter further in the direction of time, so every message arrow follows the direction of time
without the diagram needing padding put in by hand.

Normally, labels are centred w.r.t their own mark and sit on the orientation's default position.
There are two exceptions:

- The lane's opening label on a *horizontal diagram*, which is nudged forward in time so it does sit
  next to the replica's name.

- The default position of `send`:func:, `sync`:func:, and `recv`:func: is computed to be on the
  other side of the incoming/outgoing arrow.

.. _columns-solver:

Columns are (mostly) solved, not authored
-----------------------------------------

You list each replica's local events in order and name the messages.  The layout then puts every
event in the earliest `column`:term: that keeps it after its predecessor on the same replica *and*
after the send of every message it receives.

Two things follow.  A diagram stays correct while you insert events -- nothing needs re-padding,
because no position along the time axis needs ever be written by hand.  And a receive that would
land before its own send is a causal cycle, which fails compilation.


Figures and cross-references
----------------------------

Attach the ``<label>`` *after* the call.  With a ``caption`` the function returns a ``figure``, so
the reference resolves to it and it numbers alongside the document's other figures.

.. typst-code::

   #lamport-diagram(
     caption: [`DeleteFile1` can be applied twice under concurrency],
     replicas: ("B", replica("A", below)),
     events: (
       "B": ([AddFile1], send("push"), [DeleteFile1], recv("pull", size: 0.8em)[now duplicated]),
       "A": (recv("push", displacement: none), [DeleteFile1], send("pull")),
     ),
   ) <fig-duplicated-delete>

   As @fig-duplicated-delete shows, ...



----

.. [#sync-semantics] As an example of semantics you might consider `sync`:func:.  This symbolism is
   actually a convenience over a **whole synchronization protocol**.  The protocol should provides
   the expected guarantees that both replicas will agree on the exchanged values.

   In practice a ``sync`` might really look like

   .. image:: gallery/sync-explained.png

   We have implemented a replicated system, in which *syncs* can be retried so that failure in the
   node after the server's HTTP handler committed, but before the node's DB commit happened can be
   achieved by simply executing the same SYNC protocol.
