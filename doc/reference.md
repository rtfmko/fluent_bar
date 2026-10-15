# Reference

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Reference

Everything public, by where you meet it. The [API reference](https://pub.dev/documentation/fluent_bar/latest/)
has the signatures and an example for each member.

<details>
<summary><b>FluentBar</b> - the static entry point</summary>

| Group | Members |
|---|---|
| Set up | `initialize`, `updateConfig`, `patchConfig`, `currentConfig`, `configNotifier` |
| Show now (returns the entry) | `show`, `showInfo`, `showSuccess`, `showWarning`, `showError`, `showCustom`, `showSnack`, `showToast`, `showBanner`, `showLoading`, `showItem` |
| Make a draft for a chain | `info`, `success`, `warning`, `error`, `custom`, `snack`, `toast`, `banner`, `loading` |
| A Future | `future` |
| Find | `find`, `findByTag`, `activeItems`, `mainActiveItem`, `bottomActiveItem`, `lastActiveItem` |
| Close | `close`, `closeTag`, `closeActive`, `closeAll`, `clearQueue`, `dismissAndClear` |
| The queue | `allQueue`, `mainQueue`, `bottomQueue`, `allQueueLength`, `mainQueueLength`, `bottomQueueLength`, `allQueueLengthNotifier`, `mainQueueLengthNotifier`, `bottomQueueLengthNotifier`, `forceItem`, `forceItemFromQueue`, `updateItemPriority` |
| Insets measured by the inset widgets | `measuredTopInset`, `measuredBottomInset` |
| Listeners | `addAnalyticsListener`, `removeAnalyticsListener`, `addErrorHandler`, `removeErrorHandler` |

`FluentBarType.guard(type)` returns the type wrapped so that a getter that throws gives a default
instead. The library does it itself; use it in your own builder or listener that reads a type it
did not create: `FluentBarType.guard(entry.item.type).name`.

Widgets: `FluentBarScope` (the overlay), `FluentBarTopInset` and `FluentBarBottomInset` (keep bars clear of
the app bar and the bottom navigation), `FluentBarOwner` (closes the bars of a screen),
`FluentBarCloseButton`, `FluentBarTaskProgressWidget` and `FluentBarProgressLabel` (standard parts for
your own content builder).

"main" is the top region (positions `top`, `left`, `right`, `center`).

</details>

<details>
<summary><b>A shown bar</b> - FluentBarEntry and FluentBarController</summary>

`show()` returns a `FluentBarEntry<T>`: `entry.item` is the current content, `entry.controller`
changes it. The same bar is reachable later with `FluentBar.find(id)`. Most controller methods
also exist on the entry as shortcuts (`entry.pause()` is `entry.controller.pause()`).

| I want to... | On the entry | On the controller |
|---|---|---|
| Change texts, payload | `update(title:, message:, payload:, clearTitle:)` | `updateContent(...)` - also takes `type:` |
| Change one behavior / look setting | `patchBehavior`, `patchAppearance` | the same |
| Replace all behavior / look settings | controller only | `updateBehavior`, `updateAppearance` |
| Change or remove the button | `updateActions`, `removeAction` | the same |
| Change the lifetime | `updateDuration`, `addDuration`, `subtractDuration`, `makePersistent` | the same |
| Stop and continue the countdown | `pause`, `resume` | the same |
| Update progress | `updateValue`, `updateFraction`, `updateBytes`, `updateProgress` | `updateProgress` |
| Finish progress | `completeProgress`, `failProgress`, `cancelProgress` | the same |
| Draw attention | `shake`, `bounce`, `pulse`, `heartbeat`, `customEffect`, `triggerEffect` | the same |
| Put the bar into a loading state | controller only | `setLoading(isLoading:)` |
| Run an action like the button does | controller only | `handleAction(onPressed:, closeOnAction:)` |
| Show it out of turn | `force` (and `isForce` to check) | `force` |
| Close it | `close` | `close` |

Values to listen to (`ValueListenable`s on the controller) instead of polling:

| Listenable | Value |
|---|---|
| `itemNotifier` | the current `FluentBarItem` |
| `stateNotifier` | the [lifecycle](behavior.md#lifecycle) state |
| `remainingDurationNotifier`, `elapsedDurationNotifier`, `totalDurationNotifier` | the countdown as durations |
| `remainingProgressNotifier` (1 → 0), `elapsedProgressNotifier` (0 → 1) | the countdown as a fraction |
| `progressStateNotifier`, `taskProgressNotifier` | the progress state / its 0...1 value |
| `isActionExecutingNotifier` | whether an action handler runs or the bar is loading |

The entry also has `sequence`, the creation order (useful in a custom queue strategy).

</details>

<details>
<summary><b>A draft</b> - FluentBarItem, the chain and its parts</summary>

A `FluentBarItem<T>` is an immutable description of a bar; `T` is the type of its `payload`.
`FluentBar.info(...)` and friends create one, the `.with...()` chain returns changed copies.

| Field | Meaning | Chain |
|---|---|---|
| `id` | lets you find, update and de-duplicate the bar | `.withId()` |
| `uuid` | always set and unique; the identity of a bar without an `id` | - |
| `type` | info / success / warning / error / your own | chosen by the factory, `updateContent(type:)` later |
| `title`, `message` | the texts | `.withTitle()` |
| `duration`, `isPersistent` | the lifetime | `.withDuration()`, `.persistent()` |
| `payload` | your typed data, handed back in `onTap` and in the action | `.withPayload()` |
| `meta` | free-form data for analytics and for a custom duplicate rule | `.withMeta()` |
| `preset` | a label for logs (`snack`, `toast`, or your own) | `.withPreset()` |
| `tags` | labels that group bars, to close them together | `.withTag()`, `.withTags()` |
| `progressState` | the progress of a task | `.withProgress()`, `.withLinearProgress()`, `.withCircularProgress()` |
| `behavior` | where, how long, which gestures: `FluentBarBehavior` | `.at...()`, `.swipeable()`, `.withPriority()` ... |
| `appearance` | how it looks: `FluentBarAppearance` | `.withTheme()`, `.withIcon()`, `.withBackground()` ... |
| `actions` | the button: `FluentBarActions` | `.withAction()`, `.withCancelButton()` |
| `callbacks` | per-bar hooks: `FluentBarCallbacks` | `.onShow()`, `.onTap()`, `.onDismiss()` |

Parts that have no chain method are set through the objects themselves:

- `FluentBarActions`: `label` or `child`, `onPressed`, `closeOnAction`, `analyticsName`, `removeWhenProgressEnds`, `builder`, `throttleDuration`,
  `maxActionLines`, `actionOverflow`, `actionLoaderColor`, `actionLoadingWidget`.
- `FluentBarCallbacks`: `onShow`, `onTap`, `onDismiss`, `onProgressCompleted`, `onProgressFailed`,
  `onProgressCanceled`, and custom haptics `haptic`, `progressCompletedHaptic`.
- `FluentBarAppearance` text and layout: `maxTitleLines`, `maxMessageLines`, `titleOverflow`,
  `messageOverflow`, `titleTextAlign`, `messageTextAlign`, `actionTextAlign`, `iconColor`,
  `iconSize`, `constraints`, `actionsConstraints`. The rest is in the table under
  [Overriding settings](settings.md#overriding-settings).
- `FluentBarBehavior`: everything is in that table, plus `progressCompletedHaptic` and
  `withGestures(isSwipeEnabled:, dismissOnTap:)`.
- `FluentBarProgressTheme`: `style`, `position`, `showText`, `textAlign`, `textEffect`,
  `textEffectDuration`, `animationDuration`, `thickness`, `size`, `progressColor`,
  `trackDecoration`, `textStyle`, `successIcon`, `successIconColor`, `successIconDuration`,
  `labelBuilder`, `progressBuilder`, `announceUpdates`.

```dart
FluentBar.show<Order>(
  message: 'Order shipped',
  type: FluentBarType.success,
  payload: order,
  options: FluentBarOptions<Order>(
    actions: FluentBarActions<Order>(label: 'Track', onPressed: (controller, order) => openTracking(order?.id)),
    callbacks: FluentBarCallbacks<Order>(onProgressCompleted: (item) => log('done')),
    appearance: const FluentBarAppearance<Order>(maxMessageLines: 2, messageOverflow: TextOverflow.ellipsis),
  ),
);
```

</details>

<details>
<summary><b>Enums</b> - every value</summary>

| Enum | Values |
|---|---|
| `FluentBarPosition` | `top`, `bottom`, `left`, `right`, `center` |
| `FluentBarPriority` | `low`, `normal`, `high`, `critical` |
| `FluentBarDuplicatePolicy` | `update`, `updateAndResetTimer`, `ignore`, `allow` |
| `FluentBarRelocationStrategy` | `queueNext`, `forceReplace`, `ignore` |
| `FluentBarEntranceAnimation` | `slide`, `fadeSlide`, `bouncingSlide`, `fade`, `scale`, `flip3d`, `elastic` |
| `FluentBarEffect` | `shake`, `bounce`, `pulse`, `heartbeat`, `custom` |
| `FluentBarHapticType` | `none`, `light`, `medium`, `heavy` |
| `FluentBarThemeMode` | `system`, `light`, `dark` |
| `FluentBarThemeStyle` | `auto`, `material`, `cupertino`, `windows` |
| `FluentBarTimeoutBarPosition` | `top`, `bottom` |
| `FluentBarTimeoutBarDirection` | `forward`, `reverse` |
| `FluentBarProgressStyle` | `linear`, `circular` |
| `FluentBarProgressPosition` | `top`, `bottom`, `left`, `right`, `replaceIcon` |
| `FluentBarProgressTextAlign` | `left`, `right`, `center` |
| `FluentBarProgressTextEffect` | `none`, `count`, `fade`, `roll`, `flip`, `pop` |
| `FluentBarProgressOutcome` | `completed`, `failed`, `canceled` |
| `FluentBarSemantics` | `announce`, `quiet`, `hidden` |
| `FluentBarBytesLabel` | `amount`, `percent`, `both` |
| `FluentBarLifecycleState` | `queued`, `showing`, `visible`, `hiding`, `dismissed`. Getters: `isQueued`, `isShowing`, `isVisible`, `isHiding`, `isDismissed`, `isOnScreen`, `isInteractive`, `isAnimating`, `isFinished` |
| `FluentBarDismissReason` | `timeout`, `swipe`, `tap`, `actionButton`, `closeButton`, `accessibility`, `manual`, `force`, `dropped`. Getters: `isByUser`, `isByCode`, `isAutomatic` |
| `FluentBarPauseReason` | `manual`, `loading`, `action`, `touch` |
| `FluentBarInteraction` | `tap`, `action`, `hold`, `swipe`, `close`, `accessibility` |
| `FluentBarAnalyticsEvent` | `requested`, `queued`, `shown`, `updated`, `ignoredDuplicate`, `relocated`, `tapped`, `actionTapped`, `paused`, `resumed`, `progressCompleted`, `progressFailed`, `progressCanceled`, `queueOverflow`, `dismissed`. Getters: `isLifecycle`, `isInteraction`, `isProgress`, `isRejected`, `isCountdown`, `hasMetrics` |
| `FluentBarErrorSeverity` | `warning`, `error`. Getters: `isWarning`, `isError` |
| `FluentBarErrorType` | see [Errors](errors.md) |
| `FluentBarUpdateRate` (a class with constants) | `low`, `medium`, `high`, `fps60`, `fps120`, or `FluentBarUpdateRate(interval)`, `.custom(interval)`, `.ms(milliseconds)` |

Progress states are classes: `FluentBarProgressState.value(0...1)` (`FluentBarProgressValue`),
`.fraction(current, total)` (`FluentBarProgressFraction`), `.bytes(received, total)`
(`FluentBarProgressBytes`), `.indeterminate()` (`FluentBarProgressIndeterminate`). `state.format()` gives the text the default label shows, and
`FluentBarProgressLabel` is the widget that draws it with the text effects.

</details>

