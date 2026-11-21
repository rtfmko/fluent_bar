## 1.0.1

Bug fixes. No API changes.

### Queue and lifecycle

* A waiting bar removed by `close`, `closeAll`, `closeTag`, `clearQueue`, `dismissAndClear` or a `FluentBarOwner` leaving the tree now ends like a shown bar: `onDismiss` runs once and `dismissed` fires once, with the reason given to the call (`closeAll(reason:)`, `close(id, reason:)` and `closeTag(reason:)` no longer drop it for waiting bars).
* A waiting bar pushed out of the queue (by a forced bar, a lower `maxQueueLength`, a queue strategy or a relocation) gets `queueOverflow`, then `dismissed` with `dropped`, and `onDismiss` once. Before, it got no `dismissed` event and no `onDismiss`.
* The `onDismiss` and the events of waiting bars run after the call that ended them has finished with the queues, so a bar shown from such an `onDismiss` is not removed by that call.
* A bar that cannot be inserted into the overlay ends with `onDismiss` too (reason `manual`), like any other bar that ends.
* `FluentBar.forceItem` and forcing a bar find duplicates the way `show` does: forcing the id of a bar on screen or in the queue updates that bar instead of putting the id in two places.
* An `ignore` duplicate of a waiting progress bar passes on only its progress; it no longer changes the waiting bar's priority.
* `updateConfig`, `patchConfig` and a rebuilt `FluentBarScope` with an equal config do nothing: no rebuild of the bars, no queue rebalance.

### Errors

* With no error handler registered, errors (not warnings) go to `FlutterError.reportError`, in release builds too. Before, they were only printed in debug builds.
* A content widget (`withContent`, a type's `builder`, `defaultBuilder`), a custom icon or an action widget that throws while building, laying out or painting is reported and replaced by the default; Flutter's error widget no longer appears in the bar.
* `updateValue` / `updateFraction` with a value out of range, and `shake` / `pulse` with a non-finite intensity, are ignored and reported as an `invalidCall` warning instead of failing an assert. The asserts on `FluentBarProgressState.value` and `fraction` are gone.
* A theme's `isDarkMode` is called through the error handler: a throw is reported once per theme as `darkMode`; a theme subclass gets the light variant, a `copyWith(isDarkMode:)` the answer of the base theme.
* Listening to the notifiers of a bar that has ended no longer throws.
* Unpaired UTF-16 surrogates in a title, message, action label or progress label are replaced with U+FFFD instead of breaking the text.

### Progress

* `failProgress(isPersistent: false)` lets a persistent bar leave by its timer.
* `completeProgress` after `failProgress` takes the success type, unless a type is given.
* A progress re-show with the same id and no title removes the title.
* A completed ring leaves one icon; a linear indicator in place of the icon shows its whole label (`3 / 8`, `40%`); the label inside a ring is larger.

### Layout and look

* On very small screens and at large text scales the bar clips its content instead of overflowing.
* On narrow bars the action moves under the text, so the message keeps a usable width; the action keeps its state when it moves.
* `windows` theme, dark: the action text has a readable colour.
* The action throttle counts a fixed window from the last accepted tap, on the library clock.

### Docs and package

* The docs now match the code: corrected signatures, defaults and behaviour, and every public member is described in the guide for people and the guide for AI assistants.
* Working files no longer ship in the package (7 MB less).

## 1.0.0

Initial release.

* Bars shown in an overlay above the navigator: `FluentBarScope`, `FluentBarObserver` or a navigator key. No `BuildContext` needed.
* Three ways to show a bar: one-liners (`FluentBar.showSuccess`), a chain (`FluentBar.info(...).withTitle(...).show()`), and a full `FluentBar.show`.
* Presets: `snack`, `toast`, `banner`, `loading`.
* Two regions (top and bottom) with their own queues, priorities, forced bars and queue strategies (`smart`, `fifo`, `lifo`, custom).
* Duplicate policies (`update`, `updateAndResetTimer`, `ignore`, `allow`) and a custom duplicate comparator.
* Live updates of a visible bar through its controller, its entry (texts, look, behavior, duration with `updateDuration`, `addDuration`, `subtractDuration`), or a re-show with the same id; relocation between regions with a strategy.
* Progress: linear and circular indicators, value / fraction / bytes / indeterminate states, complete / fail / cancel outcomes, `FluentBar.future`.
* Actions with async handlers, a loader on the button and throttling; `analyticsName` gives a button a stable key in analytics (`action_name`).
* An optional close button: `.withCloseButton()`, `FluentBarType.showCloseButton`, `FluentBarConfig.defaultShowCloseButton`, styled by the theme, its icon set by the bar, the type (`FluentBarType.closeIcon`) or the theme, and `FluentBarCloseButton` for custom content.
* Themes: `material`, `cupertino`, `windows`, `minimal`, `modern`, `liquidGlass`, `copyWith`, and custom themes. Types: built-in, `copyWith`, custom, and global `typeOverrides`.
* One resolution order for every setting: the bar, then its type, then `FluentBarConfig`.
* Builders for content, position, transition, attention effect, progress indicator, label and action.
* `FluentBarTopInset` and `FluentBarBottomInset`; bottom bars stay above the on-screen keyboard.
* Getters on `FluentBarLifecycleState` (`isQueued`, `isShowing`, `isVisible`, `isHiding`, `isDismissed`, `isOnScreen`, `isInteractive`, `isAnimating`, `isFinished`) and on `FluentBarAnalyticsEvent` (`isLifecycle`, `isInteraction`, `isProgress`, `isRejected`, `isCountdown`, `hasMetrics`) and on `FluentBarDismissReason` (`isByUser`, `isByCode`, `isAutomatic`) and on `FluentBarErrorSeverity` (`isWarning`, `isError`).
* Tags: `.withTag()`, `FluentBar.closeTag()`, `FluentBar.findByTag()` and the `FluentBarOwner` widget, which closes the bars of a screen when it leaves the tree.
* `.withCancelButton()`: a Cancel action for a bar with progress, with the loader, the cancellation and the clean-up built in; `FluentBarActions.removeWhenProgressEnds` for your own buttons. `failProgress(retryLabel:, onRetry:)` offers a second try on the same bar; with only one of the two the bar fails without a Retry button and an `invalidCall` warning is reported.
* The dismiss gesture of a screen reader closes a bar with its own reason, `FluentBarDismissReason.accessibility`.
* Analytics events and per-bar metrics; error handlers with isolation of user callbacks, builders, themes and types. Nothing is thrown back at the caller: a call with arguments that do not fit together is reported as `FluentBarErrorType.invalidCall` and takes the safe way.
* Accessibility: `FluentBarSemantics` (`announce`, `quiet`, `hidden`) on the bar (`.withSemantics()`), the type and the config; progress values are not read out on every update; live region for screen readers, system "reduce motion" support, pause on touch.
* A guide for AI coding assistants that ships with the package: `AI_GUIDE.md` (rules and an index), one topic per file in `doc/ai/`, `doc/ai/migrations.md` for renamed API, a pointer for `AGENTS.md` in `ai/AGENTS.md`, and `llms.txt`.
