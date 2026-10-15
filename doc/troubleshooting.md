# Troubleshooting

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Troubleshooting

Something does not behave as you expected? Find the symptom below. Each answer says why it
happens and what to do.

### Nothing appears

There is no overlay to show bars in. Set one up once, for example
`MaterialApp(builder: FluentBarScope.builder())`. Until then the bars wait in the queue, and the
error handlers get an `overlay` warning.

### `show()` returned `null`

The bar was dropped: its queue held `maxQueueLength` bars (15 by default, per region), or your
own queue strategy left it out. The error handlers get a `queueOverflow` warning.

### A second bar appears instead of an update

The two bars are not "the same bar" for the library: a missing or different `id`, the duplicate
policy `allow`, or a different type argument (`FluentBar.info<void>` and `FluentBar.info<Order>`
with one `id` are different bars, and the library warns about it).

### A bar does not close by itself

One of these keeps it: unfinished progress (finish it with `completeProgress`, `failProgress` or
`cancelProgress`), `.persistent()`, the `banner` preset, or `failProgress` with a Retry button,
which waits for an answer until the user taps something.

### A bar lies over the bottom navigation while a dialog or a sheet is open

While another screen, a dialog or a sheet covers the screen, the inset measured by
`FluentBarBottomInset` (and `FluentBarTopInset`) is withdrawn. An inset set on the bar is stronger
than the measured one, so give such a bar its own:

```dart
FluentBar.error<void>('Could not save').withInsets(bottom: 80).show();
```

The on-screen keyboard is always taken into account: with the keyboard open, bottom bars stay
above it anyway.

### `addDuration` or `subtractDuration` changes nothing

The bar has no countdown (it is persistent or has unfinished progress), it is not on screen yet
(still queued) or already leaving, or the amount is negative. A negative amount, and taking away
more than is left, are reported as warnings.

### `failProgress` showed no Retry button

`retryLabel` and `onRetry` go together. With only one of them the bar fails without the button,
and the error handlers get an `invalidCall` warning.

```dart
entry.failProgress(message: 'Upload failed', retryLabel: 'Retry', onRetry: upload);
```

### `cancelProgress` did nothing

The bar had no progress, or it had already completed or failed: there is nothing to cancel.
`cancelProgress(dismiss: true)` still closes the bar.

### The progress text in place of the icon shows `42%`, not `3 / 8`

In place of the icon there is room for a percent only, so a fraction, bytes and a `labelBuilder`
text show their percent there. For `3 / 8` or `3.1 / 50 MB` put the progress elsewhere, for
example `position: FluentBarProgressPosition.bottom`.

### The progress text lags behind fast updates

The text effects (`fade`, `pop`, `roll`, `flip`) play every change to the end and start one at
most every 120 ms. Values that arrive meanwhile are skipped and the latest one plays next, so the
text never flickers and always ends on the last value. For a text that follows every update use
the default `count` effect or `none`.

### A bar with a `positionBuilder` waits although the other region is free

The region, and so the queue, follows `position` (the bar, then its type, then the config). A
`positionBuilder` only moves where the bar is drawn. Set the position as well:
`.atBottom()` for a bar that a builder draws at the bottom.

### A bar left the screen after its position changed

The region it moved to was busy. With the default relocation strategy `queueNext` the bar plays
its exit and waits first in the queue of that region. Use `.withRelocationStrategy(…)`:
`forceReplace` takes the place at once, `ignore` keeps the bar where it is.

### An error bar stays 6 seconds although `defaultDuration` is 4

The built-in `error` type sets its own duration (and `high` priority, no swipe), and a type beats
the config. Change it for the whole app with `typeOverrides`, or set the duration on the bar.

### The icon of my type does not show

The bar has its own `.withIcon(…)`, and the bar beats its type. The order is the bar, then the
type, then the theme.

### Taps on the bar or its button do nothing

- On the bar: the bar does not close on tap (`dismissOnTap(false)`, or the `toast`, `banner` and
  `loading` presets), or it is loading (`setLoading` turns gestures off).
- On the button: its handler is still running (the button shows a loader), or the second tap came
  within 400 ms of the first (`throttleDuration`).

### A bar of a screen stays after the screen is closed

Bars are drawn above every navigator, so they survive a `pop`. Tag the bar and let the screen own
the tag: see [Bars of one screen](queue.md#bars-of-one-screen).

> **API:** [`FluentBarItem`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarItem-class.html) · [`FluentBarController`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarController-class.html) · [`FluentBarConfig`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarConfig-class.html)
