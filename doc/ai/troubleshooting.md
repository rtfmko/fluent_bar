# Troubleshooting

Version: 1.0.0. Read this when something behaves unexpectedly or the user reports a problem with a bar.
The rules in `AI_GUIDE.md` apply here too.

## Troubleshooting

Find the symptom, then apply the fix. Do not work around the library (timers, `Future.delayed`,
try/catch, a second bar): each case below has a direct answer.

| Symptom | Why | Fix |
|---|---|---|
| Nothing appears | no overlay; bars wait in the queue, an `overlay` warning is reported | `MaterialApp(builder: FluentBarScope.builder())`, or the observer / navigator key |
| `show()` returned `null` | dropped: the queue of its region was full (`maxQueueLength`, 15) or a custom strategy left it out; `queueOverflow` warning | raise `maxQueueLength`, give the bar a priority, or update an existing bar by `id` instead of showing new ones |
| A second bar instead of an update | missing or different `id`, policy `allow`, or another type argument for the same `id` | the same `id` and the same type argument; see `queue.md` |
| A bar does not close by itself | unfinished progress, `.persistent()`, the `banner` preset, or `failProgress` with a Retry button (waits for an answer) | finish the progress, or `updateDuration(…)` / `close()` |
| A bar lies over the bottom navigation while a dialog or sheet is open | the inset measured by `FluentBarBottomInset` / `FluentBarTopInset` is withdrawn while the screen is covered | `.withInsets(bottom: …)` on that bar: an inset on the bar beats the measured one. The keyboard is always taken into account |
| `addDuration` / `subtractDuration` changes nothing | no countdown (persistent, unfinished progress), not on screen yet or leaving, or a negative amount (`invalidCall` warning); more than is left is a `subtractDuration` warning | check the bar is visible and timed; pass a positive amount |
| No Retry button after `failProgress` | only one of `retryLabel` and `onRetry` was passed; `invalidCall` warning | pass both |
| `cancelProgress` did nothing | the bar had no progress, or it had already completed or failed | nothing to fix; `cancelProgress(dismiss: true)` still closes the bar |
| The text in place of the icon is `42%`, not `3 / 8` | in `position: replaceIcon` the text is always the percent | another position, for example `FluentBarProgressPosition.bottom` |
| The progress text lags behind fast updates | `fade`, `pop`, `roll`, `flip` play each change to the end, at most one every 120 ms; values in between are skipped, the last one always shows | expected; for a text that follows every update use `count` (default) or `none` |
| A bar with a `positionBuilder` waits although the other region is free | the region follows `position`, not the builder | also set the position (`.atBottom()` for a bar drawn at the bottom) |
| A bar left the screen after its position changed | the target region was busy; `queueNext` (default) makes it wait first in that queue | `.withRelocationStrategy(FluentBarRelocationStrategy.forceReplace)` or `.ignore` |
| An `error` bar stays 6 s although `defaultDuration` is 4 s | the built-in `error` type sets its own duration (and `high` priority, no swipe); a type beats the config | `typeOverrides: {FluentBarType.error: FluentBarType.error.copyWith(duration: …)}` or the duration on the bar |
| The icon of a type does not show | the bar has its own `.withIcon(…)`; the bar beats its type | remove the icon from the bar |
| Taps on the bar do nothing | `dismissOnTap(false)`, the `toast` / `banner` / `loading` presets, or the bar is loading (`setLoading` turns gestures off) | `.dismissOnTap()` on the bar, or finish the loading |
| Taps on the button do nothing | its handler still runs (a loader shows), or the second tap came within `throttleDuration` (400 ms) | expected; do not add your own debounce |
| A bar of a screen stays after the screen is closed | bars live above every navigator | `.withTag('screen')` and `FluentBarOwner(tag: 'screen', …)` in the screen; see `queue.md` |

```dart
// A bar shown while a dialog is open keeps clear of the bottom navigation under it.
FluentBar.error<void>('Could not save').withInsets(bottom: 80).show();

// Retry needs both the label and the callback.
entry.failProgress(message: 'Upload failed', retryLabel: 'Retry', onRetry: upload);
```
