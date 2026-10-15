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
