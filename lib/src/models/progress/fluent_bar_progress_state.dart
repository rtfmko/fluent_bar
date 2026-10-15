import 'package:fluent_bar/src/models/fluent_bar_enums.dart';

part 'state_parts/fluent_bar_progress_bytes.dart';
part 'state_parts/fluent_bar_progress_fraction.dart';
part 'state_parts/fluent_bar_progress_indeterminate.dart';
part 'state_parts/fluent_bar_progress_value.dart';

/// The progress of a bar: a fraction, a count, a number of bytes or indeterminate.
///
/// ```dart
/// const FluentBarProgressState.value(0.42); // 42%
/// const FluentBarProgressState.fraction(3, 8); // 3 / 8
/// const FluentBarProgressState.bytes(3250586, 52428800); // 3.1 / 50 MB
/// const FluentBarProgressState.indeterminate(); // a spinner without a value
/// ```
sealed class FluentBarProgressState {
  const FluentBarProgressState();

  /// A progress without a value: the indicator runs endlessly.
  const factory FluentBarProgressState.indeterminate() = FluentBarProgressIndeterminate;

  /// A share of the whole, from `0.0` to `1.0`.
  const factory FluentBarProgressState.value(double value) = FluentBarProgressValue;

  /// A count out of a total: 3 files of 8.
  const factory FluentBarProgressState.fraction(int current, int total) = FluentBarProgressFraction;

  /// A download or an upload in bytes; a `null`, zero or negative [total] means the size is unknown.
  const factory FluentBarProgressState.bytes(int received, int? total, {FluentBarBytesLabel label}) = FluentBarProgressBytes;

  /// The progress as a fraction from 0.0 to 1.0; `null` when indeterminate.
  double? get progress;

  /// Whether the progress has reached the end.
  bool get isCompleted;
}
