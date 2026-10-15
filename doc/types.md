# Types

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Types

A **type** says what kind of bar this is and bundles its defaults: color, icon, duration, position,
animation, haptics, gestures. How the bar looks is the job of a [theme](themes.md); a type only
sets the values it overrides.

The built-in types are `FluentBarType.info`, `success`, `warning` and `error`; `FluentBar.info(…)`,
`.success(…)` and the others use them.

```dart
// A variation of a built-in type, kept in a variable.
final quiet = FluentBarType.info.copyWith(showIcon: false, duration: const Duration(seconds: 2));
FluentBar.custom<void>(quiet, 'Synced').show();

// Change a built-in type for the whole app: the existing calls stay as they are.
FluentBar.patchConfig((config) => config.copyWith(
  typeOverrides: {FluentBarType.error: FluentBarType.error.copyWith(duration: const Duration(seconds: 8))},
));
```

A type of your own extends `FluentBarType` and overrides only the getters that differ. A getter
that returns `null`, or is not overridden, leaves the value to the config:

```dart
class AchievementType extends FluentBarType {
  const AchievementType();

  @override
  String get name => 'achievement';

  @override
  Duration get duration => const Duration(seconds: 7);

  @override
  FluentBarEntranceAnimation get entranceAnimation => FluentBarEntranceAnimation.scale;

  @override
  FluentBarThemeMode? get themeMode => FluentBarThemeMode.dark;

  @override
  Widget? get icon => const Icon(Icons.auto_awesome, color: Colors.yellowAccent);
}

FluentBar.custom<void>(const AchievementType(), 'Ten days in a row!').show();
```

- `kind` names the built-in type whose colors and icon your type takes; by default itself.
- A type used as a key of `typeOverrides` is compared by identity: keep a `copyWith` type in a
  variable.
- A getter that throws is reported and replaced by its default; your code that reads the getters
  of a type it did not create can use `FluentBarType.guard(type)` for the same protection.
- Every getter a type can override, and where each one sits in the lookup order, is in
  [Overriding settings](settings.md#overriding-settings).

> **Demo:** [Themes & types → Type of the bar](https://rtfmko.github.io/fluent_bar/#/themes/type) (`themes/type`) · [Themes & types → Type overrides](https://rtfmko.github.io/fluent_bar/#/themes/type-overrides) (`themes/type-overrides`)<br>
> **API:** [`FluentBarType`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarType-class.html)
