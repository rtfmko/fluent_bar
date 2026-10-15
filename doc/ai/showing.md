# Showing a bar

Version: 1.0.0. Read this to show a bar: the one-liners, the chain, presets, an action button, gestures, screen readers.
The rules in `AI_GUIDE.md` apply here too.

## Showing a bar

```dart
// 1. One line.
FluentBar.showInfo('Profile saved');
FluentBar.showSuccess('Done', title: 'Upload', id: 'upload');
FluentBar.showWarning('Low storage');
FluentBar.showError('Payment failed');

// 2. Chain: a draft plus only what differs from the defaults.
FluentBar.success('Order #1042 has been shipped')
    .withTitle('On its way')
    .withAction('Track', onPressed: (controller, payload) => openTracking())
    .withTimeoutBar()
    .withDuration(const Duration(seconds: 6))
    .atBottom()
    .show();

// 3. Everything by hand.
FluentBar.show<void>(
  message: 'Ready',
  type: FluentBarType.success,
  id: 'ready',
  options: const FluentBarOptions<void>(
    behavior: FluentBarBehavior(position: FluentBarPosition.bottom),
    appearance: FluentBarAppearance<void>(showTimeoutBar: true),
  ),
);
```

`FluentBarOptions<T>` fields: `meta`, `tags`, `behavior`, `actions`, `appearance`, `callbacks`, `progressState`.

### Presets

| Draft / one-liner | What you get |
|---|---|
| `FluentBar.snack` / `showSnack(message, {action, onAction, type, duration, id, payload})` | bottom, no icon, optional action, like a SnackBar |
| `FluentBar.toast` / `showToast(message, {type, duration = 2 s, position = bottom, id, payload})` | compact hint, no gestures, fades in |
| `FluentBar.banner` / `showBanner(message, {title, action, onAction, type, id, payload})` | pinned at the top, persistent, not dismissible by hand |
| `FluentBar.loading` / `showLoading(message, {title, type, linear = false, id, payload})` | spinner (or line) that waits until you finish the progress |

### Chain methods (`FluentBarItem<T>`)

- Content: `withTitle`, `withId`, `withPayload`, `withMeta`, `withPreset`, `withTag(tag)`, `withTags(tags)`
- Lifetime: `withDuration`, `persistent`, `withTimeoutBar({position, direction})`, `withoutTimeoutBar`
- Progress: `withProgress(state)`, `withLinearProgress({value, state, showText, position, color,
  textEffect, successIconDuration, animationDuration})`, `withCircularProgress({… , size})`
- Place and queue: `at(position)`, `atTop`, `atBottom`, `atCenter`, `withPriority`, `forced`,
  `withDuplicatePolicy`, `withRelocationStrategy`, `withInsets({top, bottom})`, `withoutSafeArea`
- Gestures: `swipeable([bool])`, `dismissOnTap([bool])`, `undismissible`, `pauseOnTouch([bool])`,
  `withHaptic`
- Screen readers: `withSemantics(FluentBarSemantics.announce | quiet | hidden)`
- Close button: `withCloseButton({icon})`, `withoutCloseButton`; the icon comes from the bar, then
  the type (`closeIcon`), then the theme (`closeIcon`). A cross at the end of the bar,
  off by default (`FluentBarConfig.defaultShowCloseButton`, `FluentBarType.showCloseButton`). It
  only closes the bar and never stops a task: for "Cancel" use `.withCancelButton()` (see [progress.md](progress.md)). The `snack`, `toast`,
  `banner` and `loading` presets and `undismissible()` set it off on the bar, so the config does
  not add it there; `.withCloseButton()` after them brings it back. Dismiss reason `closeButton`,
  interaction `close`; `onTap` is not called. It works also while the bar is loading or its action
  runs, so a bar with a hung task can still be closed. Suggest it for web and desktop apps and for
  persistent bars. In a custom content builder use `FluentBarCloseButton(controller: entry.controller)`.
- Look: `withBackground`, `withIcon(widget, {color, size})`, `withoutIcon`, `withTheme`,
  `withThemeMode`, `dark`, `light`, `withEntrance`, `withoutAnimations`, `withContent(builder)`
- Action and callbacks: `withAction(label, {onPressed, closeOnAction = true, analyticsName})`,
  `withCancelButton(label, {child, onCancel, canceledMessage, canceledType})`, `onTap`, `onShow`,
  `onDismiss`
- Finish: `show()`, `force()`

`withAction` describes the whole button: a second call replaces the label **and** the handler.

## Actions

- `withAction(label, onPressed: (controller, payload) async {…}, closeOnAction: true, analyticsName: 'undo')`.
  `analyticsName` is a stable key for analytics (the label is translated); it arrives as
  `action_name` in `payload.toFlatMap()`. Cancel and Retry buttons set `cancel` and `retry`.
- An async `onPressed` shows a loader on the button, holds the countdown and ignores repeated taps.
- `closeOnAction: true` (default) closes the bar at the tap, before `onPressed` runs. For "loader,
  then close" pass `closeOnAction: false` and call `controller.close()` at the end of the handler.
- `closeOnAction: false` keeps the bar; update or close it from the handler through `controller`.
- `controller.setLoading(isLoading: true)` puts the whole bar into a loading state (gestures off).
- Any widget instead of the button: `FluentBarActions(builder: (context, controller, type, mode) => …)`
  passed with `item.copyWith(actions: FluentBarActions<T>(…))`. Inside it call
  `controller.handleAction(onPressed: …, closeOnAction: …)` to get the same loader, countdown hold
  and throttling as the default button.
- Other `FluentBarActions` fields: `child` (a widget instead of `label`), `analyticsName`, `removeWhenProgressEnds`
  (the button leaves with the progress), `throttleDuration` (400 ms), `maxActionLines`, `actionOverflow`, `actionLoaderColor`, `actionLoadingWidget`.

## Accessibility and motion

- A bar is a live region for screen readers; the reader's dismiss gesture closes a bar that can be
  swiped or tapped away, with the dismiss reason `accessibility` and the interaction of the same name.
  It is read out when it appears and when its title or message changes; the focus does not move.
- `FluentBarSemantics` (bar, type, config): `announce` (default), `quiet` (readable, never read
  out by itself), `hidden` (not exposed). Suggest `quiet` for bars that repeat what the screen
  shows; do not suggest `hidden` unless the user asks for it.
- The progress value is a separate node and is not read out on every update. To announce the
  result, give the bar a new message: `completeProgress(message: 'Uploaded')`.
  `FluentBarProgressTheme(announceUpdates: true)` reads every update.
- With the system "reduce motion" setting (iOS Reduce Motion, Android Remove animations) bars fade
  instead of sliding, attention effects are skipped and icons switch at once. Opt out with
  `respectSystemReduceMotion: false`.
- `withoutAnimations()` / `defaultDisableAnimations` turn every animation of a bar off.
- Touching or hovering a bar pauses its countdown (`pauseOnTouch`).
