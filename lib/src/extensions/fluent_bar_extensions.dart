import 'package:fluent_bar/src/internal.dart';

/// Ends a chain: shows the draft.
///
/// ```dart
/// FluentBar.info('Hello').atBottom().show();
/// ```
extension FluentBarItemExt<T> on FluentBarItem<T> {
  /// Shows the bar, or queues it if its region is busy.
  ///
  /// Returns the entry to control the bar with, or `null` if the bar was dropped.
  ///
  /// ```dart
  /// final entry = FluentBar.info('Saving').persistent().show();
  /// entry?.close();
  /// ```
  FluentBarEntry<T>? show({OverlayState? overlayState}) => FluentBar.showItem(this, overlayState: overlayState);

  /// Shows the bar out of turn, replacing the one on screen.
  ///
  /// ```dart
  /// FluentBar.error('Session expired').force();
  /// ```
  FluentBarEntry<T>? force({OverlayState? overlayState}) => FluentBar.forceItem(this, overlayState: overlayState);
}

/// Shortcuts on a shown or queued bar.
///
/// ```dart
/// final entry = FluentBar.info('Uploading').withLinearProgress(value: 0).show();
/// entry?.updateValue(0.5);
/// entry?.completeProgress(message: 'Uploaded');
/// ```
extension FluentBarItemActionsX<T> on FluentBarEntry<T> {
  /// Whether the bar is shown out of turn.
  bool get isForce => currentItem.behavior.isForce;

  /// Shows the current content of this entry again as a bar.
  ///
  /// ```dart
  /// entry.show();
  /// ```
  FluentBarEntry<T>? show({OverlayState? overlayState}) => FluentBarManager.instance.show(item, overlayState: overlayState);

  /// Stops the countdown until [resume].
  ///
  /// ```dart
  /// entry.pause();
  /// ```
  void pause() => controller.pause();

  /// Continues the countdown stopped by [pause].
  ///
  /// ```dart
  /// entry.resume();
  /// ```
  void resume() => controller.resume();

  /// Shakes the bar sideways to draw attention.
  ///
  /// ```dart
  /// entry.shake();
  /// ```
  void shake({double intensity = 8.0, Duration duration = const Duration(milliseconds: 400), bool repeat = false}) => controller.shake(intensity: intensity, duration: duration, repeat: repeat);

  /// Makes the bar bounce once.
  ///
  /// ```dart
  /// entry.bounce();
  /// ```
  void bounce({double scale = 0.1, Duration duration = const Duration(milliseconds: 400), bool repeat = false}) => controller.bounce(scale: scale, duration: duration, repeat: repeat);

  /// Makes the bar pulse; with [repeat] it pulses until another effect replaces it.
  ///
  /// ```dart
  /// entry.pulse(repeat: true);
  /// ```
  void pulse({double scale = 1.05, Duration duration = const Duration(milliseconds: 600), bool repeat = false}) => controller.pulse(scale: scale, duration: duration, repeat: repeat);

  /// Plays a double-beat scale effect.
  ///
  /// ```dart
  /// entry.heartbeat();
  /// ```
  void heartbeat({double scale = 1.15, Duration duration = const Duration(milliseconds: 800), bool repeat = false}) => controller.heartbeat(scale: scale, duration: duration, repeat: repeat);

  /// Plays the effect drawn by `FluentBarAppearance.customEffectBuilder`.
  ///
  /// ```dart
  /// entry.customEffect(duration: const Duration(milliseconds: 700), repeat: true);
  /// ```
  void customEffect({double intensity = 1.0, Duration duration = const Duration(milliseconds: 500), bool repeat = false}) =>
      controller.customEffect(intensity: intensity, duration: duration, repeat: repeat);

  /// Plays the effect [type] with its default or the given settings.
  ///
  /// ```dart
  /// entry.triggerEffect(FluentBarEffect.shake);
  /// ```
  void triggerEffect(FluentBarEffect type, {double? intensity, Duration? duration, bool repeat = false}) => controller.triggerEffect(type, intensity: intensity, duration: duration, repeat: repeat);

  /// Replaces the action button; `null` removes it.
  ///
  /// ```dart
  /// entry.updateActions(null);
  /// ```
  void updateActions(FluentBarActions<T>? actions) => controller.updateActions(actions);

  /// Updates the progress. The `completed...` arguments apply at the moment it reaches the end.
  void updateProgress(FluentBarProgressState state, {String? completedMessage, String? completedTitle, FluentBarType? completedType}) =>
      controller.updateProgress(state, completedMessage: completedMessage, completedTitle: completedTitle, completedType: completedType);

  /// Updates the progress as "[current] of [total]".
  ///
  /// ```dart
  /// entry.updateFraction(3, 8);
  /// ```
  void updateFraction(int current, int total, {String? completedMessage, String? completedTitle, FluentBarType? completedType}) =>
      updateProgress(FluentBarProgressState.fraction(current, total), completedMessage: completedMessage, completedTitle: completedTitle, completedType: completedType);

  /// Updates the progress with a fraction from 0.0 to 1.0.
  ///
  /// ```dart
  /// entry.updateValue(0.42);
  /// ```
  void updateValue(double value, {String? completedMessage, String? completedTitle, FluentBarType? completedType}) =>
      updateProgress(FluentBarProgressState.value(value), completedMessage: completedMessage, completedTitle: completedTitle, completedType: completedType);

  /// Closes the bar with its exit animation, or removes it from the queue.
  ///
  /// ```dart
  /// entry.close();
  /// ```
  void close({FluentBarDismissReason reason = FluentBarDismissReason.manual}) => controller.close(reason: reason);

