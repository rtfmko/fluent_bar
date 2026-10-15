/// How often the countdown values of a bar are published to listeners, such as the timeout bar.
///
/// ```dart
/// FluentBar.patchConfig((config) => config.copyWith(defaultTimeoutUpdateInterval: FluentBarUpdateRate.fps60));
/// ```
class FluentBarUpdateRate {
  /// The time between two updates.
  final Duration interval;

  const FluentBarUpdateRate._(this.interval);

  /// Ten updates a second.
  static const FluentBarUpdateRate low = FluentBarUpdateRate._(Duration(milliseconds: 100));

  /// Twenty updates a second (the default).
  static const FluentBarUpdateRate medium = FluentBarUpdateRate._(Duration(milliseconds: 50));

  /// About thirty updates a second.
  static const FluentBarUpdateRate high = FluentBarUpdateRate._(Duration(milliseconds: 33));

  /// About sixty updates a second.
  static const FluentBarUpdateRate fps60 = FluentBarUpdateRate._(Duration(milliseconds: 16));

  /// About 120 updates a second, for high refresh rate screens.
  static const FluentBarUpdateRate fps120 = FluentBarUpdateRate._(Duration(milliseconds: 8));

  /// A custom rate; the interval is kept between 5 ms and 1 s.
  factory FluentBarUpdateRate(Duration duration) {
    const int minMs = 5;
    const int maxMs = 1000;

    final int ms = duration.inMilliseconds;

    if (ms <= 0) {
      return const FluentBarUpdateRate._(Duration(milliseconds: minMs));
    }

    final int clampedMs = ms.clamp(minMs, maxMs);
    return FluentBarUpdateRate._(Duration(milliseconds: clampedMs));
  }

  /// Same as the default constructor.
  factory FluentBarUpdateRate.custom(Duration duration) => FluentBarUpdateRate(duration);

  /// A custom rate given in milliseconds.
  factory FluentBarUpdateRate.ms(int milliseconds) => FluentBarUpdateRate(Duration(milliseconds: milliseconds));

  @override
  bool operator ==(Object other) => identical(this, other) || other is FluentBarUpdateRate && interval == other.interval;

  @override
  int get hashCode => interval.hashCode;

  @override
  String toString() => 'FluentBarUpdateRate(${interval.inMilliseconds}ms)';
}
