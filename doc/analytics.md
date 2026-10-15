# Analytics

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Analytics and metrics

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/monitor.png" width="300" alt="The lifecycle, metrics and raw analytics of one bar"></p>

One listener receives everything that happens to every bar:

```dart
FluentBar.addAnalyticsListener((payload) {
  analytics.log(payload.event.name, {'id': payload.item.id, ...?payload.metrics?.toMap()});
});
```

| Event | When |
|---|---|
| `requested` | `show()` was called |
| `queued` | the bar had to wait |
| `shown` | the bar appeared |
| `updated` / `ignoredDuplicate` | a duplicate updated the bar / was discarded |
| `relocated` | a visible bar moved to the other region; `payload.previousPosition` says from where |
| `tapped` / `actionTapped` | the user tapped the bar / its button (which one: `action_name`, see below) |
| `paused` / `resumed` | the countdown stopped / went on (`payload.pauseReason`: `touch`, `action`, `loading`, `manual`) |
| `progressCompleted` / `progressFailed` / `progressCanceled` | the outcome of a progress |
| `queueOverflow` | the bar was dropped because the queue was full; `payload.metrics` is filled, reason `dropped` |
| `dismissed` | the bar closed, on screen or still in the queue; `payload.metrics` is filled |

**Metrics** come with `dismissed` and `queueOverflow` (and in the `onDismiss` callback of a bar).
`metrics.toMap()` has every field; `toFlatMap()` is the one analytics services accept.

| Question | Fields |
|---|---|
| Why did it close? | `dismissReason` (`timeout`, `swipe`, `tap`, `actionButton`, `closeButton`, `accessibility`, `manual`, `force`, `dropped`), `timedOut` |
| Who closed it? | `dismissReason.isByUser` (`swipe`, `tap`, `actionButton`, `closeButton`, `accessibility`), `.isByCode` (`manual`, `force`), `.isAutomatic` (`timeout`, `dropped`) |
| Did the user see it? | `wasVisible`, `visibleDuration`, `showingDuration`, `plannedDuration` (`null` for a persistent bar) |
| How long did it wait? | `queuedDuration`, `pausedDuration`, `wasForced` |
| What did the user do? | `interactions`, `wasTapped`, `wasActionTapped`, `wasUntouched`, `hadAction` |
| What happened to it? | `updateCount`, `progressOutcome` (`completed`, `failed`, `canceled`) |
| Which bar was it? | `id`, `typeName`, `preset`, `tags`, `position` |

Bars that never reached the screen report metrics too - dropped by a full queue, or closed while
waiting - with `wasVisible: false` and the time they spent in the queue.

`payload.toFlatMap()` and `metrics.toFlatMap()` return strings and numbers only (flags as `1` / `0`,
one `interaction_...` key per interaction), which is what Firebase Analytics and similar services
accept as event parameters:

```dart
FluentBar.addAnalyticsListener((payload) {
  analytics.logEvent(name: 'bar_${payload.event.name}', parameters: payload.toFlatMap());
});
```

**Events come in groups**, and an event knows its own:

| Getter | True for |
|---|---|
| `isLifecycle` | `requested`, `queued`, `shown`, `dismissed` |
| `isInteraction` | `tapped`, `actionTapped` |
| `isProgress` | `progressCompleted`, `progressFailed`, `progressCanceled` |
| `isRejected` | `ignoredDuplicate`, `queueOverflow` |
| `isCountdown` | `paused`, `resumed` |
| `hasMetrics` | `dismissed`, `queueOverflow`: `payload.metrics` is filled |

```dart
FluentBar.addAnalyticsListener((payload) {
  if (payload.event.isInteraction) analytics.log('bar_${payload.event.name}');
  if (payload.event.hasMetrics) analytics.log('bar_closed', payload.metrics!.toFlatMap());
  if (payload.metrics?.dismissReason.isByUser ?? false) analytics.log('bar_closed_by_user');
});
```

`updated` and `relocated` belong to no group.

**Name your buttons.** The label of a button is translated, so it is a poor key. Give the action
a stable name and it arrives as `action_name` in `payload.toFlatMap()`; the ready-made Cancel and
Retry buttons are `cancel` and `retry`:

```dart
FluentBar.info<void>('Order cancelled').withAction('Undo', analyticsName: 'undo_order').show();
```

**Turn off the events you do not need** (they are not created at all):

```dart
FluentBar.patchConfig((config) => config.copyWith(
  disabledAnalyticsEvents: {FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.paused, FluentBarAnalyticsEvent.resumed},
));
```

For one bar use its own callbacks instead: `.onShow(…)`, `.onTap(…)`, `.onDismiss((item, metrics) => …)`.

> **Demo:** [Monitor → Bars](https://rtfmko.github.io/fluent_bar/#/monitor/bars) (`monitor/bars`) · [Analytics & safety → Analytics stream](https://rtfmko.github.io/fluent_bar/#/analytics/stream) (`analytics/stream`) · [Global config → Analytics events](https://rtfmko.github.io/fluent_bar/#/config/analytics-events) (`config/analytics-events`)<br>
> **API:** [`FluentBarAnalyticsEvent`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarAnalyticsEvent.html) · [`FluentBarAnalyticsPayload`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarAnalyticsPayload-class.html) · [`FluentBarMetrics`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarMetrics-class.html)

## Errors

What happens when your code throws, every error type and how to send the reports to a crash
reporter: [Errors](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/errors.md).
