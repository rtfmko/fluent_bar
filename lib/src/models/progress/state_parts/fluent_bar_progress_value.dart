part of '../fluent_bar_progress_state.dart';

/// Progress as a fraction from 0.0 to 1.0.
class FluentBarProgressValue extends FluentBarProgressState {
  /// The fraction done, from 0.0 to 1.0.
  final double value;

  /// Creates a progress of [value], a fraction from 0.0 to 1.0.
  ///
  /// A value outside that range is not rejected here: a bar that gets one as an update ignores
  /// it and reports a warning, and [progress] keeps the indicator in range.
  const FluentBarProgressValue(this.value);

  @override
  double? get progress => value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();

  @override
  bool get isCompleted => value >= 1.0;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FluentBarProgressValue && value == other.value;

  @override
  int get hashCode => Object.hash(FluentBarProgressValue, value);
}
