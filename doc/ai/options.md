# Per-bar options and enum values

Version: 1.0.0. Read this to look up a parameter of a bar, a field of a model or the values of an enum.
The rules in `AI_GUIDE.md` apply here too.

## Per-bar options and enum values

Use these exact names; do not invent others.

- `FluentBarBehavior`: `position`, `priority`, `isForce`, `duplicatePolicy`, `relocationStrategy`,
  `isSwipeEnabled`, `dismissOnTap`, `pauseOnTouch`, `semantics`, `dismissDirection`, `useSafeArea`,
  `topInset`, `bottomInset`, `haptic`, `progressCompletedHaptic`, `timeoutUpdateInterval`, `positionBuilder`.
- `FluentBarAppearance<T>`: `theme`, `themeMode`, `backgroundColor`, `decoration`, `padding`, `margin`,
  `constraints`, `actionsConstraints`, `icon`, `iconColor`, `iconSize`, `showIcon`, `showCloseButton`, `closeIcon`, `showTimeoutBar`,
  `timeoutBarPosition`, `timeoutBarDirection`, `entranceAnimation`, `transitionDuration`,
  `reverseTransitionDuration`, `disableAnimations`, `maxTitleLines`, `maxMessageLines`,
  `titleOverflow`, `messageOverflow`, `titleTextAlign`, `messageTextAlign`, `actionTextAlign`,
  `progressTheme`, `builder`, `transitionBuilder`, `customEffectBuilder`.
- A `FluentBarType` can override the same settings as getters (`duration`, `isPersistent`,
  `position`, `priority`, `showIcon`, `icon`, `backgroundColor`, `entranceAnimation`, `haptic`, …);
  `null` means "ask the config".

Everything else that is public, so nothing has to be guessed:

- `FluentBar`, besides showing: `showItem(item)` / `forceItem(item)` for a ready `FluentBarItem`;
  `currentConfig`; `measuredTopInset` / `measuredBottomInset` (heights reported by the inset
  widgets); `allQueueLength`, `mainQueueLength`, `bottomQueueLength`; `removeErrorHandler`.
- `FluentBarController`, besides the calls in [live-bars.md](live-bars.md): `subtractDuration(duration)`,
  `triggerEffect(FluentBarEffect, {intensity, duration, repeat})`, `customEffect(…)`, `force()`,
  `handleAction(…)`, `setLoading(isLoading:, …)`.
- Entry shortcuts: `updateValue(0…1)`, `updateFraction(current, total)`,
  `updateBytes(received, total)`, `updateProgress(state)`,
  `completeProgress`, `failProgress`, `cancelProgress`, `isForce`, `force()`.
- `FluentBarItem`: `id`, `uuid` (always set, unique per draft), `type`, `title`, `message`,
  `duration`, `isPersistent`, `payload`, `meta`, `preset`, `tags`, `progressState`, `behavior`,
  `appearance`, `actions`, `callbacks`.
- `FluentBarProgressState` subclasses: `FluentBarProgressValue` (`value`),
  `FluentBarProgressFraction` (`current`, `total`), `FluentBarProgressBytes` (`received`, `total`,
  `label`, `hasTotal`, `text`, static `formatBytes(bytes)`), `FluentBarProgressIndeterminate`; all have
  `progress` (0…1 or `null`) and `isCompleted`. `state.format({formatValue, formatFraction,
  formatIndeterminate})` gives the text the default label shows.
- `FluentBarConfig.reducesMotion(context)` - whether animations should be reduced right now; use it
  in custom builders. `FluentBarBehavior.withGestures(isSwipeEnabled:, dismissOnTap:)` sets or
  clears both gesture flags. `FluentBarMetrics.countOf(FluentBarInteraction)`.
- `FluentBarType.guard(type)` wraps a type so that a throwing getter gives a default; call it in
  your own code that reads a type it did not create (`FluentBarType.guard(entry.item.type).name`).
