import 'package:fluent_bar/src/internal.dart';

part '../interfaces/bar_parts/error_bar_type.dart';
part '../interfaces/bar_parts/info_bar_type.dart';
part '../interfaces/bar_parts/success_bar_type.dart';
part '../interfaces/bar_parts/warning_bar_type.dart';
part '../interfaces/proxy/proxy_fluent_bar_type.dart';
part '../interfaces/proxy/safe_fluent_bar_type.dart';

/// What a bar is (info, success, a custom kind) and how it behaves by default.
///
/// A type bundles the settings you would otherwise repeat in every call. Use a built-in
/// type, vary one with [copyWith], or extend this class and override only what differs.
/// A getter that returns `null` leaves the decision to the global config.
///
/// ```dart
/// class PromoType extends FluentBarType {
///   const PromoType();
///
///   @override
///   String get name => 'promo';
///
///   @override
///   Color? get backgroundColor => const Color(0xFFBE185D);
///
///   @override
///   Duration? get duration => const Duration(seconds: 6);
///
///   @override
///   FluentBarPosition? get position => FluentBarPosition.bottom;
/// }
///
/// FluentBar.showCustom(const PromoType(), '20% off until Friday');
/// ```
abstract class FluentBarType {
  /// Lets subclasses be const.
  const FluentBarType();

  /// A neutral message.
  static const FluentBarType info = _InfoBarType();

  /// Something went well.
  static const FluentBarType success = _SuccessBarType();

  /// Something needs attention.
  static const FluentBarType warning = _WarningBarType();

  /// Something failed. Lives longer, has a high priority and cannot be swiped away.
  static const FluentBarType error = _ErrorBarType();

  static final Expando<FluentBarType> _guards = Expando<FluentBarType>('FluentBarType guard');

  /// Wraps [type] in a guard: an exception in any of its getters does not break the library but
  /// becomes an error report and a default value.
  ///
  /// Built-in types need no guard. For one type the guard is created once. The library calls
  /// this itself before it reads a type. Call it in your own code that reads the getters of a
  /// type it did not create, for example in a content builder or an analytics listener:
  ///
  /// ```dart
  /// final String typeName = FluentBarType.guard(entry.item.type).name;
  /// ```
  static FluentBarType guard(FluentBarType type) {
    if (type is _InfoBarType || type is _SuccessBarType || type is _WarningBarType || type is _ErrorBarType || type is _SafeFluentBarType) return type;
    return _guards[type] ??= _SafeFluentBarType(type);
  }

  /// The name of the type in logs, analytics and metrics.
  String get name => 'custom';

  /// The built-in type whose colors and icon this type uses; by default itself.
  FluentBarType get kind => this;

  /// Whether bars of this type can be swiped away. `null` leaves the decision to the config.
  bool? get isSwipeEnabled => null;

  /// Whether bars of this type stay until closed. `null` leaves the decision to the config.
  bool? get isPersistent => null;

  /// Turns off the animations of bars of this type. `null` leaves the decision to the config.
  bool? get disableAnimations => null;

  /// Whether a tap closes bars of this type. `null` leaves the decision to the config.
  bool? get dismissOnTap => null;

  /// Whether the countdown stops while a bar of this type is held or hovered. `null` leaves the decision to the config.
  bool? get pauseOnTouch => null;

  /// How bars of this type are presented to a screen reader. `null` leaves the decision to the config.
  FluentBarSemantics? get semantics => null;

  /// The distance of a top bar of this type from the top edge (see `FluentBarConfig.topInset`).
  double? get topInset => null;

  /// The distance of a bottom bar of this type from the bottom edge (see `FluentBarConfig.bottomInset`).
  double? get bottomInset => null;

  /// Whether bars of this type show an icon. `null` leaves the decision to the config.
  bool? get showIcon => null;

  /// Whether bars of this type show the countdown line. `null` leaves the decision to the config.
  bool? get showTimeoutBar => null;

