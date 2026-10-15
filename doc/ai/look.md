# Themes, types and builders

Version: 1.0.0. Read this to change how bars look: themes, light and dark, custom types, replacing a part of the bar.
The rules in `AI_GUIDE.md` apply here too.

## Themes

A **theme** decides how a bar looks (colors, shape, text styles, icons, padding); a **type** decides
what a bar is and its default behavior (next section).

```dart
// Built-in themes: material, cupertino, windows, minimal, modern, liquidGlass.
FluentBar.patchConfig((c) => c.copyWith(defaultTheme: FluentBarTheme.minimal));
FluentBar.info<void>('One bar only').withTheme(FluentBarTheme.cupertino).dark().show();

// Tweak a theme: callbacks get (context, type, themeMode).
final rounded = FluentBarTheme.material.copyWith(
  borderRadius: (context, type, mode) => BorderRadius.circular(24),
  margin: (context, type, mode) => const EdgeInsets.all(24),
);

// Your own theme: three members are required.
class BrandTheme extends FluentBarTheme {
  const BrandTheme();
  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) =>
      BoxDecoration(color: const Color(0xFF1E293B), borderRadius: theme.borderRadius(context, type, themeMode: themeMode));
  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      const TextStyle(color: Colors.white70);
}
```

Without `defaultTheme` the platform theme is used (`themeStyle`: `auto`, `material`, `cupertino`,
`windows`). Mode: `FluentBarThemeMode.system | light | dark` (bar `withThemeMode` / `dark()` / `light()`,
type `themeMode`, config `defaultThemeMode`).

## Types

```dart
// Built-in types: FluentBarType.info, success, warning, error.
// A variation of a built-in type:
final quiet = FluentBarType.info.copyWith(showIcon: false, duration: const Duration(seconds: 2));
FluentBar.custom<void>(quiet, 'Synced').show();

// Change a built-in type for the whole app; existing calls stay untouched.
FluentBar.patchConfig((c) => c.copyWith(
  typeOverrides: {FluentBarType.error: FluentBarType.error.copyWith(duration: const Duration(seconds: 8))},
));

// Your own type: override only the getters that differ; null or not overridden = the config decides.
class AchievementType extends FluentBarType {
  const AchievementType();
  @override String get name => 'achievement';
  @override Duration get duration => const Duration(seconds: 7);
  @override FluentBarEntranceAnimation get entranceAnimation => FluentBarEntranceAnimation.scale;
  @override FluentBarThemeMode? get themeMode => FluentBarThemeMode.dark;
  @override Widget? get icon => const Icon(Icons.auto_awesome, color: Colors.yellowAccent);
}

FluentBar.custom<void>(const AchievementType(), 'Ten days in a row!').show();
```

- `kind` names the built-in type whose colors and icon your type takes; by default itself.
- A `typeOverrides` key is compared by identity: keep a `copyWith` type in a variable.
- A getter that throws is reported and replaced by its default. Code that reads the getters of a
  type it did not create can use `FluentBarType.guard(type)`.
- The full list of getters and their place in the lookup order: `settings.md`.

## Builders (replace a part of the bar)

| Part | Where |
|---|---|
| Whole content | `item.withContent((context, entry) => …)`, type `builder`, config `defaultBuilder` |
| Position on screen | `FluentBarBehavior(positionBuilder: (context, child) => …)`, type, config |
| Enter / leave | `FluentBarAppearance(transitionBuilder: (context, animation, child) => …)`, type, config |
| Attention effect | `FluentBarAppearance(customEffectBuilder: …)` + `entry.customEffect(...)` |
| Progress indicator / its text | `FluentBarProgressTheme(progressBuilder: …, labelBuilder: …)` |
| Action button | `FluentBarActions(builder: …)` |
| Icon / close icon | bar `.withIcon()` / `.withCloseButton(icon:)`, type `icon` / `closeIcon`, theme `defaultIcon` / `closeIcon` |
| Container, countdown line | theme only (`wrapContainer`, `wrapInteractiveContainer`, `buildTimeoutBar`); a type does not change them |

`positionBuilder` changes only where the bar is drawn. The region and the queue follow `position`
(bar, type, config): a top bar drawn at the bottom by a builder still waits behind top bars.

Inside `withContent` you still get the queue, timers, gestures and animations; use
`entry.controller` (for example `remainingDurationNotifier`) to drive your own UI.

Two widgets of the default bar are public, so custom content can keep the standard look:
`FluentBarTaskProgressWidget(progressNotifier: entry.controller.progressStateNotifier, theme: …,
defaultColor: …, successIcon: …)` draws the indicator, and `FluentBarProgressLabel(text: …,
style: …, effect: …, duration: …)` draws a text with the roll / flip / fade effects.
Builder signatures: `progressBuilder: (context, ValueListenable<FluentBarProgressState?> notifier) => Widget`,
`labelBuilder: (FluentBarProgressState state) => String`,
`customEffectBuilder: (context, AnimationController controller, child) => Widget`.
