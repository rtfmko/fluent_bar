part of '../fluent_bar_type.dart';

class _ProxyFluentBarType extends FluentBarType {
  final FluentBarType baseType;
  final bool? overriddenIsSwipeEnabled;
  final bool? overriddenIsPersistent;
  final bool? overriddenDisableAnimations;
  final bool? overriddenDismissOnTap;
  final bool? overriddenPauseOnTouch;
  final FluentBarSemantics? overriddenSemantics;
  final double? overriddenTopInset;
  final double? overriddenBottomInset;
  final bool? overriddenShowIcon;
  final bool? overriddenShowTimeoutBar;
  final bool? overriddenShowCloseButton;
  final Widget? overriddenCloseIcon;
  final bool? overriddenUseSafeArea;
  final FluentBarThemeMode? overriddenThemeMode;
  final Color? overriddenBackgroundColor;
  final Color? overriddenTimeoutBarColor;
  final Duration? overriddenDuration;
  final Duration? overriddenTransitionDuration;
  final Duration? overriddenReverseTransitionDuration;
  final FluentBarPosition? overriddenPosition;
  final DismissDirection? overriddenDismissDirection;
  final FluentBarHapticType? overriddenHaptic;
  final FluentBarHapticType? overriddenProgressCompletedHaptic;
  final FluentBarPriority? overriddenPriority;
  final FluentBarEntranceAnimation? overriddenEntranceAnimation;
  final FluentBarTimeoutBarDirection? overriddenTimeoutBarDirection;
  final FluentBarTimeoutBarPosition? overriddenTimeoutBarPosition;
  final Widget? overriddenIcon;
  final FluentBarProgressTheme? overriddenProgressTheme;
  final FluentBarDuplicatePolicy? overriddenDuplicatePolicy;
  final FluentBarRelocationStrategy? overriddenRelocationStrategy;
  final FluentBarUpdateRate? overriddenTimeoutUpdateInterval;
  final Widget Function(BuildContext context, Widget child)? overriddenPositionBuilder;
  final Widget Function(BuildContext context, Animation<double> animation, Widget child)? overriddenTransitionBuilder;
  final Widget Function(BuildContext context, AnimationController controller, Widget child)? overriddenCustomEffectBuilder;
  final Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? overriddenBuilder;
  final FutureOr<void> Function()? overriddenCustomHaptic;
  final FutureOr<void> Function()? overriddenCustomProgressCompletedHaptic;

  const _ProxyFluentBarType({
    required this.baseType,
    this.overriddenIsSwipeEnabled,
    this.overriddenIsPersistent,
    this.overriddenDisableAnimations,
    this.overriddenDismissOnTap,
    this.overriddenPauseOnTouch,
    this.overriddenSemantics,
    this.overriddenTopInset,
    this.overriddenBottomInset,
    this.overriddenShowIcon,
    this.overriddenShowTimeoutBar,
    this.overriddenShowCloseButton,
    this.overriddenCloseIcon,
    this.overriddenUseSafeArea,
    this.overriddenThemeMode,
    this.overriddenBackgroundColor,
    this.overriddenTimeoutBarColor,
    this.overriddenDuration,
    this.overriddenTransitionDuration,
    this.overriddenReverseTransitionDuration,
    this.overriddenPosition,
    this.overriddenDismissDirection,
    this.overriddenHaptic,
    this.overriddenProgressCompletedHaptic,
    this.overriddenPriority,
    this.overriddenEntranceAnimation,
    this.overriddenTimeoutBarDirection,
    this.overriddenTimeoutBarPosition,
    this.overriddenIcon,
    this.overriddenProgressTheme,
    this.overriddenDuplicatePolicy,
    this.overriddenRelocationStrategy,
    this.overriddenTimeoutUpdateInterval,
    this.overriddenPositionBuilder,
    this.overriddenTransitionBuilder,
    this.overriddenCustomEffectBuilder,
    this.overriddenBuilder,
    this.overriddenCustomHaptic,
    this.overriddenCustomProgressCompletedHaptic,
  });

  @override
  String get name => baseType.name;

  @override
  FluentBarType get kind => baseType.kind;

  @override
  bool? get isSwipeEnabled => overriddenIsSwipeEnabled ?? baseType.isSwipeEnabled;

  @override
  bool? get isPersistent => overriddenIsPersistent ?? baseType.isPersistent;