- `FluentBarType` getters a custom type may override: `name` (`custom` unless overridden; give each type its own), `kind` (the built-in type
  whose colors and icon are used), `duration`, `isPersistent`, `position`, `priority`,
  `isSwipeEnabled`, `dismissOnTap`, `pauseOnTouch`, `semantics`, `dismissDirection`, `useSafeArea`,
  `topInset`, `bottomInset`, `duplicatePolicy`, `relocationStrategy`, `timeoutUpdateInterval`, `haptic`,
  `progressCompletedHaptic`, `customHaptic`, `customProgressCompletedHaptic`, `showIcon`, `icon`,
  `backgroundColor`, `themeMode`, `showCloseButton`, `showTimeoutBar`, `timeoutBarColor`, `timeoutBarPosition`,
  `timeoutBarDirection`, `entranceAnimation`, `transitionDuration`, `reverseTransitionDuration`,
  `disableAnimations`, `progressTheme`, `builder`, `positionBuilder`, `transitionBuilder`,
  `customEffectBuilder`. `copyWith` takes the same names except `name` and `kind`: a copy keeps
  those of its base.
- `FluentBarTheme` methods a custom theme may override; each gets `(context, type, {themeMode})`:
  required `boxDecoration` (also gets `theme`), `titleStyle`, `messageStyle`; optional
  `actionStyle`, `actionDecoration`, `actionInternalPadding`, `actionsConstraints`,
  `actionMaxLines`, `actionOverflow`, `actionTextAlign`, `actionLoaderColor`,
  `actionLoadingWidget`, `backgroundColor`, `borderRadius`, `constraints`, `padding`, `margin`,
  `spacing`, `titleSpacing`, `iconSize`, `iconColor`, `defaultIcon`, `closeIcon`, `closeIconSize`,
  `closeIconColor`, `closeButtonPadding`, `closeButtonAlignment`, `maxTitleLines`,
  `maxMessageLines`, `titleOverflow`, `messageOverflow`, `titleTextAlign`, `messageTextAlign`,
  `timeoutBarColor`, `timeoutBarBackgroundColor`, `timeoutBarMinHeight`,
  `timeoutBarBorderRadius`, `buildTimeoutBar`, `wrapContainer`, `wrapInteractiveContainer`,
  `isDarkMode`. `FluentBarTheme.x.copyWith(…)` takes the same names as callbacks
  `(context, type, themeMode) => value`.

| Enum | Values |
|---|---|
| `FluentBarPosition` | `top`, `bottom`, `left`, `right`, `center` |
| `FluentBarEntranceAnimation` | `slide`, `fadeSlide`, `bouncingSlide`, `fade`, `scale`, `flip3d`, `elastic` |
| `FluentBarEffect` | `shake`, `bounce`, `pulse`, `heartbeat`, `custom` |
| `FluentBarHapticType` | `none`, `light`, `medium`, `heavy` |
| `FluentBarThemeMode` / `FluentBarThemeStyle` | `system`, `light`, `dark` / `auto`, `material`, `cupertino`, `windows` |
| `FluentBarTimeoutBarPosition` / `FluentBarTimeoutBarDirection` | `top`, `bottom` / `forward`, `reverse` |
| `FluentBarProgressStyle` / `FluentBarProgressPosition` | `linear`, `circular` / `top`, `bottom`, `left`, `right`, `replaceIcon` |
| `FluentBarProgressTextAlign` / `FluentBarProgressTextEffect` | `left`, `right`, `center` / `none`, `count`, `fade`, `roll`, `flip`, `pop` |
| `FluentBarInteraction` (in metrics) | `tap`, `action`, `hold`, `swipe`, `close`, `accessibility` |
| `FluentBarLifecycleState` | `queued`, `showing`, `visible`, `hiding`, `dismissed` (getters `isQueued`, `isShowing`, `isVisible`, `isHiding`, `isDismissed`, `isOnScreen`, `isInteractive`, `isAnimating`, `isFinished`) |
| `FluentBarErrorSeverity` | `warning`, `error`. Getters: `isWarning`, `isError` |
| `FluentBarDismissReason` | `timeout`, `swipe`, `tap`, `actionButton`, `closeButton`, `accessibility`, `manual`, `force`, `dropped` (getters `isByUser`, `isByCode`, `isAutomatic`) |
| `FluentBarProgressOutcome` | `completed`, `failed`, `canceled` |
| `FluentBarSemantics` | `announce`, `quiet`, `hidden` |
| `FluentBarBytesLabel` | `amount`, `percent`, `both` |
| `FluentBarPauseReason` | `manual`, `loading`, `action`, `touch` |
| `FluentBarUpdateRate` | `low`, `medium`, `high`, `fps60`, `fps120`, or `FluentBarUpdateRate(interval)`, `.custom(interval)`, `.ms(milliseconds)` |
