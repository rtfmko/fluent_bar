part of '../fluent_bar_progress_state.dart';

/// Progress counted in items: [current] of [total].
class FluentBarProgressFraction extends FluentBarProgressState {
  /// How many items are done.
  final int current;

  /// How many items there are; must be greater than zero.
  final int total;

  /// Creates a progress of [current] out of [total].
  const FluentBarProgressFraction(this.current, this.total) : assert(current >= 0 && total > 0 && current <= total, 'A fraction needs total > 0 and 0 <= current <= total.');

  // The assert works only in debug; in release a zero total or an out-of-range value must not break the indicator.
  @override
  double? get progress => total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0).toDouble();

  @override
  bool get isCompleted => total > 0 && current >= total;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FluentBarProgressFraction && current == other.current && total == other.total;

  @override
  int get hashCode => Object.hash(FluentBarProgressFraction, current, total);
}
