part of '../fluent_bar_controller_impl.dart';

class _ItemNotifier<T> extends ChangeNotifier with FrameSafeNotifier implements ValueListenable<FluentBarItem<T>> {
  _ItemNotifier(this._value);

  FluentBarItem<T> _value;

  @override
  FluentBarItem<T> get value => _value;

  set value(FluentBarItem<T> next) {
    final FluentBarItem<T> previous = _value;
    if (identical(previous, next)) return;

    _value = next;
    if (_isEquivalent<T>(previous, next)) return;

    notifyListeners();
  }

  /// Whether the bar must be rebuilt because of progress.
  ///
  /// The value itself is drawn by the indicator, which listens to `progressStateNotifier`.
  /// The bar cares only that progress appeared or went away, completed (that decides whether
  /// the bar is persistent) or changed its kind (value, fraction, indeterminate).
  static bool _sameProgressShape(FluentBarProgressState? a, FluentBarProgressState? b) {
    if (a == null || b == null) return a == b;
    return a.runtimeType == b.runtimeType && a.isCompleted == b.isCompleted;
  }

  static bool _isEquivalent<V>(FluentBarItem<V> a, FluentBarItem<V> b) =>
      a.isSameIgnoringProgress(b) &&
      _sameProgressShape(a.progressState, b.progressState) &&
      a.behavior.positionBuilder == b.behavior.positionBuilder &&
      _sameCallbacks<V>(a.callbacks, b.callbacks) &&
      _sameActions<V>(a.actions, b.actions) &&
      _sameAppearanceBuilders<V>(a.appearance, b.appearance);

  static bool _sameCallbacks<V>(FluentBarCallbacks<V>? a, FluentBarCallbacks<V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.haptic == b.haptic &&
        a.progressCompletedHaptic == b.progressCompletedHaptic &&
        a.onShow == b.onShow &&
        a.onTap == b.onTap &&
        a.onDismiss == b.onDismiss &&
        a.onProgressCompleted == b.onProgressCompleted &&
        a.onProgressCanceled == b.onProgressCanceled &&
        a.onProgressFailed == b.onProgressFailed;
  }

  static bool _sameActions<V>(FluentBarActions<V>? a, FluentBarActions<V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.onPressed == b.onPressed && a.builder == b.builder && a.child == b.child && a.actionLoadingWidget == b.actionLoadingWidget;
  }

  static bool _sameAppearanceBuilders<V>(FluentBarAppearance<V> a, FluentBarAppearance<V> b) {
    if (identical(a, b)) return true;
    return a.builder == b.builder &&
        a.transitionBuilder == b.transitionBuilder &&
        a.customEffectBuilder == b.customEffectBuilder &&
        // The indicator builders live inside the progress theme, whose equality ignores functions.
        a.progressTheme?.labelBuilder == b.progressTheme?.labelBuilder &&
        a.progressTheme?.progressBuilder == b.progressTheme?.progressBuilder;
  }
}
