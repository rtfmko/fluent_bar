# fluent_bar: guide for AI assistants

This file is written for an AI coding assistant. Read it in full, then open only the file in
`doc/ai/` that your task needs. Everything here matches the public API of the package; when in
doubt, read the source in `lib/src/` rather than guessing.

- Version: 1.0.0. The installed version is in the `pubspec.lock` of the app (entry `fluent_bar:`,
  field `version`). If the versions differ, make sure you are reading `AI_GUIDE.md` from the root of
  the installed package (the path from `.dart_tool/package_config.json`) and use that one; if you
  already are, `pubspec.lock` changed without `flutter pub get`, so tell the user to run it. Do not
  edit the guide and do not copy it into the project.
- Package: `fluent_bar` (Flutter). One import: `import 'package:fluent_bar/fluent_bar.dart';`,
  never `package:fluent_bar/src/…`.
- What it is: in-app notification bars (snackbar / toast / banner / progress) shown in an overlay
  above the navigator, with a queue, live updates, themes, analytics and error isolation.
- Entry point: the static class `FluentBar`. No `BuildContext` is needed to show a bar.

## Where to read next

The paths are relative to this file. Each file starts with its version and when to read it.

| Your task | Open |
|---|---|
| set up the package in an app, or understand how bars, regions and the queue work | [doc/ai/setup.md](doc/ai/setup.md) |
| show a bar: the one-liners, the chain, presets, an action button, gestures, screen readers | [doc/ai/showing.md](doc/ai/showing.md) |
| change, find or close a bar that is already on screen | [doc/ai/live-bars.md](doc/ai/live-bars.md) |
| a download, an upload, a task with progress, a `Future`, a Cancel or a Retry button | [doc/ai/progress.md](doc/ai/progress.md) |
| several bars at once: the queue, priorities, forced bars, duplicates, tags | [doc/ai/queue.md](doc/ai/queue.md) |
| change how bars look: themes, light and dark, custom types, replacing a part of the bar | [doc/ai/look.md](doc/ai/look.md) |
| set defaults for every bar, or find which level (bar, type, config) a value comes from | [doc/ai/settings.md](doc/ai/settings.md) |
| send bar events to an analytics service or to read the metrics of a bar | [doc/ai/analytics.md](doc/ai/analytics.md) |
| report the errors of the library to a crash reporter, or find out what a reported error means | [doc/ai/errors.md](doc/ai/errors.md) |
| look up a parameter of a bar, a field of a model or the values of an enum | [doc/ai/options.md](doc/ai/options.md) |
| find a class in the source of the package, or a live example in the demo app to send the user to | [doc/ai/source.md](doc/ai/source.md) |
| a ready solution to a common task, or before writing glue code for dio, bloc, provider, riverpod, Firebase and others | [doc/ai/recipes.md](doc/ai/recipes.md) |
| something behaves unexpectedly, or the user reports a problem with a bar | [doc/ai/troubleshooting.md](doc/ai/troubleshooting.md) |
| code stopped compiling after an update, or the analyzer reports a deprecated member | [doc/ai/migrations.md](doc/ai/migrations.md) |

## Rules

1. **Set up an overlay once**, otherwise nothing can be shown (the library reports a warning and
   keeps bars in the queue). Preferred: `MaterialApp(builder: FluentBarScope.builder())`.
2. **Do not pass `BuildContext`** to show a bar. Call `FluentBar.…` from anywhere: widgets, blocs,
   services, `main()` before `runApp`.
3. **Prefer the shortest form that does the job**: one-liner → chain → full `show(...)`.
4. **To change a bar that is already shown, update it; do not show a second one.** Use the returned
   `FluentBarEntry`, or `FluentBar.find(id)`, or show again with the same `id`.
5. **Give an `id` to any bar you will update, close or de-duplicate later.**
6. **Use the same type argument for every bar that shares an `id`.** `FluentBar.info<void>(…)` and
   `FluentBar.info<Order>(…)` with one id are different bars (the library warns about it).
   `dynamic`, `void` and `Object?` count as the same type.
