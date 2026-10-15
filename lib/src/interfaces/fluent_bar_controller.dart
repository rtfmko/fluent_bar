import 'package:fluent_bar/src/internal.dart';

/// Controls one bar while it is queued or on screen.
///
/// Get it from the entry returned by `show()`, from `FluentBar.find`, or as the first
/// argument of an action handler.
///
/// ```dart
/// final entry = FluentBar.info('Saving').persistent().show();
/// entry?.controller.updateContent(message: 'Saved', type: FluentBarType.success);
/// entry?.controller.updateDuration(const Duration(seconds: 2), resetTimer: true);
/// ```
abstract class FluentBarController<T> {
  /// The current content of the bar.
  ValueListenable<FluentBarItem<T>> get itemNotifier;

  /// Where the bar is in its life: queued, showing, visible, hiding or dismissed.
  ValueListenable<FluentBarLifecycleState> get stateNotifier;

  /// The time left before the bar closes.
  ValueListenable<Duration> get remainingDurationNotifier;

  /// The time the bar has spent counting down.
  ValueListenable<Duration> get elapsedDurationNotifier;

  /// The full lifetime of the bar; `null` for a persistent bar.
  ValueListenable<Duration?> get totalDurationNotifier;

  /// The share of the time left, from 1.0 down to 0.0.
  ValueListenable<double> get remainingProgressNotifier;

  /// The share of the time spent, from 0.0 up to 1.0.
  ValueListenable<double> get elapsedProgressNotifier;

  /// The progress as a fraction from 0.0 to 1.0; `null` without progress or when indeterminate.
  ValueListenable<double?> get taskProgressNotifier;

  /// The progress state; `null` when the bar has no progress.
  ValueListenable<FluentBarProgressState?> get progressStateNotifier;

  /// Whether an action handler is running or the bar is in the loading state.
  ValueListenable<bool> get isActionExecutingNotifier;

  /// Gives the bar more time. A negative amount is reported as a `FluentBarErrorType.invalidCall`
  /// warning and ignored.
  ///
  /// ```dart
  /// controller.addDuration(const Duration(seconds: 5));
  /// ```
  void addDuration(Duration extraDuration);

  /// Takes time away from the bar; more than is left is reported as a warning and ignored, and so
  /// is a negative amount (`FluentBarErrorType.invalidCall`).
  ///
  /// ```dart
  /// controller.subtractDuration(const Duration(seconds: 2));
  /// ```
  void subtractDuration(Duration lessDuration);

  /// Changes the texts, the payload or the type; omitted arguments stay as they are.
  /// [clearTitle] removes the title.
  ///
  /// ```dart
  /// controller.updateContent(message: 'Saved', type: FluentBarType.success);
  /// controller.updateContent(clearTitle: true);
  /// ```
  void updateContent({String? title, String? message, T? payload, FluentBarType? type, bool clearTitle = false});

  /// Changes some settings of the behavior and keeps the rest.
  ///
  /// ```dart
  /// controller.patchBehavior((behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
  /// ```
  void patchBehavior(FluentBarBehavior Function(FluentBarBehavior current) update);

  /// Replaces the whole behavior: settings missing from [behavior] go back to the type and the
  /// config. To change one setting use [patchBehavior].
  ///
  /// ```dart
  /// controller.updateBehavior(behavior: const FluentBarBehavior(position: FluentBarPosition.bottom));
  /// ```
  void updateBehavior({FluentBarBehavior? behavior, bool? isPersistent});

  /// Sets a new lifetime; `null` makes the bar persistent. With [resetTimer] the countdown starts over.
  ///
  /// ```dart
  /// controller.updateDuration(const Duration(seconds: 4), resetTimer: true);
  /// ```
  void updateDuration(Duration? newDuration, {bool resetTimer = false});

  /// Keeps the bar on screen until it is closed. The same as `updateDuration(null)`.
  ///
  /// ```dart
  /// controller.makePersistent();
  /// ```
  void makePersistent();

  /// Replaces the action button; `null` removes it.
  ///
  /// ```dart
  /// controller.updateActions(FluentBarActions(label: 'Retry', onPressed: (controller, _) => retry()));
  /// ```
  void updateActions(FluentBarActions<T>? actions);

  /// Removes the action button. The same as `updateActions(null)`.
  ///
  /// ```dart
  /// controller.removeAction();
  /// ```
  void removeAction();

  /// Changes some settings of the look and keeps the rest. Return a copy of `current`.
  ///
  /// ```dart
  /// controller.patchAppearance((appearance) => appearance.copyWith(backgroundColor: Colors.teal));
  /// ```
  void patchAppearance(FluentBarAppearance<dynamic> Function(FluentBarAppearance<T> current) update);

  /// Replaces the whole look: settings missing from [appearance] go back to the type, the theme
  /// and the config. To change one setting use [patchAppearance].
  ///
  /// ```dart
  /// controller.updateAppearance(const FluentBarAppearance(backgroundColor: Colors.teal));
  /// ```
  void updateAppearance(FluentBarAppearance<T> appearance);

  /// Updates the progress.
  ///
  /// The `completed...` arguments apply at the moment the progress reaches the end.
  ///
  /// ```dart
  /// controller.updateProgress(const FluentBarProgressState.value(0.42));
  /// ```
  void updateProgress(FluentBarProgressState newProgressState, {String? completedMessage, String? completedTitle, FluentBarType? completedType});

