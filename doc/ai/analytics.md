# Analytics and metrics

Version: 1.0.1. Read this to send bar events to an analytics service or to read the metrics of a bar.
The rules in `AI_GUIDE.md` apply here too.

## Analytics and metrics

```dart
void onBarEvent(FluentBarAnalyticsPayload payload) {
  analytics.log(payload.event.name, {
    'id': payload.item.id,
    'type': payload.item.type.name,
    ...?payload.metrics?.toMap(),
  });
}

FluentBar.addAnalyticsListener(onBarEvent);
FluentBar.removeAnalyticsListener(onBarEvent);
```

- Events (`FluentBarAnalyticsEvent`): `requested`, `queued`, `shown`, `dismissed`, `updated`,
  `ignoredDuplicate`, `queueOverflow`, `tapped`, `actionTapped`, `paused`, `resumed`, `relocated`,
  `progressCompleted`, `progressCanceled`, `progressFailed`.
- An event has getters for its group; use them to filter in a listener: `isLifecycle`
  (`requested`, `queued`, `shown`, `dismissed`), `isInteraction` (`tapped`, `actionTapped`),
  `isProgress` (the three `progress...` events), `isRejected` (`ignoredDuplicate`,
  `queueOverflow`), `isCountdown` (`paused`, `resumed`), and `hasMetrics` (`dismissed`,
  `queueOverflow`: `payload.metrics` is not null). `updated` and `relocated` belong to no group.
- A dismiss reason says who closed the bar: `isByUser` (`swipe`, `tap`, `actionButton`, `closeButton`, `accessibility`),
  `isByCode` (`manual`, `force`), `isAutomatic` (`timeout`, `dropped`). Every reason is in exactly
  one of the three: `metrics.dismissReason.isByUser`.
  ```dart
  FluentBar.addAnalyticsListener((payload) {
    if (payload.event.hasMetrics) analytics.log('bar_closed', payload.metrics!.toFlatMap());
  });
  ```
- `FluentBarMetrics` comes with `dismissed`, with `queueOverflow`, and in `onDismiss(item, metrics)`.
  Bars that never reached the screen (dropped by a full queue, closed or cleared while waiting)
  get metrics too, with `wasVisible: false`. Fields:
  - why it closed: `dismissReason` (`timeout`, `swipe`, `tap`, `actionButton`, `closeButton`, `accessibility`, `manual`, `force`,
    `dropped` = never shown because the queue was full), `timedOut`;
  - time: `visibleDuration` (in the `visible` state, zero if it never got there),
    `showingDuration` (appearing), `plannedDuration` (`null` for a persistent bar),
    `queuedDuration`, `pausedDuration`;
  - the user: `interactions` (`Map<FluentBarInteraction, int>`), `wasTapped`, `wasActionTapped`,
    `wasUntouched`, `hadAction` (the bar had a button - the denominator for a button click rate);
  - the bar: `id`, `typeName`, `preset`, `tags`, `position`, `wasForced`, `wasVisible`, `updateCount`
    (content / look / behavior changes and same-id re-shows; progress ticks through the
    controller are not counted), `progressOutcome` (`completed`, `failed`, `canceled`, or `null`).
  - `metrics.toMap()` gives snake_case keys: `visible_ms`, `showing_ms`, `planned_ms`, `queued_ms`,
    `paused_ms`, `dismiss_reason`, `timed_out`, `was_visible`, `was_forced`, `was_tapped`,
    `was_action_tapped`, `was_untouched`, `had_action`, `update_count`, `progress_outcome`,
    `interactions`, `position`, `type_name`, `preset`, `tags`, `id`.
- `FluentBarInteraction` values: `tap`, `action`, `hold`, `swipe`, `close`, `accessibility`;
  `metrics.countOf(interaction)` counts one; the flat map has an `interaction_<name>` key for each.
- A waiting bar removed by a close call, `clearQueue`, `dismissAndClear` or its owner gets one
  `dismissed` event and `onDismiss`, like a shown bar. A waiting bar pushed out of a full queue (by a
  forced bar, a lower `maxQueueLength`, a queue strategy) gets `queueOverflow`, then `dismissed` with
  reason `dropped`, and `onDismiss`. A bar that does not fit when shown gets only `queueOverflow`
  (`show()` returns `null`, no `onDismiss`). These events and callbacks come after the call that ended
  the bar has finished with the queues.
- `relocated` carries `payload.previousPosition`.
- **Sending to an analytics service: use `payload.toFlatMap()`** (or `metrics.toFlatMap()`), not
  `toMap()`. It returns `Map<String, Object>` with strings and numbers only: flags are `1` / `0`,
  interactions become `interaction_tap`, `interaction_action`..., absent values are left out, and
  the payload version adds `id`, `type_name`, `preset`, `tags`, `position`, `action_name`, `pause_reason`,
  `previous_position`. For an event with metrics the metrics value of `position` (where the bar closed) replaces the requested one. Firebase Analytics rejects booleans and nested maps, so `toMap()` does not fit.
- `paused` / `resumed` carry `pauseReason`: `manual`, `loading`, `action`, `touch`.
- Mute events with `FluentBarConfig(disabledAnalyticsEvents: {FluentBarAnalyticsEvent.requested})`
  or `patchConfig`; a muted event is not created at all. Suggest this when a listener only needs a
  few events (for example only `shown`, `actionTapped`, `dismissed`).
- When each event fires: `requested` on every `show()`; `queued` if the bar had to wait; `shown`
  when it appears; `updated` / `ignoredDuplicate` for a duplicate; `relocated` when a visible bar
  changes region; `tapped` / `actionTapped`; `paused` / `resumed`; `progressCompleted` /
  `progressFailed` / `progressCanceled`; `queueOverflow` when a bar is dropped; `dismissed` at the
  end, with metrics.
- Per-bar callbacks: `onShow`, `onTap`, `onDismiss`, and through `FluentBarCallbacks`:
  `onProgressCompleted`, `onProgressFailed`, `onProgressCanceled`.
