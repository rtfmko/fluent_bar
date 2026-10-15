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