  /// Shows the bar out of turn, replacing the one on screen.
  ///
  /// ```dart
  /// controller.force();
  /// ```
  void force({OverlayState? overlayState});

  /// Runs an action the way the action button does: it shows the loader, holds the
  /// countdown, ignores repeated calls and closes the bar first if [closeOnAction] is set.
  ///
  /// ```dart
  /// await controller.handleAction(onPressed: (controller, payload) => api.retry());
  /// ```
  Future<void> handleAction({
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed,
    bool closeOnAction = true,
    Duration throttleDuration = const Duration(milliseconds: 400),
  });

  /// Closes the bar with its exit animation, or removes it from the queue.
  ///
  /// ```dart
  /// controller.close();
  /// ```
  void close({FluentBarDismissReason reason = FluentBarDismissReason.manual});

  /// Turns the loading state on or off: the action shows a loader and gestures are disabled.
  ///
  /// ```dart
  /// controller.setLoading(isLoading: true);
  /// ```
  void setLoading({required bool isLoading, bool? dismissOnTap, bool? isSwipeEnabled, bool pauseTimeoutTimer = true});

  /// Cancels the progress; with [dismiss] the bar is closed as well. Fires `onProgressCanceled`.
  ///
  /// A bar whose progress has already ended, or that has none, has nothing to cancel: the call
  /// changes nothing and fires nothing, only [dismiss] still closes the bar.
  ///
  /// ```dart
  /// controller.cancelProgress(fallbackMessage: 'Cancelled', fallbackType: FluentBarType.warning);
  /// ```
  void cancelProgress({String? fallbackMessage, FluentBarType? fallbackType, bool dismiss = false});

  /// Completes the progress with success: the indicator turns into the success icon, the bar takes
  /// the new texts and type (if given) and starts the usual countdown. Fires `onProgressCompleted`.
  void completeProgress({String? message, String? title, FluentBarType? type});

  /// Completes the progress with a failure: the indicator is removed, the bar takes the new texts and
  /// type ([FluentBarType.error] by default) and starts the usual countdown. Fires `onProgressFailed`.
  ///
  /// With [retryLabel] the bar gets a Retry button in place of its action. A tap removes the button
  /// and calls [onRetry], which starts the task again: show the bar again with the same id and a
  /// progress, or send a progress to this one. [retryLabel] and [onRetry] go together: with only
  /// one of them the bar fails without a Retry button, and a `FluentBarErrorType.invalidCall`
  /// warning goes to the error handlers.
  ///
  /// [isPersistent] keeps the failed bar on screen until the user answers: a tap on Retry, another
  /// button, a new progress or duration, or the same id shown again. A new text, look or behavior
  /// keeps the hold. It is `true` when there is a Retry button and `false` otherwise.
  ///
  /// A progress that goes on without a tap takes the Retry button away. A second failure of the
  /// same ended progress is ignored, and so is a failure after a cancellation by the Cancel
  /// button (`withCancelButton`): a stopped task usually ends with an error.
  ///
  /// ```dart
  /// entry.failProgress(message: 'Download failed', retryLabel: 'Retry', onRetry: retry);
  /// ```
  void failProgress({String? message, String? title, FluentBarType? type, String? retryLabel, FutureOr<void> Function()? onRetry, bool? isPersistent});

  /// Stops the countdown until [resume].
  ///
  /// ```dart
  /// controller.pause();
  /// ```
  void pause();

  /// Continues the countdown stopped by [pause].
  ///
  /// ```dart
  /// controller.resume();
  /// ```
  void resume();

  /// Shakes the bar sideways to draw attention.
  ///
  /// ```dart
  /// controller.shake();
  /// ```
  void shake({double intensity = 8.0, Duration duration = const Duration(milliseconds: 400), bool repeat = false});

  /// Makes the bar bounce once.
  ///
  /// ```dart
  /// controller.bounce();
  /// ```
  void bounce({double scale = 0.1, Duration duration = const Duration(milliseconds: 400), bool repeat = false});

  /// Makes the bar pulse; with [repeat] it pulses until another effect replaces it.
  ///
  /// ```dart
  /// controller.pulse(repeat: true);
  /// ```
  void pulse({double scale = 1.05, Duration duration = const Duration(milliseconds: 600), bool repeat = false});

  /// Plays a double-beat scale effect.
  ///
  /// ```dart
  /// controller.heartbeat();
  /// ```
  void heartbeat({double scale = 1.15, Duration duration = const Duration(milliseconds: 800), bool repeat = false});

  /// Plays the effect drawn by `FluentBarAppearance.customEffectBuilder`.
  ///
  /// ```dart
  /// controller.customEffect(repeat: true);
  /// ```
  void customEffect({double intensity = 1.0, Duration duration = const Duration(milliseconds: 500), bool repeat = false});

  /// Plays the effect [type] with its default or the given settings.
  ///
  /// ```dart
  /// controller.triggerEffect(FluentBarEffect.pulse);
  /// ```
  void triggerEffect(FluentBarEffect type, {double? intensity, Duration? duration, bool repeat = false});
}
