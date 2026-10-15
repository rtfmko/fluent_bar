# Queue, priority, duplicates

Version: 1.0.0. Read this for several bars at once: the queue, priorities, forced bars, duplicates, tags.
The rules in `AI_GUIDE.md` apply here too.

## Queue, priority, duplicates

```dart
FluentBar.error<void>('Connection lost').withPriority(FluentBarPriority.critical).show();
FluentBar.error<void>('Session expired').forced().show();              // replaces the bar on screen
FluentBar.forceItemFromQueue(id: 'sync');
FluentBar.updateItemPriority(id: 'sync', newPriority: FluentBarPriority.high);
```

**Regions.** Two regions, each shows one bar at a time and has its own queue: top (`main` in the
API; positions `top`, `left`, `right`, `center`) and bottom (`bottom`). A top bar and a bottom bar
can be visible together; two bars of one region never are. `enableMultiRegion: false` = one queue
and one visible bar for the whole screen. The region follows `position` (bar, type, config), not
`positionBuilder`, which only moves where the bar is drawn.

**Order of waiting bars** (`defaultQueueStrategy`):

- `SmartQueueStrategy` (default): forced bars first, then by priority (`critical` > `high` >
  `normal` > `low`), then in the order of requests.
- `FifoQueueStrategy`: order of requests, priorities ignored, forced bars first.
- `LifoQueueStrategy`: newest first.
- Your own `FluentBarQueueStrategy` (example below).

What to expect:

- The next bar appears when the bar in its region closes. Nothing is stacked.
- A forced bar closes the bar on screen (dismiss reason `force`) and appears at once; only another
  forced bar makes it wait. A forced bar is never dropped.
- `maxQueueLength` is per region (1-100, default 15). A bar that does not fit is dropped: `show()`
  returns `null`, the error handlers get a warning, analytics gets `queueOverflow`.
- Bars requested before the overlay exists wait in the queue.

**Duplicates.** "The same bar" = what `duplicateComparator` says if it is set; otherwise the same
`id`; bars without an `id` are the same when they are fully equal. Both regions are searched (the
visible bar and the queue), so the same `id` with another position updates and moves the bar.
Bars with different payload types are never duplicates.

The policy of the incoming bar (`.withDuplicatePolicy()` → type → `defaultDuplicatePolicy`) decides:

| Policy | Result |
|---|---|
| `update` (default) | the existing bar takes the new content, its countdown goes on; event `updated` |
| `updateAndResetTimer` | the same, and the countdown starts over |
| `ignore` | the new bar is discarded; event `ignoredDuplicate`. A changed progress still gets through |
| `allow` | always a separate bar; only an unfinished progress with the same `id` is continued |

- Both bars carry progress → only progress, texts and type are taken; button, callbacks, look stay.
- The existing bar is still queued → merged in the queue: the higher priority wins, forced if either is.
- A visible bar that changes region meets `FluentBarRelocationStrategy`: `queueNext` (default: wait
  first in the new queue), `forceReplace`, `ignore`.
- Look at the queue: `FluentBar.activeItems`, `mainActiveItem`, `bottomActiveItem`, `lastActiveItem`,
  `allQueue`, `mainQueue`, `bottomQueue`, the `…QueueLength` getters and, for widgets, the
  `allQueueLengthNotifier` / `mainQueueLengthNotifier` / `bottomQueueLengthNotifier` listenables.
  "main" is the top region.

```dart
// Your own order: `onEnqueue` returns the new queue (entries left out are dropped),
// `onDequeue` returns the next bar and the rest.
class NewestFirstStrategy extends FluentBarQueueStrategy {
  const NewestFirstStrategy();

  @override
  QueueOperationResult onEnqueue({
    required List<FluentBarEntry<dynamic>> queue,
    required FluentBarEntry<dynamic> incoming,
    required FluentBarConfig config,
  }) => QueueOperationResult(queue: [incoming, ...queue].take(config.maxQueueLength).toList(), shouldForce: incoming.isForce);

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({
    required List<FluentBarEntry<dynamic>> queue,
    required FluentBarConfig config,
  }) => queue.isEmpty ? (null, queue) : (queue.first, queue.sublist(1));
}

FluentBar.patchConfig((c) => c.copyWith(defaultQueueStrategy: const NewestFirstStrategy()));
```

To compare priorities in a strategy use `entry.item.behavior.priority?.weight` (`low` < `normal` <
`high` < `critical`); `entry.sequence` is the creation order.

### Bars that belong to a screen

Bars are drawn above every navigator and survive `pop` and tab switches. When a bar makes sense
only on one screen, tag it and let the screen own the tag:

```dart
FluentBarOwner(tag: 'checkout', child: const CheckoutBody());          // in the screen's build

FluentBar.error<void>('Card declined').withTag('checkout').show();     // wherever the bar is shown
```

- `FluentBarOwner` closes every bar with its tag (shown and queued) when it leaves the tree. With
  several owners of one tag the bars are closed when the last one is gone.
- The tag is always set by hand with `.withTag`; `FluentBarOwner` does not tag bars.
- A tag is not a priority: a forced or higher-priority bar still replaces a tagged one.
- Do not tag bars that should survive the screen ("Saved", "Sent").
- `item.tags` is a `Set<String>`; `metrics.tags` and `tags` (comma-separated) in `toFlatMap()`.
