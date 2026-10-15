part of '../fluent_bar_type.dart';

/// A guard around a user-defined type.
///
/// The getters of a type are user code: in a subclass of [FluentBarType] any of them may throw.
/// The library reads them in dozens of places (show, queue, timers, widget build), so they are
/// guarded once at the source: on a throw the error goes to the handler
/// ([FluentBarErrorType.fluentBarType]) and the default value is used.
///
/// Builders and callbacks are returned as they are: resolvers guard their calls.
class _SafeFluentBarType extends FluentBarType {
  final FluentBarType _base;

  const _SafeFluentBarType(this._base);

  /// Defaults come from a "clean" type so that they never drift from [FluentBarType].
  static const FluentBarType _defaults = _DefaultFluentBarType();

  T _read<T>(String name, T Function(FluentBarType type) read) =>
      FluentBarErrorHandler.instance.executeSafe<T>(overrideCall: () => read(_base), fallbackCall: () => read(_defaults), type: FluentBarErrorType.fluentBarType, debugContext: name);

  @override
  String get name => _read('name', (FluentBarType t) => t.name);

  // If kind cannot be read, the type counts as standalone (like any custom type).
  @override
  FluentBarType get kind =>
      FluentBarErrorHandler.instance.executeSafe<FluentBarType>(overrideCall: () => _base.kind, fallbackCall: () => this, type: FluentBarErrorType.fluentBarType, debugContext: 'kind');

  @override
  bool? get isSwipeEnabled => _read('isSwipeEnabled', (FluentBarType t) => t.isSwipeEnabled);

  @override
  bool? get isPersistent => _read('isPersistent', (FluentBarType t) => t.isPersistent);

  @override
  bool? get disableAnimations => _read('disableAnimations', (FluentBarType t) => t.disableAnimations);

  @override
  bool? get dismissOnTap => _read('dismissOnTap', (FluentBarType t) => t.dismissOnTap);

  @override
  bool? get pauseOnTouch => _read('pauseOnTouch', (FluentBarType t) => t.pauseOnTouch);

  @override
  FluentBarSemantics? get semantics => _read('semantics', (FluentBarType t) => t.semantics);

  @override
  double? get topInset => _read('topInset', (FluentBarType t) => t.topInset);

  @override
  double? get bottomInset => _read('bottomInset', (FluentBarType t) => t.bottomInset);

  @override
  bool? get showIcon => _read('showIcon', (FluentBarType t) => t.showIcon);

  @override
  bool? get showTimeoutBar => _read('showTimeoutBar', (FluentBarType t) => t.showTimeoutBar);

  @override
  bool? get showCloseButton => _read('showCloseButton', (FluentBarType t) => t.showCloseButton);

  @override
  Widget? get closeIcon => _read('closeIcon', (FluentBarType t) => t.closeIcon);

  @override
  bool? get useSafeArea => _read('useSafeArea', (FluentBarType t) => t.useSafeArea);

  @override
  FluentBarThemeMode? get themeMode => _read('themeMode', (FluentBarType t) => t.themeMode);

  @override
  Color? get backgroundColor => _read('backgroundColor', (FluentBarType t) => t.backgroundColor);

  @override
  Color? get timeoutBarColor => _read('timeoutBarColor', (FluentBarType t) => t.timeoutBarColor);

  @override
  Duration? get duration => _read('duration', (FluentBarType t) => t.duration);

  @override
  Duration? get transitionDuration => _read('transitionDuration', (FluentBarType t) => t.transitionDuration);

  @override
  Duration? get reverseTransitionDuration => _read('reverseTransitionDuration', (FluentBarType t) => t.reverseTransitionDuration);

  @override
  FluentBarPosition? get position => _read('position', (FluentBarType t) => t.position);

  @override
  DismissDirection? get dismissDirection => _read('dismissDirection', (FluentBarType t) => t.dismissDirection);

  @override
  FluentBarHapticType get haptic => _read('haptic', (FluentBarType t) => t.haptic);

  @override
  FluentBarHapticType get progressCompletedHaptic => _read('progressCompletedHaptic', (FluentBarType t) => t.progressCompletedHaptic);

  @override
  FluentBarPriority get priority => _read('priority', (FluentBarType t) => t.priority);

  @override
  FluentBarEntranceAnimation? get entranceAnimation => _read('entranceAnimation', (FluentBarType t) => t.entranceAnimation);

  @override
  FluentBarTimeoutBarDirection? get timeoutBarDirection => _read('timeoutBarDirection', (FluentBarType t) => t.timeoutBarDirection);

  @override
  FluentBarTimeoutBarPosition? get timeoutBarPosition => _read('timeoutBarPosition', (FluentBarType t) => t.timeoutBarPosition);

  @override
  FluentBarProgressTheme? get progressTheme => _read('progressTheme', (FluentBarType t) => t.progressTheme);

  @override
  FluentBarDuplicatePolicy? get duplicatePolicy => _read('duplicatePolicy', (FluentBarType t) => t.duplicatePolicy);

  @override
  FluentBarRelocationStrategy? get relocationStrategy => _read('relocationStrategy', (FluentBarType t) => t.relocationStrategy);

  @override
  FluentBarUpdateRate? get timeoutUpdateInterval => _read('timeoutUpdateInterval', (FluentBarType t) => t.timeoutUpdateInterval);

  @override
  Widget? get icon => _read('icon', (FluentBarType t) => t.icon);

  @override
  Widget Function(BuildContext context, Widget child)? get positionBuilder => _read('positionBuilder', (FluentBarType t) => t.positionBuilder);

  @override
  Widget Function(BuildContext context, Animation<double> animation, Widget child)? get transitionBuilder => _read('transitionBuilder', (FluentBarType t) => t.transitionBuilder);

  @override
  Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? get builder => _read('builder', (FluentBarType t) => t.builder);

  @override
  Widget Function(BuildContext context, AnimationController controller, Widget child)? get customEffectBuilder => _read('customEffectBuilder', (FluentBarType t) => t.customEffectBuilder);

  @override
  FutureOr<void> Function()? get customHaptic => _read('customHaptic', (FluentBarType t) => t.customHaptic);

  @override
  FutureOr<void> Function()? get customProgressCompletedHaptic => _read('customProgressCompletedHaptic', (FluentBarType t) => t.customProgressCompletedHaptic);
}

class _DefaultFluentBarType extends FluentBarType {
  const _DefaultFluentBarType();
}
