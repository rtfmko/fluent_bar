import 'package:fluent_bar/src/internal.dart';

/// The sum of two counters as one [ValueListenable].
///
/// The sum lives in its own [ValueNotifier], so listeners are notified only when it
/// changes, and an exception in one listener does not affect the others.
class CombinedValueListenable implements ValueListenable<int> {
  final ValueListenable<int> _main;
  final ValueListenable<int> _secondary;
  final ValueNotifier<int> _total;

  /// Listens to both counters and publishes their sum.
  CombinedValueListenable(this._main, this._secondary) : _total = FrameSafeValueNotifier<int>(_main.value + _secondary.value) {
    _main.addListener(_recalculate);
    _secondary.addListener(_recalculate);
  }

  void _recalculate() => _total.value = _main.value + _secondary.value;

  @override
  // Read from the sources: their listeners may be told about a change a frame later.
  int get value => _main.value + _secondary.value;

  @override
  void addListener(VoidCallback listener) => _total.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _total.removeListener(listener);

  /// Stops listening to the counters; the value no longer updates.
  void dispose() {
    _main.removeListener(_recalculate);
    _secondary.removeListener(_recalculate);
    _total.dispose();
  }
}
