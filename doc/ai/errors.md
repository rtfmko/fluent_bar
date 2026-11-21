# Errors

Version: 1.0.1. Read this to report the errors of the library to a crash reporter, or to find out what a reported error means.
The rules in `AI_GUIDE.md` apply here too.

## Errors

```dart
FluentBar.addErrorHandler((FluentBarException error, StackTrace stackTrace) {
  crashReporter.record(error.error, stackTrace, reason: error.type.displayName);
});
```

- A throw in your callback, builder, theme or type is caught, reported here and replaced by a
  default. The bar still appears.
- `error.severity.isWarning` is true for misuse the library recovered from, for example: no
  overlay to show bars in (`FluentBarErrorType.overlay`), queue overflow (`queueOverflow`), the
  same id with a different payload type (`payloadTypeMismatch`), arguments that do not fit
  together (`invalidCall`). `error.severity.isError` is true for a throw in your code and for a
  wrong setup. Send errors to a crash reporter and log warnings:
  ```dart
  FluentBar.addErrorHandler((FluentBarException error, StackTrace stackTrace) {
    if (error.severity.isWarning) {
      logger.warning('fluent_bar: ${error.type.displayName}: ${error.error}');
      return;
    }
    crashReporter.record(error.error, stackTrace, reason: error.type.displayName);
  });
  ```
- In debug builds every report is also printed to the console, with or without a handler. With no
  handler registered, a report with severity `error` goes to `FlutterError.reportError` (also in
  release builds); a `warning` is only printed in debug. Once a handler is registered, reports go
  only to the handlers.
- Nothing is thrown back at the caller: a call that fails is reported and leaves things as they were.
- `FluentBarException` fields: `type`, `severity`, `error` (the original exception), `stackTrace`.
  Its constructor takes `error`, `stackTrace`, `type` and `severity` (default `error`), and `toString`
  reads `FluentBarException [displayName]: error`, which helps in a test of a handler.
  `type.displayName` is `type.label` when the type has one, otherwise the name of the value.
- `FluentBar.removeErrorHandler(handler)` unregisters a handler. A handler that throws is not reported again.
- Every `FluentBarErrorType`, so a handler can switch on it:
  - builders: `customBuilderAppearance`, `customBuilderTransition`, `customBuilderEffect`,
    `customProgressBuilder`, `customButtonBuilder`, `fluentBarResolver`;
  - callbacks: `callbackShow`, `callbackTap`, `callbackDismiss`, `callbackProgressCompleted`,
    `callbackProgressFailed`, `callbackProgressCanceled`, `callbackAnalytics`,
    `callbackDuplicateComparator`, `actionPressed`, `patchCallback` (the callback of
    `patchAppearance`, `patchBehavior` or `patchConfig` threw; nothing is changed);
  - theme and type: `fluentBarTheme`, `fluentBarType`, `darkMode`;
  - queue strategy: `queueEnqueue`, `queueDequeue`; haptics: `hapticInternal`, `hapticExternal`;
  - warnings (misuse, recovered): `overlay`, `queueOverflow`, `payloadTypeMismatch`,
    `subtractDuration`, `invalidCall` (arguments that do not fit together), `patchCallback` when `patchAppearance` gets back an appearance of another
    payload type; setup, reported as an error: `initialization` (`initialize` called twice).

### What the library does after each type

| Type | When | What happens then |
|---|---|---|
| `customBuilderAppearance` | the content builder threw, or the widget it returned threw while built, laid out or painted (reported once) | default content |
| `customBuilderTransition` | the transition builder threw | no transition |
| `customBuilderEffect` | a custom effect builder threw | no effect |
| `customProgressBuilder` | `progressBuilder` threw | built-in indicator |
| `customButtonBuilder` | the action builder threw | no button, the bar stays |
| `fluentBarResolver` | a position builder, `labelBuilder` or a `FluentBar.future` text threw | the default for that part; a `future` text that threw counts as not given (the bar keeps its text, the type changes) |
| `callbackShow`, `callbackTap`, `callbackDismiss` | that callback threw | the bar goes on as if it had returned |
| `callbackProgressCompleted` / `Failed` / `Canceled` | that callback threw | the progress keeps its outcome |
| `callbackAnalytics` | a listener threw | the other listeners still get the event |
| `callbackDuplicateComparator` | `duplicateComparator` threw | the two bars count as different |
| `actionPressed` | `onPressed`, `onCancel` of `withCancelButton` or `onRetry` of `failProgress` threw | the loader goes away; a Cancel button lets the bar follow the progress again |
| `patchCallback` | a `patch…` callback threw (`error`) or `patchAppearance` got another payload type (`warning`) | nothing changes |
| `fluentBarTheme` | a theme method threw | the value of the base theme, or the built-in platform theme |
| `fluentBarType` | a getter of a custom type threw | the default of that getter |
| `darkMode` | `isDarkMode` of a theme threw (reported once per theme) | a subclass: the light variant; a `copyWith(isDarkMode:)`: the answer of the base theme |
| `queueEnqueue` / `queueDequeue` | a queue strategy threw | the bar goes to the end / the first bar is shown |
| `hapticInternal` / `hapticExternal` | haptic feedback failed | no vibration |
| `overlay` (`warning`) | no overlay to show bars in; reported once, only while the app runs and a bar waits, and again after an overlay has come and gone | bars wait in the queue |
| `overlay` (`error`) | inserting into the overlay failed | the bar whose insert failed is dropped |
| `queueOverflow` (`warning`) | the queue was full | the new bar is dropped, `show()` returns `null` |
| `payloadTypeMismatch` (`warning`) | the same `id` with another payload type; not reported with a `duplicateComparator` or the policy `allow` | the new bar is shown separately |
| `subtractDuration` (`warning`) | at least as much time taken as was left (a persistent bar is skipped silently) | the countdown is not changed |
| `invalidCall` (`warning`) | arguments that do not fit together: `failProgress` with only one of `retryLabel` and `onRetry`; a negative amount for `addDuration` / `subtractDuration`; a progress value outside `0…1` or a bad fraction passed to `updateValue` / `updateFraction` / `updateProgress`; a NaN or infinite intensity or scale for `shake`, `bounce`, `pulse`, `heartbeat`, `customEffect`, `triggerEffect` | the bar fails as usual, without a Retry button and without waiting for an answer; the other bad arguments are ignored |
| `initialization` (`error`) | `FluentBar.initialize` called twice | the call is ignored; use `updateConfig` / `patchConfig` |

A bad progress value does not assert: `FluentBarProgressState.value` outside `0.0 … 1.0` or a
`fraction` with `total <= 0` or `current` outside `0 … total` can be created, but passing it to
`updateValue`, `updateFraction` or `updateProgress` is ignored and reported as `invalidCall`.
