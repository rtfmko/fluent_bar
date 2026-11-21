# Errors

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.1/README.md)

The library never lets your code break a bar or the app. When a callback, builder, theme, type
or queue strategy throws, or when a call cannot be done as asked, the library catches it, reports
it to your error handlers and goes on with a safe default. Nothing is thrown back at the caller.

## Receiving the reports

```dart
FluentBar.addErrorHandler((FluentBarException error, StackTrace stackTrace) {
  crashReporter.record(error.error, stackTrace, reason: error.type.displayName);
});
```

A handler gets a `FluentBarException` and its stack trace:

| Field | What it holds |
|---|---|
| `type` | which part failed, a `FluentBarErrorType` (below) |
| `severity` | `warning` or `error`, a `FluentBarErrorSeverity` (below) |
| `error` | the original exception your code threw, or a `StateError` / `ArgumentError` that describes the misuse |
| `stackTrace` | where it happened |

`error.type.displayName` is a short readable name for logs, for example `Callback: OnTap`; `type.label`
is the same text when the type has one (`null` otherwise). `FluentBarException` has a constructor
(`error`, `stackTrace`, `type`, and `severity`, which defaults to `error`) and a `toString` that reads
`FluentBarException [Callback: OnTap]: <error>`; both are handy for a test of your handler.
`FluentBar.removeErrorHandler(handler)` unregisters a handler. A handler that throws itself is
not reported again. In debug builds every report is also printed to the console with a
`[FluentBar]` prefix, whether a handler is registered or not. With no handler registered, a report
with the severity `error` also goes to `FlutterError.reportError`, in release builds too, so your
`FlutterError.onError` and crash reporter see it; a `warning` is only printed in debug builds. Once
you register a handler, the reports go to the handlers only.

## Severity

| `FluentBarErrorSeverity` | Meaning | What to do |
|---|---|---|
| `warning` (`severity.isWarning`) | A call was used in a way the library does not support, and it recovered: the bar was dropped, shown separately or left as it was. | Fix the call. Usually worth a log entry, not a crash report. |
| `error` (`severity.isError`) | Your code threw, or the setup is wrong. The library replaced the result with a default. | Fix your code. Send it to your crash reporter. |

A handler that sends only real failures to a crash reporter and logs the rest:

```dart
FluentBar.addErrorHandler((FluentBarException error, StackTrace stackTrace) {
  if (error.severity.isWarning) {
    logger.warning('fluent_bar: ${error.type.displayName}: ${error.error}');
    return;
  }
  crashReporter.record(error.error, stackTrace, reason: error.type.displayName);
});
```

## Every error type

Each row says when the report comes and what the library does after it.

### Builders

| `FluentBarErrorType` | When | What the library does |
|---|---|---|
| `customBuilderAppearance` | The content builder (`withContent`, `FluentBarType.builder`, `FluentBarConfig.defaultBuilder`) threw. | Draws the bar with the default content. The same when the widget the builder returned threw while it was built, laid out or painted: reported once. |
| `customBuilderTransition` | The transition builder threw. | Shows the bar without the transition. |
| `customBuilderEffect` | A custom attention effect builder threw. | Draws the bar without the effect. |
| `customProgressBuilder` | `FluentBarProgressTheme.progressBuilder` threw. | Draws the built-in indicator. |
| `customButtonBuilder` | The builder of the action button threw. | Leaves the place of the button empty. The bar stays. |
| `fluentBarResolver` | A position builder, `FluentBarProgressTheme.labelBuilder`, or the `success` / `error` text of `FluentBar.future` threw. | Uses the default: the bar without the position builder, the default progress text. A `FluentBar.future` text that threw is treated as not given: the bar keeps its text and only the type changes. |

### Callbacks

| `FluentBarErrorType` | When | What the library does |
|---|---|---|
| `callbackShow` | `onShow` threw. | The bar stays on screen. |
| `callbackTap` | `onTap` threw. | The tap is counted; the bar is closed if it closes on tap. |
| `callbackDismiss` | `onDismiss` threw. | The bar is already closed; the next one is shown. |
| `callbackProgressCompleted` | `onProgressCompleted` threw. | The progress is still completed. |
| `callbackProgressFailed` | `onProgressFailed` threw. | The progress is still failed. |
| `callbackProgressCanceled` | `onProgressCanceled` threw. | The progress is still cancelled. |
| `callbackAnalytics` | An analytics listener threw. | The other listeners still get the event. |
| `callbackDuplicateComparator` | `FluentBarConfig.duplicateComparator` threw. | Treats the two bars as different. |
| `actionPressed` | The `onPressed` of an action threw, including `onCancel` of `withCancelButton` and `onRetry` of `failProgress`. | Removes the loader from the button. A Cancel button lets the bar follow the progress again; a Retry button is already gone. |
| `patchCallback` | The callback of `patchAppearance`, `patchBehavior` or `FluentBar.patchConfig` threw (`error`), or `patchAppearance` got back an appearance of another payload type (`warning`). | Changes nothing. |

