# Builders

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Builders: replace any part

Everything the bar draws can be replaced with your own widget, and the queue, timers, gestures and
accessibility keep working. Like any setting, a builder can live on the bar, on a type or in the
config (see [Overriding settings](settings.md#overriding-settings)).

| Part | On one bar | On a type | In the config |
|---|---|---|---|
| The whole content | `.withContent((context, entry) => …)` | `builder` | `defaultBuilder` |
| Where the bar sits | `FluentBarBehavior(positionBuilder: (context, child) => …)` | `positionBuilder` | `defaultPositionBuilder` |
| How it enters and leaves | `FluentBarAppearance(transitionBuilder: (context, animation, child) => …)` | `transitionBuilder` | `defaultTransitionBuilder` |
| An attention effect | `FluentBarAppearance(customEffectBuilder: …)` + `entry.customEffect()` | `customEffectBuilder` | - |
| The progress indicator | `FluentBarProgressTheme(progressBuilder: (context, notifier) => …)` | `progressTheme` | `progressTheme` |
| The progress text | `FluentBarProgressTheme(labelBuilder: (state) => …)` | `progressTheme` | `progressTheme` |
| The action button | `FluentBarActions(builder: (context, controller, type, mode) => …)` | - | - |
| The icon | `.withIcon()` | `icon` | theme `defaultIcon` |
| The close icon | `.withCloseButton(icon: …)` | `closeIcon` | theme `closeIcon` |
| Container, countdown line | `.withTheme()` with the theme hooks `wrapContainer`, `buildTimeoutBar` | theme only | `defaultTheme` |

```dart
// Your own content. The entry gives you the texts and the controller.
FluentBar.info<void>('Now playing: Midnight City')
    .withContent((context, entry) => Card(
          child: ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(entry.item.message),
            trailing: FluentBarCloseButton(controller: entry.controller),
          ),
        ))
    .show();

// Your own place on screen and your own entrance, for every bar.
FluentBar.patchConfig((config) => config.copyWith(
  defaultPositionBuilder: (context, child) => Align(alignment: Alignment.topRight, child: SizedBox(width: 360, child: child)),
  defaultTransitionBuilder: (context, animation, child) => ScaleTransition(scale: animation, child: child),
));
```

"Theme only": a type does not change the container or the countdown line. They come from the theme
of the bar or of the config; adjust a built-in one with `FluentBarTheme.material.copyWith(…)`.

`positionBuilder` decides only where the bar is drawn. Its region, and so the queue it waits in,
comes from `position` (the bar, then its type, then the config). A top bar that a builder draws at
the bottom still waits behind the other top bars. See
[Regions and the queue](queue.md#regions-and-the-queue).

A builder that throws does not break the bar: the error is reported and the default part is drawn.

> **Demo:** [Builders → Content builder](https://rtfmko.github.io/fluent_bar/#/builders/content-builder) (`builders/content-builder`) · [Builders → Standard parts in your own layout](https://rtfmko.github.io/fluent_bar/#/builders/standard-parts) (`builders/standard-parts`) · [Builders → Position builder](https://rtfmko.github.io/fluent_bar/#/builders/position-builder) (`builders/position-builder`) · [Builders → Transition & effect builders](https://rtfmko.github.io/fluent_bar/#/builders/transition-effect) (`builders/transition-effect`) · [Builders → Progress & label builders](https://rtfmko.github.io/fluent_bar/#/builders/progress-label) (`builders/progress-label`) · [Builders → Action builder](https://rtfmko.github.io/fluent_bar/#/builders/action-builder) (`builders/action-builder`) · [Builders → Theme hooks](https://rtfmko.github.io/fluent_bar/#/builders/theme-hooks) (`builders/theme-hooks`)<br>
> **API:** [`FluentBarAppearance`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarAppearance-class.html) · [`FluentBarBehavior`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarBehavior-class.html) · [`FluentBarActions`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarActions-class.html) · [`FluentBarProgressTheme`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarProgressTheme-class.html) · [`FluentBarTaskProgressWidget`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarTaskProgressWidget-class.html)

