# Changing a bar after it is shown

Version: 1.0.0. Read this to change, find or close a bar that is already on screen.
The rules in `AI_GUIDE.md` apply here too.

## Changing a bar after it is shown

```dart
final entry = FluentBar.info<void>('Saving…').withId('save').persistent().show();

entry?.update(title: 'Almost there', message: 'Uploading attachments');
entry?.controller.updateContent(type: FluentBarType.success, message: 'Saved');
entry?.updateDuration(const Duration(seconds: 3), resetTimer: true);            // null = persistent
entry?.addDuration(const Duration(seconds: 5));
entry?.subtractDuration(const Duration(seconds: 2));                            // more than is left: a warning, nothing changes
entry?.update(clearTitle: true);                                                // remove the title
entry?.removeAction();                                                          // remove the button
entry?.makePersistent();                                                        // no countdown any more
entry?.patchBehavior((b) => b.copyWith(position: FluentBarPosition.bottom));    // change one setting
entry?.patchAppearance((a) => a.copyWith(backgroundColor: Colors.teal));        // change one setting
entry?.pause();  entry?.resume();
entry?.shake();  entry?.bounce();  entry?.pulse();  entry?.heartbeat(repeat: true);
entry?.close();

// Without the entry at hand:
FluentBar.find('save')?.controller.updateContent(message: 'Saved');
FluentBar.close('save');
```

Changing the type, theme or colors of a visible bar fades to the new look; text changes at once.
Changing the position of a visible bar moves the same bar: it fades in at the new place (it stays
`visible`), or, when the target region is busy and the strategy is `queueNext`, it plays its exit,
waits in that queue and appears again with the usual entrance.

**One rule for every update and every `copyWith`: an omitted argument (or `null`) keeps the value;
to remove a value use the `clear…` flag or the named method.**

| To… | Use | Not |
|---|---|---|
| change one behavior / look setting | `patchBehavior((b) => b.copyWith(…))`, `patchAppearance((a) => a.copyWith(…))` | `updateBehavior` / `updateAppearance` - they replace the whole object |
| replace all behavior / look settings | `controller.updateBehavior(behavior: …)`, `controller.updateAppearance(…)` | |
| remove the title | `update(clearTitle: true)` | `update(title: null)` - keeps it |
| remove the button | `removeAction()` (= `controller.updateActions(null)`) | |
| make a bar persistent | `makePersistent()` (= `controller.updateDuration(null)`) | |
| remove fields of a draft | `item.copyWith(clearTitle:, clearDuration:, clearPayload:, clearMeta:, clearActions:, clearProgressState:)` | passing `null` |

The entry has shortcuts for most of them; `updateContent` (with `type:`), `updateBehavior`,
`updateAppearance`, `setLoading` and `handleAction` exist only on `entry.controller`. Everything
works through `FluentBar.find(id)` too.

### Find and close

| To... | Call |
|---|---|
| get a shown or queued bar by id | `FluentBar.find(id)` → `FluentBarEntry<dynamic>?` |
| list bars | `FluentBar.activeItems`, `allQueue`, `mainQueue`, `bottomQueue` |
| close one bar | `FluentBar.close(id)` (returns `false` if there is none) or `entry.close()` |
| close the bar on screen | `FluentBar.closeActive()` |
| clear the queue and close the visible bars, animated | `FluentBar.closeAll()` |
| find / close the bars of one screen or feature | `FluentBar.findByTag(tag)`, `FluentBar.closeTag(tag)` (returns the count; removes queued ones too) |
| drop waiting bars only | `FluentBar.clearQueue()` |
| remove everything instantly | `FluentBar.dismissAndClear()` (use it in test `tearDown`) |

Any call into the library is safe from `initState`, `build` and `dispose` (for example
`FluentBar.close(id)` or `patchConfig` when a screen goes away): values change at once and
listeners are notified right after the frame. Do not wrap such calls in
`addPostFrameCallback` or `Future.microtask`.

Closing from code gives the dismiss reason `manual`. A bar with no `id` can only be reached through
the entry returned by `show()`.

Listen instead of polling: `FluentBarController` exposes `ValueListenable`s: `itemNotifier`,
`stateNotifier`, `remainingDurationNotifier`, `elapsedDurationNotifier`, `totalDurationNotifier`,
`remainingProgressNotifier` (1 → 0), `elapsedProgressNotifier` (0 → 1), `progressStateNotifier`,
`taskProgressNotifier`, `isActionExecutingNotifier`.
