part of '../fluent_bar_progress_state.dart';

/// Progress counted in items: [current] of [total].
class FluentBarProgressFraction extends FluentBarProgressState {
  /// How many items are done.
  final int current;

  /// How many items there are; must be greater than zero.
  final int total;

  /// Creates a progress of [current] out of [total].
  ///
  /// A fraction needs `total > 0` and `0 <= current <= total`. Another one is not rejected here:
  /// a bar that gets one as an update ignores it and reports a warning, and [progress] keeps the
  /// indicator in range.
  const FluentBarProgressFraction(this.current, this.total);

  @override
  double? get progress => total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0).toDouble();

  @override
  bool get isCompleted => total > 0 && current >= total;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FluentBarProgressFraction && current == other.current && total == other.total;

  @override
  int get hashCode => Object.hash(FluentBarProgressFraction, current, total);
}