  /// Whether bars of this type show a close button. `null` leaves the decision to the config.
  bool? get showCloseButton => null;

  /// The icon of the close button of bars of this type; `null` takes the close icon of the theme.
  Widget? get closeIcon => null;

  /// Whether bars of this type keep clear of the notch, status bar and home gesture. `null` leaves the decision to the config.
  bool? get useSafeArea => null;

  /// The light or dark look of bars of this type. `null` leaves the decision to the config.
  FluentBarThemeMode? get themeMode => null;

  /// The background color of bars of this type; `null` takes it from the theme.
  Color? get backgroundColor => null;

  /// The color of the countdown line of bars of this type; `null` takes it from the theme.
  Color? get timeoutBarColor => null;

  /// The lifetime of bars of this type. `null` means `FluentBarConfig.defaultDuration`.
  Duration? get duration => null;

  /// How long bars of this type take to appear. `null` leaves the decision to the config.
  Duration? get transitionDuration => null;

  /// How long bars of this type take to leave. `null` leaves the decision to the config.
  Duration? get reverseTransitionDuration => null;

  /// Where bars of this type appear. `null` leaves the decision to the config.
  FluentBarPosition? get position => null;

  /// Which way bars of this type can be swiped away. `null` leaves the decision to the config.
  DismissDirection? get dismissDirection => null;

  /// The haptic feedback played when a bar of this type appears.
  FluentBarHapticType get haptic => FluentBarHapticType.none;

  /// The haptic feedback played when the progress of a bar of this type completes.
  FluentBarHapticType get progressCompletedHaptic => FluentBarHapticType.none;

  /// The priority that orders bars of this type in the queue.
  FluentBarPriority get priority => FluentBarPriority.normal;

  /// How bars of this type enter and leave the screen. `null` leaves the decision to the config.
  FluentBarEntranceAnimation? get entranceAnimation => null;

  /// Which way the countdown line of bars of this type moves. `null` leaves the decision to the config.
  FluentBarTimeoutBarDirection? get timeoutBarDirection => null;

  /// Where the countdown line sits inside bars of this type. `null` leaves the decision to the config.
  FluentBarTimeoutBarPosition? get timeoutBarPosition => null;

  /// The look of progress indicators of this type; merged field by field over the config.
  FluentBarProgressTheme? get progressTheme => null;

  /// What happens when a bar of this type is shown again with the same id. `null` leaves the decision to the config.
  FluentBarDuplicatePolicy? get duplicatePolicy => null;

  /// What happens when a visible bar of this type moves into a busy region. `null` leaves the decision to the config.
  FluentBarRelocationStrategy? get relocationStrategy => null;

  /// How often the countdown values of bars of this type are published. `null` leaves the decision to the config.
  FluentBarUpdateRate? get timeoutUpdateInterval => null;

  /// The icon of bars of this type; `null` takes the default icon of the theme.
  Widget? get icon => null;

  /// Places bars of this type on screen with a custom widget.
  Widget Function(BuildContext context, Widget child)? get positionBuilder => null;

  /// Draws the entrance and exit of bars of this type.
  Widget Function(BuildContext context, Animation<double> animation, Widget child)? get transitionBuilder => null;

  /// Replaces the content of bars of this type.
  Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? get builder => null;

  /// Draws the attention effect started with `customEffect()` on bars of this type.
  Widget Function(BuildContext context, AnimationController controller, Widget child)? get customEffectBuilder => null;

  /// A custom haptic played when a bar of this type appears, instead of [haptic].
  FutureOr<void> Function()? get customHaptic => null;

  /// A custom haptic played when the progress completes, instead of [progressCompletedHaptic].
  FutureOr<void> Function()? get customProgressCompletedHaptic => null;

