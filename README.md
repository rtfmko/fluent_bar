# fluent_bar

[![pub package](https://img.shields.io/pub/v/fluent_bar.svg)](https://pub.dev/packages/fluent_bar)
[![CI](https://github.com/rtfmko/fluent_bar/actions/workflows/ci.yml/badge.svg)](https://github.com/rtfmko/fluent_bar/actions/workflows/ci.yml)
[![Live demo](https://img.shields.io/badge/demo-try%20it%20in%20the%20browser-7C3AED)](https://rtfmko.github.io/fluent_bar/)
[![API reference](https://img.shields.io/badge/docs-API%20reference-0EA5E9)](https://rtfmko.github.io/fluent_bar/api/)

Notification bars for Flutter: snackbar, toast, banner, progress and loading. They queue up
instead of piling on, can be changed while they are on screen, and never need a `BuildContext`.

```dart
FluentBar.showSuccess('Profile saved');
```

**[Try the live demo](https://rtfmko.github.io/fluent_bar/)**: every feature has a screen
you can play with, and each one shows the code behind it.

Each section below ends with two pointers:

- **Demo** - the screen in the live demo where this feature is shown, as *Screen → Section*. The
  link opens the demo on that section. The code in brackets, for example `(queue/duplicates)`, is a
  search query for the demo app: type it into the search field there to find the same section
  yourself, for example on a phone. The search also finds sections by an API name, such as
  `withAction`, `clearQueue` or `duplicateComparator`.
- **API** - the reference page with every parameter
  ([all classes](https://pub.dev/documentation/fluent_bar/latest/)).

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/hero.gif" width="300" alt="Five bars queue at the top while an upload shows progress at the bottom"></p>

**Start here:**
[Install](#install) ·
[Set up](#set-up-once) ·
[Show a bar](#show-a-bar) ·
[Recipes](#recipes) ·
[Update a bar](#change-a-bar-that-is-on-screen) ·
[Find and close](#find-and-close) ·
[Progress](#progress)

**Going further:**
[Regions and the queue](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/queue.md#regions-and-the-queue) ·
[Duplicates](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/queue.md#duplicates) ·
[Overriding settings](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/settings.md#overriding-settings) ·
[Themes](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/themes.md#themes) ·
[Types](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/types.md#types) ·
[Builders](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/builders.md#builders-replace-any-part) ·
[Global config](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/settings.md#global-config) ·
[Accessibility](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/accessibility.md#accessibility) ·
[Lifecycle](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/behavior.md#lifecycle) ·
[Analytics](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/analytics.md#analytics-and-metrics) ·
[Errors](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/errors.md#errors) ·
[Good to know](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/behavior.md#good-to-know) ·
[Troubleshooting](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/troubleshooting.md#troubleshooting) ·
[Reference](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/reference.md#reference) ·
[Other packages](#using-with-other-packages) ·
[AI assistants](#using-with-ai-assistants) ·
[Example](#example)

> **Using an AI coding assistant?** The package ships a full guide and ready-made rules for Cursor,
> Claude Code and `AGENTS.md`, so the assistant writes code for the version you have installed.
> See [Using with AI assistants](#using-with-ai-assistants).

## Why fluent_bar

- **One call from anywhere.** No `BuildContext`, no `ScaffoldMessenger`. Works from a bloc, a
  service, or `main()` before `runApp`.
- **A queue, not a pile.** One bar per region (top and bottom); the rest wait by priority.
- **Replace anything.** Content, position, transition, progress, button: each has a builder.
- **Bars are alive.** Change the text, type, progress, duration or position of a bar that is
  already on screen. The same `id` updates instead of duplicating.
- **Progress built in.** Linear or circular, a `Future` wrapper, and success / fail / cancel outcomes.
- **Themes and types.** Six built-in themes, your own with three methods, and types that bundle
  the defaults you would otherwise repeat in every call.
- **One rule for settings.** The bar, then its type, then the global config. Everywhere.
- **Your code cannot break it.** A throwing callback, builder, theme or type is reported and
  replaced by a default; the bar still appears.
- **Observable.** Fifteen analytics events and per-bar metrics: time on screen, time in the
  queue, how the user interacted, why it closed.
- **Considerate.** Screen-reader live region, system "reduce motion", keyboard avoidance,
  pause on touch.

## Install

```sh
flutter pub add fluent_bar
```

Requires Flutter 3.32 or newer.

## Set up once

Bars live in an overlay above the navigator, so they survive route changes:

```dart
import 'package:fluent_bar/fluent_bar.dart';

MaterialApp(
  builder: FluentBarScope.builder(),
  home: const HomePage(),
);
```

Alternatives: `navigatorObservers: [FluentBarObserver.instance]`, or
`FluentBar.initialize(config: …, navigatorKey: yourKey)`.

To keep bars clear of your app bar and bottom navigation, wrap them once:

```dart
Scaffold(
  appBar: FluentBarTopInset(child: AppBar(title: const Text('Inbox'))),
  bottomNavigationBar: FluentBarBottomInset(child: NavigationBar(destinations: destinations)),
);
```

While another screen, a dialog or a sheet covers the screen, its insets are withdrawn; the
on-screen keyboard is always taken into account, so bottom bars stay above it.

> **Demo:** [Quick start → Setup](https://rtfmko.github.io/fluent_bar/#/start/setup) (`start/setup`) · [Behavior & gestures → Below the app bar, above the bottom bar](https://rtfmko.github.io/fluent_bar/#/behavior/insets) (`behavior/insets`)<br>
> **API:** [`FluentBarScope`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarScope-class.html) · [`FluentBarObserver`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarObserver-class.html) · [`FluentBarTopInset`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarTopInset-class.html) · [`FluentBarBottomInset`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarBottomInset-class.html)

## Show a bar

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/show.gif" width="300" alt="A bar with a title, an action and a countdown line"></p>

Three ways, from shortest to most flexible:

```dart
// 1. One line.
FluentBar.showInfo('Copied to clipboard');
FluentBar.showError('Payment failed', title: 'Checkout');

// 2. A chain: a draft plus only what differs from the defaults.
FluentBar.success('Order #1042 has been shipped')
    .withTitle('On its way')
    .withAction('Track', onPressed: (controller, payload) => openTracking())
    .withTimeoutBar()
    .atBottom()
    .show();

// 3. Everything by hand.
FluentBar.show<void>(
  message: 'Ready',
  type: FluentBarType.success,
  options: const FluentBarOptions<void>(
    behavior: FluentBarBehavior(position: FluentBarPosition.bottom),
  ),
);
```

### Presets

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/presets.gif" width="300" alt="A pinned banner at the top and a snack with Undo at the bottom"></p>

```dart
FluentBar.showSnack('Message archived', action: 'Undo', onAction: (controller, _) => restore());
FluentBar.showToast('Saved');
FluentBar.showBanner('Changes will sync later.', title: 'You are offline', type: FluentBarType.warning);
final entry = FluentBar.showLoading<void>('Connecting…');
```

> **Demo:** [Quick start → One-liners](https://rtfmko.github.io/fluent_bar/#/start/one-liners) (`start/one-liners`) · [Quick start → The chain](https://rtfmko.github.io/fluent_bar/#/start/the-chain) (`start/the-chain`) · [Quick start → Presets](https://rtfmko.github.io/fluent_bar/#/start/presets) (`start/presets`) · [Playground](https://rtfmko.github.io/fluent_bar/#/playground) (`playground`)<br>
> **API:** [`FluentBar`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBar-class.html) · [`FluentBarItemBuilder`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarItemBuilder.html) · [`FluentBarOptions`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarOptions-class.html)

## Recipes

The bars apps need most often. Copy, paste, change the text.

### Saved

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_saved.gif" width="300" alt="A green success bar"></p>

```dart
FluentBar.showSuccess('Changes saved');
```

### A hint that never piles up

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_toast.gif" width="300" alt="A small toast that restarts instead of piling up"></p>

```dart
FluentBar.showToast('Copied', id: 'copied');
```

With an `id`, repeated taps update the toast on screen instead of queueing ten.

### Undo

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_undo.gif" width="300" alt="A bottom bar with an Undo button"></p>

```dart
FluentBar.showSnack('Conversation deleted', action: 'Undo', onAction: (controller, _) => restore());
```

### Error with Retry

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_retry.gif" width="300" alt="An error bar whose Retry button shows a loader, then the bar closes"></p>

```dart
FluentBar.error<void>('Could not load the feed')
    .persistent()
    .withAction('Retry', closeOnAction: false, onPressed: (controller, _) async {
      await loadFeed();      // the button shows a loader meanwhile
      controller.close();
    })
    .show();
```

With `closeOnAction: false` the bar stays while the work runs, with a loader on the button, and the
handler closes it. Without it a tap closes the bar at once and the handler runs after that.

### Loading, then the result

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_loading.gif" width="300" alt="A spinner bar that turns into a success bar"></p>

```dart
final loading = FluentBar.showLoading<void>('Signing in…', id: 'sign_in');
try {
  await auth.signIn();
  loading?.completeProgress(message: 'Welcome back', type: FluentBarType.success);
} catch (_) {
  loading?.failProgress(message: 'Wrong email or password');
}
```

### Upload with progress

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_upload.gif" width="300" alt="A bar with a progress line and a percent"></p>

```dart
final upload = FluentBar.info<void>('Uploading 12 photos')
    .withId('upload')
    .withLinearProgress(value: 0, showText: true)
    .atBottom()
    .show();

upload?.updateFraction(3, 12);
upload?.completeProgress(message: 'All photos uploaded', type: FluentBarType.success);
```

### Offline banner

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_offline.gif" width="300" alt="A pinned warning banner replaced by a Back online bar"></p>

```dart
FluentBar.banner<void>('Changes will sync later.', title: 'You are offline', type: FluentBarType.warning, id: 'network').show();

// Later: the same id replaces the banner instead of adding a second bar.
FluentBar.success<void>('Back online').withId('network').withDuration(const Duration(seconds: 2)).show();
```

### An alert that must be answered

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_alert.gif" width="300" alt="A persistent error bar with a Sign in button"></p>

```dart
FluentBar.error<void>('Your session has expired.')
    .withTitle('Sign in again')
    .forced()          // jumps the queue
    .persistent()      // no countdown
    .undismissible()   // no swipe, no tap, no close button
    .withAction('Sign in', onPressed: (controller, _) => openSignIn())
    .show();
```

### Download with Cancel

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_download.gif" width="300" alt="A download bar with a Cancel button that turns into a warning"></p>

```dart
final entry = FluentBar.info<void>('Downloading the map')
    .withId('download')
    .withLinearProgress(value: 0, showText: true)
    .withCancelButton(
      'Cancel',
      onCancel: () => download.cancel(),   // the button shows a loader meanwhile
      canceledMessage: 'Download cancelled',
      canceledType: FluentBarType.warning,
    )
    .show();

download.onProgress = (received, total) => entry?.updateBytes(received, total);
```

`withCancelButton` is the action of the bar with the routine built in:

- **On a tap** the bar stops following the progress and the button shows a loader while `onCancel`
  stops your task (the loader is visible only if `onCancel` is asynchronous). Then the progress is
  cancelled and the bar leaves by its timer.
- **If `onCancel` throws**, the error is reported and the bar follows the progress again.
- **If the task finishes or fails while it is being stopped**, that result stays.
- **What the stopped task still sends afterwards is ignored**, progress and a failure alike: the
  error a cancelled request ends with does not turn the bar red. To start over, show the bar again
  with the same `id`.
- **The button goes away with the progress**, whatever the outcome: a finished upload does not
  keep a Cancel button. Any action can do the same: `FluentBarActions(removeWhenProgressEnds: true)`.

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/retry.gif" width="300" alt="A download that fails at 60 percent, shows Retry and finishes on the second try"></p>

A failure can offer a second try on the same bar. `failProgress` with `retryLabel` puts a Retry
button in place of Cancel and keeps the bar until the user answers:

```dart
void download() {
  final entry = FluentBar.info<void>('Downloading the map')
      .withId('map')
      .withLinearProgress(value: 0, showText: true)
      .withCancelButton('Cancel', onCancel: task.cancel, canceledMessage: 'Download cancelled')
      .show();

  task.start(
    onProgress: (received, total) => entry?.updateBytes(received, total),
    onDone: () => entry?.completeProgress(message: 'Map downloaded', type: FluentBarType.success),
    onError: () => entry?.failProgress(
      message: 'Download failed',
      type: FluentBarType.warning,      // an error by default
      retryLabel: 'Retry',
      onRetry: download,                // the same id: the bar starts over in place
    ),
  );
}
```

A tap on Retry removes the button and calls `onRetry`. Showing the bar again with the same `id`
and a progress starts it over in place: the usual type, the indicator and Cancel are back.
`isPersistent: false` lets the failed bar leave by its timer even with the button. The hold ends
with the answer: a tap on Retry, another button, a new progress or duration, or the same `id` shown again. `retryLabel`
and `onRetry` go together: with only one of them the bar fails as usual without a Retry button, and
an `invalidCall` warning goes to your error handler.

> **Demo:** [Progress & futures → Fail and retry](https://rtfmko.github.io/fluent_bar/#/progress/retry) (`progress/retry`) · [Progress & futures → Cancel button](https://rtfmko.github.io/fluent_bar/#/progress/cancel-button) (`progress/cancel-button`)

### Cookie consent

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_consent.gif" width="300" alt="A bottom bar with an Accept button that stays until answered"></p>

```dart
FluentBar.info<void>('We use cookies to keep you signed in.')
    .atBottom()
    .persistent()
    .undismissible()
    .withoutIcon()
    .withAction('Accept')
    .show();
```

### Achievement

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/recipe_achievement.gif" width="300" alt="A purple bar in the center that pulses"></p>

```dart
FluentBar.success<void>('7 days in a row. Keep going!')
    .withTitle('Streak unlocked')
    .withBackground(const Color(0xFF7C3AED))
    .dark()
    .withIcon(const Icon(Icons.emoji_events_rounded), color: Colors.amberAccent)
    .withEntrance(FluentBarEntranceAnimation.elastic)
    .atCenter()
    .show()
    ?.heartbeat();
```

Label bars like these with `.withPreset('undo')` to tell them apart in logs and analytics.

### Popular settings

Every setting can be set on one bar or once for the whole app:

| I want… | On one bar | For the whole app (`FluentBarConfig`) |
|---|---|---|
| Bars at the bottom | `.atBottom()` | `defaultPosition: FluentBarPosition.bottom` |
| A longer or shorter life | `.withDuration(…)` | `defaultDuration` |
| A bar that stays until closed | `.persistent()` | - |
| A countdown line (or none) | `.withTimeoutBar()`, `.withoutTimeoutBar()` | `defaultShowTimeoutBar` |
| No swipe / no tap to close | `.swipeable(false)`, `.dismissOnTap(false)`, `.undismissible()` | `defaultIsSwipeEnabled`, `defaultDismissOnTap` |
| A close button | `.withCloseButton()`, `.withoutCloseButton()` | `defaultShowCloseButton: true` |
| Dark or light look | `.dark()`, `.light()` | `defaultThemeMode` |
| Another theme | `.withTheme(FluentBarTheme.minimal)` | `defaultTheme` |
| No icon / my icon | `.withoutIcon()`, `.withIcon(…)` | `defaultShowIcons` |
| Another entrance | `.withEntrance(FluentBarEntranceAnimation.fade)` | `defaultEntranceAnimation` |
| No animations at all | `.withoutAnimations()` | `defaultDisableAnimations: true` |
| Vibration | `.withHaptic(FluentBarHapticType.light)` | `enableHaptics` |
| A longer queue | - | `maxQueueLength` |

> **Demo:** [Quick start → Recipes](https://rtfmko.github.io/fluent_bar/#/start/recipes) (`start/recipes`)<br>
> **API:** [`FluentBar`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBar-class.html) · [`FluentBarItemBuilder`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarItemBuilder.html)

## Change a bar that is on screen

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/update.gif" width="300" alt="A bar that changes its text and type while visible"></p>

```dart
final entry = FluentBar.info<void>('Saving…').withId('save').persistent().show();

entry?.update(message: 'Uploading attachments');
entry?.controller.updateContent(type: FluentBarType.success, message: 'Saved');
entry?.controller.updateDuration(const Duration(seconds: 3), resetTimer: true);
entry?.patchBehavior((behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
entry?.patchAppearance((appearance) => appearance.copyWith(backgroundColor: Colors.teal));
entry?.shake();
entry?.close();

// Without the entry at hand:
FluentBar.find('save')?.update(message: 'Saved');
FluentBar.close('save');
```

Changing the type or theme of a visible bar fades to the new look. A bar that is moved to another
position fades in at its new place; if that region is busy it leaves, waits there and appears again.

> **Demo:** [Behavior & gestures → Control a live bar](https://rtfmko.github.io/fluent_bar/#/behavior/live-bar) (`behavior/live-bar`) · [Behavior & gestures → Moving a bar that is already shown](https://rtfmko.github.io/fluent_bar/#/behavior/relocation) (`behavior/relocation`) · [Behavior & gestures → Actions](https://rtfmko.github.io/fluent_bar/#/behavior/actions) (`behavior/actions`) · [Playground → Runtime control](https://rtfmko.github.io/fluent_bar/#/playground/runtime) (`playground/runtime`)<br>
> **API:** [`FluentBarEntry`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarEntry-class.html) · [`FluentBarItemActionsX`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarItemActionsX.html) · [`FluentBarController`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarController-class.html)

## Find and close

Give a bar an `id` and you can reach it from anywhere, without keeping the entry around.

| I want to... | Call |
|---|---|
| Get a bar that is shown or waiting | `FluentBar.find('save')` - returns its entry or `null` |
| Check what is on screen / in the queue | `FluentBar.activeItems`, `FluentBar.allQueue` |
| Close one bar | `FluentBar.close('save')` or `entry.close()` |
| Close the bar that is on screen | `FluentBar.closeActive()` |
| Clear the queue and close the visible bars with their animation | `FluentBar.closeAll()` |
| Get / close the bars of one screen or feature | `FluentBar.findByTag('checkout')` / `FluentBar.closeTag('checkout')`, or `FluentBarOwner` |
| Drop the waiting bars, keep the visible ones | `FluentBar.clearQueue()` |
| Remove everything at once, no animation | `FluentBar.dismissAndClear()` |

```dart
// In another class, with only the id at hand:
if (FluentBar.find('save') != null) FluentBar.close('save');

// Every bar of one screen (see "Bars of one screen" in doc/queue.md):
FluentBar.closeTag('checkout');
```

Every call here, and every other call into the library, is safe inside `initState`, `build` and
`dispose`: the change happens at once, and widgets listening to the library are told right after
the current frame.

`close` returns `false` when there is no bar with that `id`. A bar closed from code reports the
dismiss reason `manual`. In widget tests call `FluentBar.dismissAndClear()` in `tearDown`.

> **Demo:** [Quick start → Closing bars](https://rtfmko.github.io/fluent_bar/#/start/closing) (`start/closing`) · [Queue & duplicates → Clean up](https://rtfmko.github.io/fluent_bar/#/queue/clean-up) (`queue/clean-up`)<br>
> **API:** [`FluentBar`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBar-class.html) · [`FluentBarEntry`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarEntry-class.html)

## Progress

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/progress.gif" width="300" alt="A download bar with a progress line and the amount in megabytes"></p>

```dart
final entry = FluentBar.info<void>('Uploading photos')
    .withId('upload')
    .withLinearProgress(value: 0, showText: true)
    .show();

entry?.updateValue(0.42);                                    // 0.0 … 1.0
entry?.completeProgress(message: 'All photos uploaded', type: FluentBarType.success);
// or: entry?.failProgress(message: 'Upload failed');
// or: entry?.cancelProgress(fallbackMessage: 'Upload cancelled');
```

A bar with unfinished progress stays on screen; once it is finished the usual countdown starts.
`cancelProgress` on a bar whose progress has ended, or that has none, changes nothing.

A download or an upload reports bytes. `updateBytes` takes the same `(received, total)` pair that
network libraries give you, picks the unit for the text and copes with a missing size:

```dart
final download = FluentBar.info<void>('Downloading the map').withLinearProgress(showText: true).show();

download?.updateBytes(3250586, 52428800);   // 3.1 / 50 MB
download?.updateBytes(3250586, null);       // 3.1 MB and an indeterminate line: the size is unknown
```

More in [Using fluent_bar with other packages](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/INTEGRATIONS.md).

**Endless or not is decided by the value you pass, not by a setting.** The theme only chooses the
shape - a line (`withLinearProgress`) or a circle (`withCircularProgress`):

| You pass | The indicator |
|---|---|
| `value(0.4)`, `fraction(3, 8)`, `bytes(received, total)` | fills up to that point |
| `indeterminate()`, `bytes(received, null)` (also `0` or `-1`), or no value at all | endless |

The latest value wins, so one bar can switch: start endless while the size is unknown and turn
into a normal progress when it arrives, or the other way round.

In place of the icon (`position: FluentBarProgressPosition.replaceIcon`, the default of
`withCircularProgress` and also available to `withLinearProgress`) there is room for a percent
only, for a ring and for a line alike. A fraction, bytes and a `labelBuilder`
text show their percent there; bytes without a total show no text.

For a `Future`, one call does it all and hands the result back to you:

```dart
final user = await FluentBar.future<User>(
  api.saveProfile(),
  loading: 'Saving…',
  success: (user) => 'Profile of ${user.name} saved',
  error: (error) => 'Could not save',
);
```

> **Demo:** [Progress & futures → Three ways to update](https://rtfmko.github.io/fluent_bar/#/progress/update) (`progress/update`) · [Progress & futures → Cancel button](https://rtfmko.github.io/fluent_bar/#/progress/cancel-button) (`progress/cancel-button`) · [Progress & futures → Finishing a progress](https://rtfmko.github.io/fluent_bar/#/progress/finish) (`progress/finish`) · [Progress & futures → FluentBar.future](https://rtfmko.github.io/fluent_bar/#/progress/future) (`progress/future`) · [Progress & futures → Downloads in bytes](https://rtfmko.github.io/fluent_bar/#/progress/bytes) (`progress/bytes`) · [Progress & futures → Look of the indicator](https://rtfmko.github.io/fluent_bar/#/progress/look) (`progress/look`)<br>
> **API:** [`FluentBarProgressState`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarProgressState-class.html) · [`FluentBarProgressTheme`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarProgressTheme-class.html)

---

Everything above is enough for most apps. The rest is listed below.

## More in the library

The full documentation is in [`doc/`](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc):

- [Queue and duplicates](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/queue.md): regions, priorities, the queue strategies, duplicate rules, tags for one screen
- [Behavior](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/behavior.md): the close button, the lifecycle of a bar, and the things that follow from how bars work
- [Settings](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/settings.md): global config, and the order in which every setting is resolved
- [Themes](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/themes.md): built-in themes, tweaking one, light and dark, custom themes
- [Types](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/types.md): built-in types, variations, `typeOverrides`, custom types
- [Builders](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/builders.md): replace the content, position, transition or progress of a bar
- [Accessibility](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/accessibility.md): screen readers, reduce motion, and progress announcements
- [Analytics](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/analytics.md): events, metrics, and sending them to an analytics service
- [Errors](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/errors.md): every error type and severity, when it is reported and what the library does then
- [Troubleshooting](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/troubleshooting.md): a symptom, why it happens and what to do
- [Reference](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/reference.md): every public class, method and enum

## Using with other packages

`fluent_bar` needs no other package of yours (its own dependencies are Flutter, `cupertino_icons`
and `meta`). Copy-ready examples of using it together with popular
packages are in **[doc/INTEGRATIONS.md](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/INTEGRATIONS.md)**:

| For | Packages |
|---|---|
| Download and upload progress | `dio`, `http`, `firebase_storage` |
| Showing bars from your state layer | `flutter_bloc`, `provider`, `flutter_riverpod` |
| Sending bar events to analytics | `firebase_analytics` |
| Sending isolated errors to crash reports | `firebase_crashlytics`, `sentry_flutter` |
| An offline banner | `connectivity_plus` |
| Pushes that arrive while the app is open | `firebase_messaging` |
| Setting up the overlay with a router | `go_router` |

## Using with AI assistants

The package ships a reference written for AI coding assistants, so the code they write matches
the version you have installed.

[`AI_GUIDE.md`](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/AI_GUIDE.md) holds the rules and an
index; each file in [`doc/ai/`](https://github.com/rtfmko/fluent_bar/tree/v1.0.0/doc/ai) covers one
topic, so an assistant reads only what its task needs. Both are inside the package you installed.
[`ai/AGENTS.md`](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/ai/AGENTS.md) is a short text that
tells an assistant where to find them:

| You use | Do this |
|---|---|
| Cursor, Codex, Copilot agents, Gemini CLI, Windsurf and other agents that read `AGENTS.md` | Append `ai/AGENTS.md` to the `AGENTS.md` in your project root. For GitHub Copilot it also works in `.github/copilot-instructions.md`, for Gemini CLI in `GEMINI.md`. |
| Claude Code | The same, then add the line `@AGENTS.md` to the `CLAUDE.md` in your project root. |
| A chat assistant without access to your project | Attach `AI_GUIDE.md` and the files from `doc/ai/` your question is about. |
| A tool that fetches docs by URL | Point it at [`llms.txt`](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/llms.txt). |

## Example

The [`example`](https://github.com/rtfmko/fluent_bar/tree/v1.0.0/example) app is the
[live demo](https://rtfmko.github.io/fluent_bar/): a playground that generates the chain for the
bar you configure, a queue monitor, and a screen per feature. Run it locally with:

```sh
cd example
flutter run
```

## Contributing

Issues and pull requests are welcome. See
[CONTRIBUTING.md](https://github.com/rtfmko/fluent_bar/blob/main/CONTRIBUTING.md).

## Acknowledgements

Built with the help of [Claude](https://claude.ai/) by Anthropic.

If the package saves you time, you can [buy me a coffee on Ko-fi](https://ko-fi.com/rtfmko).

## License

See [LICENSE](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/LICENSE).