  /// Completes the progress with success and starts the usual countdown.
  ///
  /// ```dart
  /// entry.completeProgress(message: 'Uploaded', type: FluentBarType.success);
  /// ```
  void completeProgress({String? message, String? title, FluentBarType? type}) => controller.completeProgress(message: message, title: title, type: type);

  /// Completes the progress with a failure; the type becomes error unless [type] is given.
  ///
  /// ```dart
  /// entry.failProgress(message: 'Upload failed');
  /// entry.failProgress(message: 'Upload failed', retryLabel: 'Retry', onRetry: retry);
  /// ```
  ///
  /// With [retryLabel] and [onRetry] the bar gets a Retry button and waits for an answer
  /// ([isPersistent]); see `FluentBarController.failProgress`.
  void failProgress({String? message, String? title, FluentBarType? type, String? retryLabel, FutureOr<void> Function()? onRetry, bool? isPersistent}) =>
      controller.failProgress(message: message, title: title, type: type, retryLabel: retryLabel, onRetry: onRetry, isPersistent: isPersistent);

  /// Cancels the progress; with [dismiss] the bar is closed as well.
  ///
  /// ```dart
  /// entry.cancelProgress(fallbackMessage: 'Upload cancelled', fallbackType: FluentBarType.warning);
  /// ```
  void cancelProgress({String? fallbackMessage, FluentBarType? fallbackType, bool dismiss = false}) =>
      controller.cancelProgress(fallbackMessage: fallbackMessage, fallbackType: fallbackType, dismiss: dismiss);

  /// Shows this bar out of turn, replacing the one on screen.
  ///
  /// ```dart
  /// entry.force();
  /// ```
  FluentBarEntry<T> force({OverlayState? overlayState}) => FluentBarManager.instance.forceEntry(this, overlayState: overlayState);

  /// Changes the texts or the payload of the bar; omitted arguments stay as they are.
  /// [clearTitle] removes the title.
  ///
  /// ```dart
  /// entry.update(message: 'Almost there');
  /// ```
  void update({String? title, String? message, T? payload, bool clearTitle = false}) => controller.updateContent(title: title, message: message, payload: payload, clearTitle: clearTitle);

  /// Changes some settings of the behavior and keeps the rest.
  ///
  /// ```dart
  /// entry.patchBehavior((behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
  /// ```
  void patchBehavior(FluentBarBehavior Function(FluentBarBehavior current) update) => controller.patchBehavior(update);

  /// Changes some settings of the look and keeps the rest. Return a copy of `current`.
  ///
  /// ```dart
  /// entry.patchAppearance((appearance) => appearance.copyWith(backgroundColor: Colors.teal));
  /// ```
  void patchAppearance(FluentBarAppearance<dynamic> Function(FluentBarAppearance<T> current) update) => controller.patchAppearance(update);

  /// Updates a download or an upload counted in bytes.
  ///
  /// The first two arguments are what network libraries report, so the method can be passed as
  /// their progress callback. An unknown [total] (`null`, zero, negative) gives an indeterminate
  /// indicator that still shows how much has arrived; reaching [total] completes the progress.
  ///
  /// ```dart
  /// await dio.download(url, path, onReceiveProgress: entry.updateBytes);
  /// ```
  void updateBytes(int received, int? total, {FluentBarBytesLabel label = FluentBarBytesLabel.amount}) => updateProgress(FluentBarProgressBytes(received, total, label: label));

  /// Removes the action button.
  ///
  /// ```dart
  /// entry.removeAction();
  /// ```
  void removeAction() => controller.removeAction();

  /// Keeps the bar on screen until it is closed.
  ///
  /// ```dart
  /// entry.makePersistent();
  /// ```
  void makePersistent() => controller.makePersistent();

  /// Sets a new duration; `null` keeps the bar until it is closed. With [resetTimer] the countdown
  /// starts over, otherwise the time already passed counts.
  ///
  /// ```dart
  /// entry.updateDuration(const Duration(seconds: 4), resetTimer: true);
  /// ```
  void updateDuration(Duration? newDuration, {bool resetTimer = false}) => controller.updateDuration(newDuration, resetTimer: resetTimer);

  /// Gives the bar more time. A negative amount is reported as a warning and ignored.
  ///
  /// ```dart
  /// entry.addDuration(const Duration(seconds: 5));
  /// ```
  void addDuration(Duration extraDuration) => controller.addDuration(extraDuration);

  /// Takes time away from the bar. More than it has left, or a negative amount, is reported as a
  /// warning and ignored.
  ///
  /// ```dart
  /// entry.subtractDuration(const Duration(seconds: 2));
  /// ```
  void subtractDuration(Duration lessDuration) => controller.subtractDuration(lessDuration);
}

/// Turns a progress state into its text.
///
/// ```dart
/// const FluentBarProgressState.value(0.42).format(); // '42%'
/// const FluentBarProgressState.fraction(3, 8).format(); // '3 / 8'
/// const FluentBarProgressState.bytes(3250586, 52428800).format(); // '3.1 / 50 MB'
/// ```
extension FluentBarProgressStateLabel on FluentBarProgressState {
  /// Returns the text of this state; each kind can be formatted with its own callback.
  ///
  /// ```dart
  /// state.format(formatFraction: (current, total) => '$current of $total files');
  /// ```
  String format({String Function(double value)? formatValue, String Function(int current, int total)? formatFraction, String Function()? formatIndeterminate}) => switch (this) {
    FluentBarProgressValue(value: final double p) => formatValue?.call(p) ?? '${progressPercentOf(p)}%',
    FluentBarProgressFraction(current: final int c, total: final int t) => formatFraction?.call(c, t) ?? '$c / $t',
    FluentBarProgressBytes(text: final String text) => text,
    FluentBarProgressIndeterminate() => formatIndeterminate?.call() ?? '',
  };
}