  /// A copy of this type with some defaults replaced.
  ///
  /// ```dart
  /// final quiet = FluentBarType.info.copyWith(showIcon: false, duration: const Duration(seconds: 2));
  /// FluentBar.showCustom(quiet, 'Synced');
  /// ```
  FluentBarType copyWith({
    bool? isSwipeEnabled,
    bool? isPersistent,
    bool? disableAnimations,
    bool? dismissOnTap,
    bool? pauseOnTouch,
    FluentBarSemantics? semantics,
    double? topInset,
    double? bottomInset,
    bool? showIcon,
    bool? showTimeoutBar,
    bool? showCloseButton,
    Widget? closeIcon,
    bool? useSafeArea,
    FluentBarThemeMode? themeMode,
    Color? backgroundColor,
    Color? timeoutBarColor,
    Duration? duration,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    FluentBarPosition? position,
    DismissDirection? dismissDirection,
    FluentBarHapticType? haptic,
    FluentBarHapticType? progressCompletedHaptic,
    FluentBarPriority? priority,
    FluentBarEntranceAnimation? entranceAnimation,
    FluentBarTimeoutBarDirection? timeoutBarDirection,
    FluentBarTimeoutBarPosition? timeoutBarPosition,
    Widget? icon,
    FluentBarProgressTheme? progressTheme,
    FluentBarDuplicatePolicy? duplicatePolicy,
    FluentBarRelocationStrategy? relocationStrategy,
    FluentBarUpdateRate? timeoutUpdateInterval,
    Widget Function(BuildContext context, Widget child)? positionBuilder,
    Widget Function(BuildContext context, Animation<double> animation, Widget child)? transitionBuilder,
    Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? builder,
    Widget Function(BuildContext context, AnimationController controller, Widget child)? customEffectBuilder,
    FutureOr<void> Function()? customHaptic,
    FutureOr<void> Function()? customProgressCompletedHaptic,
  }) => _ProxyFluentBarType(
    baseType: this,
    overriddenIsSwipeEnabled: isSwipeEnabled,
    overriddenIsPersistent: isPersistent,
    overriddenDisableAnimations: disableAnimations,
    overriddenDismissOnTap: dismissOnTap,
    overriddenPauseOnTouch: pauseOnTouch,
    overriddenSemantics: semantics,
    overriddenTopInset: topInset,
    overriddenBottomInset: bottomInset,
    overriddenShowIcon: showIcon,
    overriddenShowTimeoutBar: showTimeoutBar,
    overriddenShowCloseButton: showCloseButton,
    overriddenCloseIcon: closeIcon,
    overriddenUseSafeArea: useSafeArea,
    overriddenThemeMode: themeMode,
    overriddenBackgroundColor: backgroundColor,
    overriddenTimeoutBarColor: timeoutBarColor,
    overriddenDuration: duration,
    overriddenTransitionDuration: transitionDuration,
    overriddenReverseTransitionDuration: reverseTransitionDuration,
    overriddenPosition: position,
    overriddenDismissDirection: dismissDirection,
    overriddenHaptic: haptic,
    overriddenProgressCompletedHaptic: progressCompletedHaptic,
    overriddenPriority: priority,
    overriddenEntranceAnimation: entranceAnimation,
    overriddenTimeoutBarDirection: timeoutBarDirection,
    overriddenTimeoutBarPosition: timeoutBarPosition,
    overriddenIcon: icon,
    overriddenProgressTheme: progressTheme,
    overriddenDuplicatePolicy: duplicatePolicy,
    overriddenRelocationStrategy: relocationStrategy,
    overriddenTimeoutUpdateInterval: timeoutUpdateInterval,
    overriddenPositionBuilder: positionBuilder,
    overriddenTransitionBuilder: transitionBuilder,
    overriddenCustomEffectBuilder: customEffectBuilder,
    overriddenBuilder: builder,
    overriddenCustomHaptic: customHaptic,
    overriddenCustomProgressCompletedHaptic: customProgressCompletedHaptic,
  );
}