7. **Settings resolve in one order everywhere: the bar → its type → the global config.** Set a value
   on the bar only when it differs from the type and the config.
8. **Never wrap library calls in try/catch to "protect" the app.** User callbacks, builders, themes
   and types are already guarded: a throw is reported to error handlers and a fallback is used.
9. **Progress values are fractions `0.0 … 1.0`**, not percents. `FluentBarProgressState.value(1.2)`
   and `.fraction(5, 3)` fail an assert; clamp first. (`withLinearProgress(value:)` clamps for you.)
10. **A bar with unfinished progress never times out.** Finish it with `completeProgress`,
    `failProgress` or `cancelProgress`; then the normal countdown starts.
11. **`copyWith(appearance: …)` / `copyWith(behavior: …)` and `updateAppearance` / `updateBehavior`
    replace the whole object.** To change one setting use a `.with…()` method on a draft and
    `patchAppearance` / `patchBehavior` on a shown bar. `null` never removes a value: use the
    `clear…` flags, `removeAction()` or `makePersistent()`.
12. Do not import from `package:fluent_bar/src/…` in application code.
13. **Use the getters of the enums instead of comparing values.** A state, an analytics event,
    a dismiss reason and the severity of an error answer the usual questions themselves. Prefer
    a getter to `==` even when the comparison would be short:
    ```dart
    void onEvent(FluentBarAnalyticsPayload payload, FluentBarEntry<void> entry) {
      final FluentBarLifecycleState state = entry.controller.stateNotifier.value;

      // Do
      if (state.isOnScreen) log('drawn');
      if (payload.event.hasMetrics) log('closed', payload.metrics);
      if (payload.metrics?.dismissReason.isByUser ?? false) log('closed by the user');
      FluentBar.addErrorHandler((FluentBarException error, StackTrace _) {
        if (error.severity.isWarning) log('misuse', error.type.displayName);
      });

      // Do not
      if (state == FluentBarLifecycleState.showing || state == FluentBarLifecycleState.visible || state == FluentBarLifecycleState.hiding) log('drawn');
      if (payload.event == FluentBarAnalyticsEvent.dismissed || payload.event == FluentBarAnalyticsEvent.queueOverflow) log('closed');
      FluentBar.addErrorHandler((FluentBarException error, StackTrace _) {
        if (error.severity == FluentBarErrorSeverity.warning) log('misuse', error.type.displayName);
      });
    }
    ```
    Compare with a single value only when no getter says it, for example
    `event == FluentBarAnalyticsEvent.shown`.

## Common mistakes

The most frequent ones. More symptoms with their causes and fixes: `doc/ai/troubleshooting.md`.

| Symptom | Cause and fix |
|---|---|
| Nothing appears | No overlay. Add `FluentBarScope.builder()` (or the observer / navigator key). |
| Bar covers the app bar or sits under the bottom navigation | Wrap them in `FluentBarTopInset` / `FluentBarBottomInset`. |
| A second bar appears instead of an update | Missing or different `id`, policy `allow`, or a different type argument. |
| Bar never closes | Unfinished progress, `persistent()`, a `banner`, or `isPersistent: true`. |
| Progress shows the wrong number | Passing percents; use `0.0 … 1.0`. |
| Settings set earlier in a chain are lost | A later `copyWith(appearance: …)` / `copyWith(behavior: …)` replaced them. |
| Icon animates on every update | Different glyph each time. The same `Icon(glyph)` re-created does not animate. |
| Tests leak bars between cases | Call `FluentBar.dismissAndClear()` in `tearDown`. |
| A bar of a screen is still there after the screen is closed | Bars live above the navigator. Tag it (`.withTag`) and wrap the screen in `FluentBarOwner`. |
| `ProviderNotFoundException` / no `BlocProvider` in a content builder | The builder is built above the navigator. Provide above `MaterialApp`, read the value before `show()`, or pass the object with `Provider.value` / `BlocProvider.value`. |
| A bar keeps the old language after the locale changes | Texts are plain strings. Show the bar again with the same `id`. |
| A screen reader reads every percent of a progress | It does not by default; check for `announceUpdates: true`. |