### Themes, types and queue strategies

| `FluentBarErrorType` | When | What the library does |
|---|---|---|
| `fluentBarTheme` | A method of a theme threw. | Takes the value from the base theme, or draws the whole bar with the built-in theme of the platform. |
| `fluentBarType` | A getter of a custom `FluentBarType` threw. | Uses the default value of that getter. |
| `darkMode` | `FluentBarTheme.isDarkMode` threw. Reported once per theme. | A theme subclass that throws gets the light variant. A `copyWith(isDarkMode: …)` that throws gets the answer of the base theme. |
| `queueEnqueue` | `onEnqueue` of a queue strategy threw. | Puts the bar at the end of the queue. |
| `queueDequeue` | `onDequeue` of a queue strategy threw. | Shows the first bar of the queue. |

### Haptics

| `FluentBarErrorType` | When | What the library does |
|---|---|---|
| `hapticInternal` | The built-in haptic feedback failed on the platform. | No vibration. |
| `hapticExternal` | A custom haptic callback threw. | No vibration. |

### Misuse, reported as a warning

| `FluentBarErrorType` | When | What the library does |
|---|---|---|
| `overlay` | Bars wait and there is nowhere to show them: no `FluentBarScope`, no `FluentBarObserver`, no `navigatorKey`. Reported once, and only when the app is running and a bar is waiting; it can be reported again after an overlay has appeared and gone. | Keeps the bars in the queue and shows them once an overlay appears. |
| `queueOverflow` | A bar was shown while its queue held `maxQueueLength` bars. | Drops the new bar; `show()` returns `null`. Analytics gets `queueOverflow`. |
| `payloadTypeMismatch` | A bar was shown with the `id` of a bar on screen that has another payload type, so it cannot update it. Not reported when `duplicateComparator` is set or the policy is `allow`. | Shows the new bar separately. |
| `subtractDuration` | `subtractDuration` asked for at least as much time as the bar had left. A persistent bar has no countdown and is skipped without a report. | Leaves the countdown as it was. |
| `invalidCall` | A call got arguments that do not fit together: `failProgress` with `retryLabel` but no `onRetry`, or `onRetry` but no `retryLabel`; `addDuration` or `subtractDuration` with a negative amount; `updateValue`, `updateFraction` or `updateProgress` with a value outside `0 … 1` (or a fraction with `total <= 0` or `current` outside `0 … total`); `shake`, `bounce`, `pulse`, `heartbeat`, `customEffect` or `triggerEffect` with a NaN or infinite intensity or scale. | Takes the safe way: the bar fails as usual, without a Retry button and without waiting for an answer; a negative amount, a bad progress value or a bad effect argument is ignored. |

### Setup, reported as an error

Inserting a bar into the overlay can fail as well, for example when the overlay was passed in
broken. That is reported as `overlay` with the severity `error`, and the bar whose insert failed is
dropped.

| `FluentBarErrorType` | When | What the library does |
|---|---|---|
| `initialization` | `FluentBar.initialize` was called a second time. | Ignores the call. To change settings later use `FluentBar.updateConfig` or `FluentBar.patchConfig`. |

## Bad progress values

A progress value outside `0.0 … 1.0` (a percent passed by mistake, `value(42)`) or a fraction with
`total <= 0` or `current` outside `0 … total` does not assert and does not throw. The state can be
created, but when it is passed to `updateValue`, `updateFraction` or `updateProgress` the call is
ignored and an `invalidCall` warning is reported. Clamp the value first if you want the bar to move.

> **Demo:** [Analytics & safety → When your code throws](https://rtfmko.github.io/fluent_bar/#/analytics/errors) (`analytics/errors`)<br>
> **API:** [`FluentBarException`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarException-class.html) · [`FluentBarErrorType`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarErrorType.html) · [`FluentBarErrorSeverity`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarErrorSeverity.html)
