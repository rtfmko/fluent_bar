part of '../fluent_bar_controller_impl.dart';

/// The single source of truth about the lifetime of a bar.
///
/// A pure model: it knows nothing about timers, the manager or widgets. The state is a budget
/// ([total], `null` means persistent) and a [Stopwatch] that runs only while the bar is
/// spending time. Remaining and elapsed time are always computed, never accumulated by ticks,
/// so pausing, adding or subtracting time and changing the duration work at any moment and in
/// any order.
///
/// [Stopwatch] is monotonic: system clock changes and app suspension do not break it.
class _Lifetime {
  _Lifetime(this._watch, Duration? total) : _total = total?.nonNegative;

  final Stopwatch _watch;
  Duration? _total;

  Duration? get total => _total;

  bool get isTimed => _total != null;

  Duration get elapsed {
    final Duration? total = _total;
    if (total == null) return Duration.zero;

    final Duration spent = _watch.elapsed;
    return spent > total ? total : spent;
  }

  Duration get remaining {
    final Duration? total = _total;
    if (total == null) return Duration.zero;
    return total - elapsed;
  }

  /// Share of the time left (1.0 -> 0.0). 0.0 for a persistent bar and for a zero budget.
  double get remainingRatio {
    final Duration? total = _total;
    if (total == null || total <= Duration.zero) return 0.0;
    return (remaining.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0).toDouble();
  }

  /// Share of the time spent (0.0 -> 1.0). A zero budget counts as spent, a persistent one as untouched.
  double get elapsedRatio {
    final Duration? total = _total;
    if (total == null) return 0.0;
    if (total <= Duration.zero) return 1.0;
    return (elapsed.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0).toDouble();
  }

  /// A new budget from scratch. Whether the clock runs does not change.
  void reset(Duration? total) {
    _total = total?.nonNegative;
    _watch.reset();
  }

  /// A new budget that keeps the time already spent. A budget smaller than that means expired.
  void retarget(Duration? total) {
    if (total == null || _total == null) {
      reset(total);
      return;
    }
    _total = total.nonNegative;
  }

  /// Shifts the budget by [delta] (may be negative). The time spent does not change.
  void shift(Duration delta) {
    final Duration? total = _total;
    if (total == null) return;
    _total = (total + delta).nonNegative;
  }

  void start() {
    if (_total != null) _watch.start();
  }

  void stop() => _watch.stop();
}
