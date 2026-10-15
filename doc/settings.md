# Settings

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Overriding settings

Every setting is looked up in the same order, and the first place that sets it wins:

**the bar → its type → `FluentBarConfig` → the built-in default**

```dart
// For the whole app.
FluentBar.patchConfig((config) => config.copyWith(
  defaultDuration: const Duration(seconds: 5),
  defaultPosition: FluentBarPosition.bottom,
));

// For one kind of bar: a type. A getter you do not override means "ask the config".
class SaleType extends FluentBarType {
  const SaleType();
  @override String get name => 'sale';
  @override Duration? get duration => const Duration(seconds: 8);
}

// For one bar.
FluentBar.showInfo('Saved');                                         // 5 s, bottom  (config)
FluentBar.showCustom<void>(const SaleType(), '20% off');            // 8 s, bottom  (type, then config)
FluentBar.custom<void>(const SaleType(), '20% off')
    .withDuration(const Duration(seconds: 3))
    .atTop()
    .show();                                                         // 3 s, top     (the bar)
```

| To change… | Do this |
|---|---|
| A default for every bar | `FluentBar.patchConfig((c) => c.copyWith(…))`. Applies at once, also to bars on screen |
| A built-in type everywhere, without touching the calls | `typeOverrides: {FluentBarType.error: FluentBarType.error.copyWith(duration: …)}` in the config |
| A group of bars | your own `FluentBarType`, or `FluentBarType.info.copyWith(…)` kept in a variable |
| One bar | the `.with…()` chain, or `FluentBarOptions(behavior: …, appearance: …)` |
| A bar that is already on screen | `entry.patchBehavior(…)`, `entry.patchAppearance(…)`, `entry.update(…)` |
| The look of a built-in theme | `FluentBarTheme.material.copyWith(…)` as `defaultTheme` or `.withTheme(…)` |
| One visual detail of one bar | `.withBackground(…)`, `.withIcon(…)`, or `FluentBarAppearance(padding: …, decoration: …)`. These beat the theme |
| The progress indicator | `progressTheme` in the config, the type or the bar; the three are merged field by field |
| Back to the default | `config.copyWith(clearDefaultTheme: true)` and the other `clear…` flags; passing `null` keeps the value |

**Every setting and where it lives.** Read a row left to right: the first filled place wins.

<details>
<summary>The full table (33 settings)</summary>

| Setting | Bar: chain | Bar: field | Type | Config |
|---|---|---|---|---|
| Position | `.at()`, `.atTop()`, `.atBottom()`, `.atCenter()` | `behavior.position` | `position` | `defaultPosition` |
| Lifetime | `.withDuration()` | `duration` | `duration` | `defaultDuration` |
| Stay until closed | `.persistent()` | `isPersistent` | `isPersistent` | - |
| Swipe to dismiss | `.swipeable()` | `behavior.isSwipeEnabled` | `isSwipeEnabled` | `defaultIsSwipeEnabled` |
| Swipe direction | - | `behavior.dismissDirection` | `dismissDirection` | `defaultDismissDirection` |
| Tap to dismiss | `.dismissOnTap()` | `behavior.dismissOnTap` | `dismissOnTap` | `defaultDismissOnTap` |
| Pause on touch | `.pauseOnTouch()` | `behavior.pauseOnTouch` | `pauseOnTouch` | `defaultPauseOnTouch` |
| Screen reader | `.withSemantics()` | `behavior.semantics` | `semantics` | `defaultSemantics` |
| Safe area | `.withoutSafeArea()` | `behavior.useSafeArea` | `useSafeArea` | `defaultUseSafeArea` |
| Insets | `.withInsets()` | `behavior.topInset`, `bottomInset` | `topInset`, `bottomInset` | `topInset`, `bottomInset` (then measured) |
| Priority | `.withPriority()` | `behavior.priority` | `priority` (`normal`) | - |
| Duplicate policy | `.withDuplicatePolicy()` | `behavior.duplicatePolicy` | `duplicatePolicy` | `defaultDuplicatePolicy` |
| Relocation strategy | `.withRelocationStrategy()` | `behavior.relocationStrategy` | `relocationStrategy` | `defaultRelocationStrategy` |
| Haptic | `.withHaptic()` | `behavior.haptic` | `haptic` | - (`enableHaptics` switches all) |
| Countdown update rate | - | `behavior.timeoutUpdateInterval` | `timeoutUpdateInterval` | `defaultTimeoutUpdateInterval` |
| Icon shown | `.withoutIcon()`, `.withIcon()` | `appearance.showIcon` | `showIcon` | `defaultShowIcons` |
| Icon | `.withIcon()` | `appearance.icon` | `icon` | theme `defaultIcon` |
| Background | `.withBackground()` | `appearance.backgroundColor` | `backgroundColor` | theme `backgroundColor` |
| Close button | `.withCloseButton()`, `.withoutCloseButton()` | `appearance.showCloseButton` | `showCloseButton` | `defaultShowCloseButton` |
| Close icon | `.withCloseButton(icon:)` | `appearance.closeIcon` | `closeIcon` | theme `closeIcon` |
| Countdown line | `.withTimeoutBar()`, `.withoutTimeoutBar()` | `appearance.showTimeoutBar` | `showTimeoutBar` | `defaultShowTimeoutBar` |
| Countdown line place | `.withTimeoutBar(position:)` | `appearance.timeoutBarPosition` | `timeoutBarPosition` | `defaultTimeoutBarPosition` |
| Countdown line direction | `.withTimeoutBar(direction:)` | `appearance.timeoutBarDirection` | `timeoutBarDirection` | `defaultTimeoutBarDirection` |
| Light / dark | `.dark()`, `.light()`, `.withThemeMode()` | `appearance.themeMode` | `themeMode` | `defaultThemeMode` |
| Theme | `.withTheme()` | `appearance.theme` | - | `defaultTheme` (then `themeStyle`) |
| Entrance animation | `.withEntrance()` | `appearance.entranceAnimation` | `entranceAnimation` | `defaultEntranceAnimation` |
| Enter / leave duration | - | `appearance.transitionDuration`, `reverseTransitionDuration` | the same names | `defaultTransitionDuration`, `defaultReverseTransitionDuration` |
| No animations | `.withoutAnimations()` | `appearance.disableAnimations` | `disableAnimations` | `defaultDisableAnimations` |
| Progress look | `.withLinearProgress()`, `.withCircularProgress()` | `appearance.progressTheme` | `progressTheme` | `progressTheme` (merged field by field) |
| Content builder | `.withContent()` | `appearance.builder` | `builder` | `defaultBuilder` |
| Position builder | - | `behavior.positionBuilder` | `positionBuilder` | `defaultPositionBuilder` |
| Transition builder | - | `appearance.transitionBuilder` | `transitionBuilder` | `defaultTransitionBuilder` |
| Effect builder | - | `appearance.customEffectBuilder` | `customEffectBuilder` | - |