  @override
  bool? get disableAnimations => overriddenDisableAnimations ?? baseType.disableAnimations;

  @override
  bool? get dismissOnTap => overriddenDismissOnTap ?? baseType.dismissOnTap;

  @override
  bool? get pauseOnTouch => overriddenPauseOnTouch ?? baseType.pauseOnTouch;

  @override
  FluentBarSemantics? get semantics => overriddenSemantics ?? baseType.semantics;

  @override
  double? get topInset => overriddenTopInset ?? baseType.topInset;

  @override
  double? get bottomInset => overriddenBottomInset ?? baseType.bottomInset;

  @override
  bool? get showIcon => overriddenShowIcon ?? baseType.showIcon;

  @override
  bool? get showTimeoutBar => overriddenShowTimeoutBar ?? baseType.showTimeoutBar;

  @override
  bool? get showCloseButton => overriddenShowCloseButton ?? baseType.showCloseButton;

  @override
  Widget? get closeIcon => overriddenCloseIcon ?? baseType.closeIcon;

  @override
  bool? get useSafeArea => overriddenUseSafeArea ?? baseType.useSafeArea;

  @override
  FluentBarThemeMode? get themeMode => overriddenThemeMode ?? baseType.themeMode;

  @override
  Color? get backgroundColor => overriddenBackgroundColor ?? baseType.backgroundColor;

  @override
  Color? get timeoutBarColor => overriddenTimeoutBarColor ?? baseType.timeoutBarColor;

  @override
  Duration? get duration => overriddenDuration ?? baseType.duration;

  @override
  Duration? get transitionDuration => overriddenTransitionDuration ?? baseType.transitionDuration;

  @override
  Duration? get reverseTransitionDuration => overriddenReverseTransitionDuration ?? baseType.reverseTransitionDuration;

  @override
  FluentBarPosition? get position => overriddenPosition ?? baseType.position;

  @override
  DismissDirection? get dismissDirection => overriddenDismissDirection ?? baseType.dismissDirection;

  @override
  FluentBarHapticType get haptic => overriddenHaptic ?? baseType.haptic;

  @override
  FluentBarHapticType get progressCompletedHaptic => overriddenProgressCompletedHaptic ?? baseType.progressCompletedHaptic;

  @override
  FluentBarPriority get priority => overriddenPriority ?? baseType.priority;

  @override
  FluentBarEntranceAnimation? get entranceAnimation => overriddenEntranceAnimation ?? baseType.entranceAnimation;

  @override
  FluentBarTimeoutBarDirection? get timeoutBarDirection => overriddenTimeoutBarDirection ?? baseType.timeoutBarDirection;

  @override
  FluentBarTimeoutBarPosition? get timeoutBarPosition => overriddenTimeoutBarPosition ?? baseType.timeoutBarPosition;

  @override
  FluentBarProgressTheme? get progressTheme => overriddenProgressTheme ?? baseType.progressTheme;

  @override
  FluentBarDuplicatePolicy? get duplicatePolicy => overriddenDuplicatePolicy ?? baseType.duplicatePolicy;

  @override
  FluentBarRelocationStrategy? get relocationStrategy => overriddenRelocationStrategy ?? baseType.relocationStrategy;

  @override
  FluentBarUpdateRate? get timeoutUpdateInterval => overriddenTimeoutUpdateInterval ?? baseType.timeoutUpdateInterval;

  @override
  Widget? get icon => overriddenIcon ?? baseType.icon;

  @override
  Widget Function(BuildContext context, Widget child)? get positionBuilder => overriddenPositionBuilder ?? baseType.positionBuilder;

  @override
  Widget Function(BuildContext context, Animation<double> animation, Widget child)? get transitionBuilder => overriddenTransitionBuilder ?? baseType.transitionBuilder;

  @override
  Widget Function(BuildContext context, AnimationController animation, Widget child)? get customEffectBuilder => overriddenCustomEffectBuilder ?? baseType.customEffectBuilder;

  @override
  Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? get builder => overriddenBuilder ?? baseType.builder;

  @override
  FutureOr<void> Function()? get customHaptic => overriddenCustomHaptic ?? baseType.customHaptic;

  @override
  FutureOr<void> Function()? get customProgressCompletedHaptic => overriddenCustomProgressCompletedHaptic ?? baseType.customProgressCompletedHaptic;
}
