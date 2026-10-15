# Global config and overriding settings

Version: 1.0.0. Read this to set defaults for every bar, or to find which level (bar, type, config) a value comes from.
The rules in `AI_GUIDE.md` apply here too.

## Global config (`FluentBarConfig`)

| Group | Fields (default) |
|---|---|
| Place | `defaultPosition` (top), `enableMultiRegion` (true), `defaultUseSafeArea` (true), `topInset`, `bottomInset` (null = measured), `defaultRelocationStrategy` (queueNext), `defaultPositionBuilder` |
| Look | `defaultTheme`, `themeStyle` (auto), `defaultThemeMode` (system), `defaultShowIcons` (true), `defaultEntranceAnimation` (slide), `defaultTransitionDuration` (300 ms), `defaultReverseTransitionDuration` (250 ms), `defaultDisableAnimations` (false), `respectSystemReduceMotion` (true), `defaultTransitionBuilder`, `defaultBuilder` |
| Lifetime | `defaultDuration` (4 s), `defaultShowTimeoutBar` (false), `defaultTimeoutBarPosition` (bottom), `defaultTimeoutBarDirection` (forward), `defaultTimeoutUpdateInterval` (`FluentBarUpdateRate.medium`) |
| Gestures | `defaultIsSwipeEnabled` (true), `defaultDismissOnTap` (true), `defaultPauseOnTouch` (true), `defaultDismissDirection`, `enableHaptics` (true), `defaultShowCloseButton` (false), `closeButtonLabel` (null = the app localization; reset with `clearCloseButtonLabel`), `defaultSemantics` (announce) |
| Queue | `defaultQueueStrategy` (smart), `maxQueueLength` (15, per region), `defaultDuplicatePolicy` (update), `duplicateComparator` |
| Other | `progressTheme`, `typeOverrides`, `disabledAnalyticsEvents` |

`copyWith(null)` keeps a value; to clear one use the flags `clearTopInset`, `clearBottomInset`,
`clearDefaultTheme`, `clearTypeOverrides`, `clearDuplicateComparator`, `clearDefaultBuilder`,
`clearDefaultPositionBuilder`, `clearDefaultTransitionBuilder`, `clearCloseButtonLabel`. Listen with `FluentBar.configNotifier`.

## Overriding settings (where a value comes from)

Lookup order for every setting; the first level that sets it wins:
**the bar → its `FluentBarType` → `FluentBarConfig` → the built-in default.**

```dart
// Level 3 - the whole app.
FluentBar.patchConfig((c) => c.copyWith(defaultDuration: const Duration(seconds: 5), defaultPosition: FluentBarPosition.bottom));

// Level 2 - one kind of bar. A getter that is not overridden returns null = "ask the config".
class SaleType extends FluentBarType {
  const SaleType();
  @override String get name => 'sale';
  @override Duration? get duration => const Duration(seconds: 8);
}

// Level 1 - one bar.
FluentBar.showInfo('Saved');                                          // 5 s, bottom (config)
FluentBar.showCustom<void>(const SaleType(), '20% off');             // 8 s, bottom (type, then config)
FluentBar.custom<void>(const SaleType(), '20% off').withDuration(const Duration(seconds: 3)).atTop().show(); // 3 s, top (bar)

// A built-in type changed everywhere without touching existing calls.
final longError = FluentBarType.error.copyWith(duration: const Duration(seconds: 10));
FluentBar.patchConfig((c) => c.copyWith(typeOverrides: {FluentBarType.error: longError}));
```

Every setting and its three places. Read a row left to right; the first filled place wins.
"-" = that level does not exist for the setting.

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

Visual details that only a theme knows (`padding`, `margin`, `decoration`, `constraints`, text
styles, line limits, alignment, overflow) resolve bar → theme: `FluentBarAppearance(…)` for one
bar, `FluentBarTheme.x.copyWith(…)` for all.

Choose the level by how many bars need the value:

| Scope | Where to put it |
|---|---|
| Every bar | `FluentBarConfig` through `FluentBar.patchConfig` (applies at once, also to visible bars) |
| A built-in type everywhere | `typeOverrides` in the config |
| A group of bars | a custom `FluentBarType`, or `FluentBarType.x.copyWith(…)` kept in a variable |
| One bar | the `.with…()` chain or `FluentBarOptions(behavior:, appearance:)` |
| A bar already on screen | `entry.patchBehavior(…)`, `patchAppearance(…)`, `update(…)`, `controller.updateDuration(…)` |
| Look of a theme | `FluentBarTheme.x.copyWith(…)` as `defaultTheme` or `.withTheme(…)` |
| One visual detail of one bar | `withBackground`, `withIcon`, or `FluentBarAppearance(padding, margin, decoration, constraints, …)`; these beat the theme |
| Progress indicator | `progressTheme` on the config, the type or the bar - merged field by field |

Details that are easy to get wrong:

- Built-in types set some values themselves, and those beat the config: `error` has a 6 s duration,
  `high` priority and no swipe. To change them use `typeOverrides` or set the value on the bar.
- An explicit `false` is a value: `.swipeable(false)` beats a type or config that says `true`.
- `null` never clears a config value in `copyWith`; use the `clear…` flags (see "Global config" above).
- Replacing a whole behavior or appearance object against changing one field: rule 11 in `AI_GUIDE.md`.
- `priority` and `haptic` have no config default because every type already has a value for them
  (`normal`, `none` in the base type).
- A builder set further away is cancelled by an explicit value set closer: `.atTop()` on a bar wins
  over `defaultPositionBuilder`, `.withEntrance(…)` wins over `defaultTransitionBuilder`.
- Do not repeat a config or type value on the bar "to be safe"; it stops following later changes.