"-" means that level does not exist for the setting. Visual details that only a theme knows
(padding, margin, decoration, text styles, line limits, alignment) resolve **bar → theme**:
set them in `FluentBarAppearance` for one bar or in `FluentBarTheme.copyWith(…)` for all.

</details>

Good to know:

- The built-in `error` type sets its own values (6 s, high priority, no swipe), so config defaults
  do not reach them. Change them with `typeOverrides` or on the bar.
- An explicit `false` counts as set: `.swipeable(false)` on a bar beats a type that allows swiping.
- One rule for every `copyWith` and `update…`: an omitted argument keeps the value. To remove one
  use the `clear…` flag (`clearTitle`, `clearActions`, …) or `entry.removeAction()` /
  `entry.makePersistent()`.
- `copyWith(behavior: …)` and `updateBehavior(…)` replace the whole object (the same for
  appearance). To change one setting use `.with…()` on a draft and `patchBehavior` /
  `patchAppearance` on a bar that is shown.

> **Demo:** [Overriding settings → Who wins?](https://rtfmko.github.io/fluent_bar/#/overrides/who-wins) (`overrides/who-wins`) · [Overriding settings → Where to put a setting](https://rtfmko.github.io/fluent_bar/#/overrides/where) (`overrides/where`) · [Themes & types → Override a built-in type everywhere](https://rtfmko.github.io/fluent_bar/#/themes/type-overrides) (`themes/type-overrides`) · [Global config](https://rtfmko.github.io/fluent_bar/#/config) (`config`)<br>
> **API:** [`FluentBarConfig`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarConfig-class.html) · [`FluentBarType`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarType-class.html) · [`FluentBarBehavior`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarBehavior-class.html) · [`FluentBarAppearance`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarAppearance-class.html)

## Global config

Every default lives in one place and can be changed at any time, also for bars already on screen:

```dart
FluentBar.patchConfig((config) => config.copyWith(
  defaultPosition: FluentBarPosition.bottom,
  defaultDuration: const Duration(seconds: 5),
  defaultShowTimeoutBar: true,
  maxQueueLength: 5,
));
```

`FluentBar.updateConfig(config)` replaces the whole config, `patchConfig` changes a part of it,
`FluentBar.currentConfig` reads it and `FluentBar.configNotifier` lets a widget follow it.

Motion: with `respectSystemReduceMotion` (on by default) bars fade instead of sliding and skip
attention effects when the system asks to reduce motion. In your own builders ask
`config.reducesMotion(context)`.

> **Demo:** [Global config](https://rtfmko.github.io/fluent_bar/#/config) (`config`) · [Global config → Your config as code](https://rtfmko.github.io/fluent_bar/#/config/code) (`config/code`)<br>
> **API:** [`FluentBarConfig`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarConfig-class.html)

