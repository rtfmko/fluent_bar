part of '../fluent_bar_progress_state.dart';

/// Progress without a known value: the work is running, the end is not known.
class FluentBarProgressIndeterminate extends FluentBarProgressState {
  /// Creates an indeterminate progress.
  const FluentBarProgressIndeterminate();

  @override
  double? get progress => null;

  @override
  bool get isCompleted => false;

  @override
  bool operator ==(Object other) => other is FluentBarProgressIndeterminate;

  @override
  int get hashCode => (FluentBarProgressIndeterminate).hashCode;
}
