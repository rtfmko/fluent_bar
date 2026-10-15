import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter/widgets.dart';

/// Makes a notifier safe to change while Flutter builds, lays out or tears down widgets.
///
/// The library is called from anywhere, including `initState`, `build` and `dispose`
/// (`FluentBar.close(id)` when a screen goes away is the most common case). At that moment
/// the widget tree is locked: a listener that calls `setState`, as every `ValueListenableBuilder`
/// does, throws. So during that phase of a frame the value still changes at once, but listeners
/// hear about it right after the frame.
mixin FrameSafeNotifier on ChangeNotifier {
  bool _hasPendingNotification = false;
  bool _wasDisposeRequested = false;

  static WidgetsBinding? _lockedBinding() {
    final WidgetsBinding binding;
    try {
      binding = WidgetsBinding.instance;
    } catch (_) {
      // No binding yet: nothing is being built, so nothing can be locked.
      return null;
    }
    return binding.schedulerPhase == SchedulerPhase.persistentCallbacks ? binding : null;
  }

  @override
  void notifyListeners() {
    if (_wasDisposeRequested) return;

    final WidgetsBinding? binding = _lockedBinding();
    if (binding == null) {
      super.notifyListeners();
      return;
    }

    if (_hasPendingNotification) return;
    _hasPendingNotification = true;

    binding.addPostFrameCallback((_) {
      _hasPendingNotification = false;
      if (_wasDisposeRequested) {
        // The last change (for example the `dismissed` state) must still reach the listeners.
        super.notifyListeners();
        super.dispose();
      } else {
        super.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    if (_wasDisposeRequested) return;

    // Listeners are still owed a notification: dispose after it has been delivered.
    if (_hasPendingNotification) {
      _wasDisposeRequested = true;
      return;
    }

    _wasDisposeRequested = true;
    super.dispose();
  }
}

/// A [ValueNotifier] that is safe to change during a frame; see [FrameSafeNotifier].
class FrameSafeValueNotifier<T> extends ValueNotifier<T> with FrameSafeNotifier {
  /// Creates a notifier with the initial [value].
  FrameSafeValueNotifier(super.value);
}
