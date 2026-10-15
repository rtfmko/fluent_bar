import 'package:fluent_bar/src/internal.dart';

/// Callbacks for the life of one bar.
///
/// ```dart
/// FluentBar.loading('Uploading').copyWith(
///   callbacks: FluentBarCallbacks(
///     onProgressCompleted: (item) => analytics.log('upload_done'),
///     onProgressFailed: (item) => analytics.log('upload_failed'),
///     onDismiss: (item, metrics) => analytics.log('upload_bar_closed', metrics.toMap()),
///   ),
/// ).show();
/// ```
class FluentBarCallbacks<T> {
  /// A custom haptic played when the bar appears, instead of the built-in one.
  final FutureOr<void> Function()? haptic;

  /// A custom haptic played when the progress completes, instead of the built-in one.
  final FutureOr<void> Function()? progressCompletedHaptic;

  /// Called when the bar appears on screen.
  final void Function(FluentBarItem<T> item)? onShow;

  /// Called when the bar is tapped; receives the payload.
  final void Function(T? payload)? onTap;

  /// Called when the bar is closed; receives the metrics.
  final void Function(FluentBarItem<T> item, FluentBarMetrics metrics)? onDismiss;

  /// Called when the progress completes.
  final void Function(FluentBarItem<T> item)? onProgressCompleted;

  /// Called when the progress is cancelled.
  final void Function(FluentBarItem<T> item)? onProgressCanceled;

  /// The progress ended with a failure (see `failProgress`).
  final void Function(FluentBarItem<T> item)? onProgressFailed;

  /// Creates a set of callbacks.
  const FluentBarCallbacks({this.haptic, this.progressCompletedHaptic, this.onShow, this.onTap, this.onDismiss, this.onProgressCompleted, this.onProgressCanceled, this.onProgressFailed});

  /// A copy with the given callbacks replaced; `null` keeps a callback.
  FluentBarCallbacks<T> copyWith({
    FutureOr<void> Function()? haptic,
    FutureOr<void> Function()? progressCompletedHaptic,
    void Function(FluentBarItem<T> item)? onShow,
    void Function(T? payload)? onTap,
    void Function(FluentBarItem<T> item, FluentBarMetrics metrics)? onDismiss,
    void Function(FluentBarItem<T> item)? onProgressCompleted,
    void Function(FluentBarItem<T> item)? onProgressCanceled,
    void Function(FluentBarItem<T> item)? onProgressFailed,
  }) => FluentBarCallbacks<T>(
    haptic: haptic ?? this.haptic,
    progressCompletedHaptic: progressCompletedHaptic ?? this.progressCompletedHaptic,
    onShow: onShow ?? this.onShow,
    onTap: onTap ?? this.onTap,
    onDismiss: onDismiss ?? this.onDismiss,
    onProgressCompleted: onProgressCompleted ?? this.onProgressCompleted,
    onProgressCanceled: onProgressCanceled ?? this.onProgressCanceled,
    onProgressFailed: onProgressFailed ?? this.onProgressFailed,
  );
}
