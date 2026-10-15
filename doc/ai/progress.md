# Progress

Version: 1.0.0. Read this for a download, an upload, a task with progress, a `Future`, a Cancel or a Retry button.
The rules in `AI_GUIDE.md` apply here too.

## Progress

```dart
final entry = FluentBar.info<void>('Uploading photos')
    .withId('upload')
    .withLinearProgress(value: 0, showText: true)
    .show();

// Three equivalent ways to update. All work for a bar that is still waiting in the queue too.
entry?.updateValue(0.42);                                              // the entry
entry?.controller.updateProgress(const FluentBarProgressState.fraction(3, 8));   // the controller
FluentBar.info<void>('Uploading photos').withId('upload').withProgress(const FluentBarProgressState.value(0.6)).show(); // same id

// Finish. Each outcome has its own callback and analytics event.
entry?.updateValue(1.0, completedMessage: 'All photos uploaded', completedType: FluentBarType.success);
entry?.completeProgress(message: 'Uploaded', type: FluentBarType.success);
entry?.failProgress(message: 'Upload failed');                         // type becomes error
entry?.cancelProgress(fallbackMessage: 'Upload cancelled', fallbackType: FluentBarType.warning);
entry?.cancelProgress(dismiss: true);                                  // cancel and close
```

`cancelProgress` on a bar whose progress has ended, or that has none, changes nothing and fires
nothing; only `dismiss: true` still closes the bar.

- States: `FluentBarProgressState.value(0…1)`, `.fraction(current, total)`,
  `.bytes(received, total)`, `.indeterminate()`.
- Endless or not is decided by the state, not by a setting: `value`, `fraction` and `bytes` with a
  known total fill the indicator; `indeterminate()`, `bytes(received, null / 0 / -1)` and a bar
  created with `withLinearProgress()` without a value are endless. The theme chooses only the shape
  (`FluentBarProgressStyle.linear` / `circular`). The latest state wins, so one bar may go from
  endless to determinate and back.
- **Downloads and uploads: use bytes, do not convert to a fraction yourself.**
  `entry.updateBytes(received, total, {label})` takes the pair that network libraries report, so
  it can be passed as a callback (`onReceiveProgress: entry?.updateBytes`). It formats the text
  (`3.1 / 50 MB`), picks the unit, treats a `null`, zero or negative `total` as "size unknown"
  (indeterminate indicator, text `3.1 MB`) and never asserts on `received > total`. Reaching
  `total` completes the progress. `label`: `FluentBarBytesLabel.amount` (default), `percent`, `both`.
- A same-id re-show where both bars carry progress updates only progress, texts and type; the
  action, callbacks and look of the existing bar are kept.
- Look: `FluentBarProgressTheme(style, position, showText, textAlign, textEffect,
  textEffectDuration, animationDuration, thickness, size, progressColor, trackDecoration,
  successIcon, successIconColor, successIconDuration, textStyle, labelBuilder, progressBuilder,
  announceUpdates)`.
  It merges field by field across bar → type → config.
- With `position: replaceIcon` (the default of `withCircularProgress`; `withLinearProgress` takes
  it too) the text is always the percent, for a ring and for a line alike: a fraction, bytes and
  `labelBuilder` show their percent there, and a progress without one (indeterminate, bytes
  without a total) shows no text. For "3 / 8" or "3.1 / 50 MB" next to the bar use another
  position.
- The indicator animates by distance: a small step takes about 300 ms, a jump across the whole
  scale takes `animationDuration` (default 800 ms). No need to throttle or smooth updates yourself.
- The text effects (`fade`, `pop`, `roll`, `flip`) never cut a change short and start one at most
  every 120 ms: a text that arrives meanwhile waits, and only the latest one plays. The label does
  not dim: the new text is fully visible before the old one fades, `roll` slides without fading.

### A Future

```dart
final user = await FluentBar.future<User>(
  api.saveProfile(),
  loading: 'Saving…',
  success: (user) => 'Profile of ${user.name} saved',
  error: (e) => 'Could not save',
);
```

It returns the same future: the result and the exception still reach the caller.

### Download with a Cancel button

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

`withCancelButton(label, {child, onCancel, canceledMessage, canceledType})` is the action of the
bar (a later `withAction` replaces it, and it replaces an earlier one). Prefer it over a
hand-written `withAction('Cancel', closeOnAction: false, …)`; it handles the races:

- on a tap progress updates are ignored at once (through the entry, the controller and a same-id
  re-show); the button shows a loader while an asynchronous `onCancel` runs;
- `onCancel` threw: the error goes to the error handler, updates are followed again;
- the progress completed or failed while `onCancel` ran: that result stays, nothing is cancelled;
- after the cancellation late updates of the stopped task are ignored, `failProgress` included (a
  cancelled request usually ends with an error; there is no need to special-case it), so the bar
  closes by its timer; a new `show()` with the same id and a progress starts over;
- the button is removed when the progress ends in any way (`FluentBarActions.removeWhenProgressEnds`,
  usable for your own Pause button too). `cancelProgress()` called from code does not lock anything.

### Failure with Retry

`failProgress({message, title, type, retryLabel, onRetry, isPersistent})`. With `retryLabel` the
bar gets a Retry button in place of its action and is held on screen until the user answers
(`retryLabel` and `onRetry` go together: with only one of them the bar fails without a Retry
button and an `invalidCall` warning is reported; `isPersistent`
defaults to `true` with a Retry button and to `false` without; the item is not changed). The
hold ends with a tap on Retry, another button (`updateActions`, `removeAction`), a new progress
or duration, or the same `id` shown again; a new text, look or behavior keeps it. A progress that
goes on without a tap takes the Retry button away. A tap removes the button and calls `onRetry`
without awaiting it, so `onRetry` may be the whole task. Restart by showing the bar again with
the same `id` and a progress: it is updated in place. Do not hand-write this with `updateActions` and
`makePersistent`.

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
