part of '../fluent_bar_controller_impl.dart';

/// A value that is computed when read instead of being stored (time left, share elapsed).
///
/// Reading [value] is always up to date, no listener needed. [publish] notifies listeners,
/// and only if the value changed since the last time. [isObserved] tells whether there are
/// listeners: the controller uses it to decide whether the timer calling [publish] is needed.
class _LiveNotifier<T> extends ChangeNotifier with FrameSafeNotifier implements ValueListenable<T> {
  _LiveNotifier(this._read, this._onObservedChanged) : _published = _read();

  final T Function() _read;
  final VoidCallback _onObservedChanged;

  T _published;
  bool _isDisposed = false;

  @override
  T get value => _read();

  bool get isObserved => !_isDisposed && hasListeners;

  void publish() {
    final T next = _read();
    if (next == _published) return;

    _published = next;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    // The bar has ended: there is nothing more to hear (see [_EndedSafeValueNotifier]).
    if (_isDisposed) return;
    final bool wasObserved = isObserved;
    super.addListener(listener);
    if (!wasObserved) _onObservedChanged();
  }

  @override
  void removeListener(VoidCallback listener) {
    final bool wasObserved = isObserved;
    super.removeListener(listener);
    if (wasObserved && !isObserved) _onObservedChanged();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// A notifier of the controller that may still be listened to after the bar has ended.
///
/// The code that shows a bar keeps its entry and may add or remove a listener at any time,
/// also after the end. A disposed [ChangeNotifier] throws on `addListener`; this one ignores it:
/// the bar will not change any more. `removeListener` is always allowed.
class _EndedSafeValueNotifier<T> extends FrameSafeValueNotifier<T> {
  _EndedSafeValueNotifier(super.value);

  bool _isEnded = false;

  @override
  void addListener(VoidCallback listener) {
    if (_isEnded) return;
    super.addListener(listener);
  }

  @override
  void dispose() {
    _isEnded = true;
    super.dispose();
  }
}
