# Behavior

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## A close button

<p align="center"><img src="https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/close_button.gif" width="300" alt="A bar with a cross at the end that closes it"></p>

A cross at the end of the bar. It is off by default; turn it on for one bar, for a type or for
every bar. Useful on the web and desktop, where a swipe is awkward, and on bars that stay until closed.

```dart
FluentBar.info('A new version is ready').persistent().withCloseButton().show();

// For every bar:
FluentBar.patchConfig((config) => config.copyWith(defaultShowCloseButton: true));
```

- **It only closes the bar.** A running upload goes on; to stop the task give the bar a Cancel
  action (see [Download with Cancel](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md#download-with-cancel)).
- **It stands next to the action**, after it. A tap on the cross does not run the action and is
  not a tap on the bar: `onTap` is not called.
- **It works on a busy bar too**: while the bar is loading or its action runs, the cross is the
  way out if the task hangs.
- **Some bars keep it off** even when the config turns it on: the `snack`, `toast`, `banner` and
  `loading` presets and `.undismissible()` bars. `.withCloseButton()` on the bar brings it back.
- **Analytics** get the dismiss reason `closeButton` (part of `isByUser`) and the interaction `close`.
- **The look comes from the theme**: `closeIcon`, `closeIconSize`, `closeIconColor`,
  `closeButtonPadding` and `closeButtonAlignment` (`center` by default, `start` puts the cross at
  the top of a tall bar). One bar can bring its own icon (`.withCloseButton(icon: …)`), and so can a type
  (`FluentBarType.info.copyWith(closeIcon: …)`): the bar wins over the type, the type over the theme.
- **Screen readers** hear the "Close" label of the app localization; `closeButtonLabel` in the
  config replaces it (`copyWith(clearCloseButtonLabel: true)` brings the default back).
- **A custom content builder** replaces the standard content, the cross included. Put the
  ready-made `FluentBarCloseButton(controller: entry.controller)` where you need it.

```dart
final theme = FluentBarTheme.material.copyWith(
  closeIcon: (context, type, mode) => const Icon(Icons.cancel),
  closeButtonAlignment: (context, type, mode) => CrossAxisAlignment.start,
);
```

> **Demo:** [Behavior & gestures → Close button](https://rtfmko.github.io/fluent_bar/#/behavior/close-button) (`behavior/close-button`) · [Global config → Gestures](https://rtfmko.github.io/fluent_bar/#/config/gestures) (`config/gestures`) · [Playground → Gestures & feedback](https://rtfmko.github.io/fluent_bar/#/playground/gestures) (`playground/gestures`)<br>
> **API:** [`FluentBarCloseButton`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarCloseButton-class.html) · [`FluentBarTheme`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarTheme-class.html)

## Lifecycle

Every bar goes through the same states. Read the current one from
`entry.controller.stateNotifier` (a `ValueListenable<FluentBarLifecycleState>`).

| State | What it means |
|---|---|
| `queued` | Waiting: its region is busy, or there is no overlay yet. |
| `showing` | On screen, the entrance animation plays. Taps, swipes and the action button already work. |
| `visible` | In place. **The countdown starts here.** |
| `hiding` | Closing: the exit animation plays. |
| `dismissed` | Gone. The controller is disposed and ignores further calls. |

```dart
final entry = FluentBar.info<void>('Saved').show();

entry?.controller.stateNotifier.addListener(() {
  if (entry.controller.stateNotifier.value.isVisible) startReading();
});
```

The state answers questions itself, so there is nothing to compare by hand. Each state has its own
getter (`isQueued`, `isShowing`, `isVisible`, `isHiding`, `isDismissed`), and the questions that
cover several states have theirs:

| Getter | True for | Use it to ask |
|---|---|---|
| `isQueued` | `queued` | is it still waiting? |
| `isOnScreen` | `showing`, `visible`, `hiding` | is it drawn right now? |
| `isInteractive` | `showing`, `visible` | can the user tap it? |
| `isAnimating` | `showing`, `hiding` | is it moving? |
| `isFinished` | `hiding`, `dismissed` | is it too late to update it? |
| `isDismissed` | `dismissed` | is it gone? |

```dart
final state = entry.controller.stateNotifier.value;

if (state.isQueued) FluentBar.close('upload');            // drop it before it is shown
if (!state.isFinished) entry.update(message: 'Almost done');
```

Things that follow from it:

- **The duration of a bar is the time it stands still.** A 4 s bar with a 300 ms entrance is on
  screen for 4 s plus both animations. Time added during the entrance (`addDuration`) is kept.
- **Without an entrance animation** (`.withoutAnimations()`, a zero duration) `visible` follows
  `showing` at once.
- **An attention effect** requested before `visible` (`show()?.shake()`) plays when the bar gets there.
- **A bar closed while it was still appearing** goes `showing → hiding` and never becomes
  `visible`. Its metrics say `wasVisible: false`: an easy way to find bars nobody had time to read.
- **A bar that moves to the other region** and has to wait there goes back to `queued`.
- `onShow` and the `shown` analytics event fire when the bar appears (`showing`), `onDismiss` and
  `dismissed` when it is gone.

> **Demo:** [Monitor → Bars](https://rtfmko.github.io/fluent_bar/#/monitor/bars) (`monitor/bars`) · [Behavior & gestures → Entrance animations & haptics](https://rtfmko.github.io/fluent_bar/#/behavior/entrance-haptics) (`behavior/entrance-haptics`)<br>
> **API:** [`FluentBarLifecycleState`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarLifecycleState.html) · [`FluentBarController`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarController-class.html)

## Good to know

Three things follow from how bars work, and each has a short answer.

**A bar is above every screen and every navigator.** It stays when you switch a tab or pop a
route, and it is drawn over dialogs. Tie a bar to a screen with a tag and `FluentBarOwner`
(see [Bars of one screen](queue.md#bars-of-one-screen)).

**The texts are plain strings.** A bar that is on screen or in the queue keeps the language it
was created in. After the user changes the language, show the long-living bars again with the
same `id`: they are updated in place, without a new animation.

```dart
void onLocaleChanged(AppLocalizations l10n) {
  if (FluentBar.find('offline') != null) FluentBar.banner<void>(l10n.noConnection, id: 'offline').show();
}
```

**A content builder is built above the navigator.** It sees what is provided above `MaterialApp`
(or inside `MaterialApp.builder`, above `FluentBarScope`), and it does not see a `Provider` or a
`BlocProvider` created inside a screen. Read the value before showing the bar, or hand the object
over with `.value`: [State inside a bar](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/INTEGRATIONS.md#state-inside-a-bar).

