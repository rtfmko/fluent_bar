import 'package:fluent_bar/src/internal.dart';

/// Decides whether `incoming` is the same bar as `existing`.
///
/// It replaces the default rule (same id, or equal bars without ids).
///
/// ```dart
/// FluentBar.patchConfig((config) => config.copyWith(
///   duplicateComparator: (incoming, existing) => incoming.meta?['group'] == existing.meta?['group'],
/// ));
/// ```
typedef FluentBarDuplicateComparator = bool Function(FluentBarItem<dynamic> incoming, FluentBarItem<dynamic> existing);

/// The global defaults of every bar.
///
/// Every setting resolves in one order: the bar itself, then its type, then this config.
///
/// ```dart
/// FluentBar.updateConfig(const FluentBarConfig(
///   defaultPosition: FluentBarPosition.bottom,
///   defaultDuration: Duration(seconds: 5),
///   defaultShowTimeoutBar: true,
/// ));
///
/// FluentBar.patchConfig((config) => config.copyWith(maxQueueLength: 5));
/// ```
class FluentBarConfig {
  /// Two regions, top and bottom, each with its own bar and queue. With `false` one bar is shown at a time.
  final bool enableMultiRegion;

  /// Whether bars show an icon. Used when neither the bar nor its type sets it.
  final bool defaultShowIcons;

  /// Turns off the animations of every bar. Used when neither the bar nor its type sets it.
  final bool defaultDisableAnimations;

  /// Whether bars keep clear of the notch, status bar and home gesture. Used when neither the bar nor its type sets it.
  final bool defaultUseSafeArea;

  /// Whether bars show the countdown line. Used when neither the bar nor its type sets it.
  final bool defaultShowTimeoutBar;

  /// Whether bars show a close button. Used when neither the bar nor its type sets it.
  ///
  /// The `snack`, `toast`, `banner` and `loading` presets and `undismissible()` turn it off for
  /// themselves; `.withCloseButton()` on the bar brings it back.
  final bool defaultShowCloseButton;

  /// What a screen reader says for the close button; `null` uses the "Close" label of the app localization.
  final String? closeButtonLabel;

  /// Whether bars can be swiped away. Used when neither the bar nor its type sets it.
  final bool defaultIsSwipeEnabled;

  /// Whether a tap closes a bar. Used when neither the bar nor its type sets it.
  final bool defaultDismissOnTap;

  /// Whether the countdown stops while a bar is held or hovered. Used when neither the bar nor its type sets it.
  final bool defaultPauseOnTouch;

  /// How bars are presented to a screen reader. Used when neither the bar nor its type sets it.
  final FluentBarSemantics defaultSemantics;

  /// How many bars may wait in the queue of one region (1 to 100). A bar over the limit is dropped.
  final int maxQueueLength;

  /// The distance of bottom bars from the bottom edge of the screen.
  ///
  /// `null` (default) means measured: the height of the bottom panel wrapped in
  /// `FluentBarBottomInset`, or zero without one. A number is a fixed inset instead of the
  /// measured one. A bar and a type may set their own: the bar, its type, this field, the measured value.
  final double? bottomInset;

  /// The distance of top bars from the top edge of the screen. Works like [bottomInset]: `null` is
  /// the height of the app bar wrapped in `FluentBarTopInset` (status bar included), a number is fixed.
  final double? topInset;

  /// The lifetime of a bar when neither the bar nor its type sets one.
  final Duration defaultDuration;

  /// The master switch for haptic feedback: with `false` the library calls neither the built-in
  /// vibration nor the custom haptic callbacks of bars and types.
  final bool enableHaptics;

  /// Follow the system setting that asks to remove motion: "Reduce Motion" on iOS
  /// (`AccessibilityFeatures.reduceMotion`) and "Remove animations" on Android
  /// (`AccessibilityFeatures.disableAnimations`).
  ///
  /// When it is on, bars fade in and out instead of sliding and scaling, attention effects
  /// (shake, bounce, pulse, heartbeat, custom) are not played, and the icon changes at once.
  /// Color changes still fade: that is not motion.
  ///
  /// On Android Flutter itself shortens regular animations to a few frames under this setting,
  /// so the fade is practically instant there; on iOS it runs at normal speed.
  ///
  /// `true` by default. With `false` the library does not change its behavior because of the
  /// setting (the shortening done by Flutter on Android remains).
  final bool respectSystemReduceMotion;

  /// How long a bar takes to appear. Used when neither the bar nor its type sets it.
  final Duration defaultTransitionDuration;

  /// How long a bar takes to leave. Used when neither the bar nor its type sets it.
  final Duration defaultReverseTransitionDuration;

  /// Where bars appear. Used when neither the bar nor its type sets it.
  final FluentBarPosition defaultPosition;

  /// Which way bars can be swiped away. `null` follows the position of the bar.
  final DismissDirection? defaultDismissDirection;

  /// Where the countdown line sits inside a bar. Used when neither the bar nor its type sets it.
  final FluentBarTimeoutBarPosition defaultTimeoutBarPosition;

  /// The order of waiting bars.
  final FluentBarQueueStrategy defaultQueueStrategy;

  /// What happens when a visible bar moves into a busy region. Used when neither the bar nor its type sets it.
  final FluentBarRelocationStrategy defaultRelocationStrategy;

  /// How often countdown values are published to listeners. Used when neither the bar nor its type sets it.
  final FluentBarUpdateRate defaultTimeoutUpdateInterval;

  /// The built-in theme used when [defaultTheme] is not set; `auto` follows the platform.
  final FluentBarThemeStyle themeStyle;

  /// What happens when a bar with the same id is shown again. Used when neither the bar nor its type sets it.
  final FluentBarDuplicatePolicy defaultDuplicatePolicy;

  /// The theme of every bar that does not set its own. `null` uses the platform theme (see [themeStyle]).
  final FluentBarTheme? defaultTheme;

  /// The light or dark look of bars. `system` follows the app theme.
  final FluentBarThemeMode defaultThemeMode;

  /// Which way the countdown line moves. Used when neither the bar nor its type sets it.
  final FluentBarTimeoutBarDirection defaultTimeoutBarDirection;

  /// How bars enter and leave the screen. Used when neither the bar nor its type sets it.
  final FluentBarEntranceAnimation defaultEntranceAnimation;

  /// The look of progress indicators; merged field by field under the bar and its type.
  final FluentBarProgressTheme progressTheme;

  /// Replaces types for the whole app: every bar of the key type behaves as the value type.
  final Map<FluentBarType, FluentBarType>? typeOverrides;

  /// Analytics events that are not delivered to listeners. Handy for turning off what the app does
  /// not need (for example paused / resumed or requested) without filtering in every listener.
  final Set<FluentBarAnalyticsEvent> disabledAnalyticsEvents;

  /// A custom rule for what counts as the same bar.
  final FluentBarDuplicateComparator? duplicateComparator;

  /// Places bars on screen with a custom widget when neither the bar nor its type sets a position.
  final Widget Function(BuildContext context, Widget child)? defaultPositionBuilder;

  /// Draws the entrance and exit of bars when neither the bar nor its type sets an animation.
  final Widget Function(BuildContext context, Animation<double> animation, Widget child)? defaultTransitionBuilder;

  /// Replaces the content of every bar that has no builder of its own.
  final Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? defaultBuilder;

  /// Creates a config; everything left out keeps its default.
  const FluentBarConfig({
    this.enableMultiRegion = true,
    this.defaultShowIcons = true,
    this.defaultDisableAnimations = false,
    this.defaultUseSafeArea = true,
    this.defaultShowTimeoutBar = false,
    this.defaultShowCloseButton = false,
    this.closeButtonLabel,
    this.defaultIsSwipeEnabled = true,
    this.defaultDismissOnTap = true,
    this.defaultPauseOnTouch = true,
    this.defaultSemantics = FluentBarSemantics.announce,
    int maxQueueLength = 15,
    this.bottomInset,
    this.topInset,
    this.defaultDuration = const Duration(seconds: 4),
    this.enableHaptics = true,
    this.respectSystemReduceMotion = true,
    this.defaultTransitionDuration = const Duration(milliseconds: 300),
    this.defaultReverseTransitionDuration = const Duration(milliseconds: 250),
    this.defaultPosition = FluentBarPosition.top,
    this.defaultDismissDirection,
    this.defaultTimeoutBarPosition = FluentBarTimeoutBarPosition.bottom,
    this.defaultQueueStrategy = const SmartQueueStrategy(),
    this.defaultRelocationStrategy = FluentBarRelocationStrategy.queueNext,
    this.defaultTimeoutUpdateInterval = FluentBarUpdateRate.medium,
    this.themeStyle = FluentBarThemeStyle.auto,
    this.defaultDuplicatePolicy = FluentBarDuplicatePolicy.update,
    this.defaultTheme,
    this.defaultThemeMode = FluentBarThemeMode.system,
    this.defaultTimeoutBarDirection = FluentBarTimeoutBarDirection.forward,
    this.defaultEntranceAnimation = FluentBarEntranceAnimation.slide,
    this.progressTheme = const FluentBarProgressTheme(),
    this.typeOverrides,
    this.disabledAnalyticsEvents = const <FluentBarAnalyticsEvent>{},
    this.duplicateComparator,
    this.defaultPositionBuilder,
    this.defaultTransitionBuilder,
    this.defaultBuilder,
  }) : maxQueueLength = maxQueueLength < 1 ? 1 : (maxQueueLength > 100 ? 100 : maxQueueLength);

  /// A copy with the given fields replaced. `null` keeps a field; the `clear...` flags reset one.
  ///
  /// ```dart
  /// config.copyWith(defaultTheme: FluentBarTheme.minimal);
  /// config.copyWith(clearDefaultTheme: true);
  /// ```
  FluentBarConfig copyWith({
    bool? enableMultiRegion,
    bool? defaultShowIcons,
    bool? defaultDisableAnimations,
    bool? defaultUseSafeArea,
    bool? defaultShowTimeoutBar,
    bool? defaultShowCloseButton,
    String? closeButtonLabel,
    bool? defaultIsSwipeEnabled,
    bool? defaultDismissOnTap,
    bool? defaultPauseOnTouch,
    FluentBarSemantics? defaultSemantics,
    int? maxQueueLength,
    double? bottomInset,
    double? topInset,
    Duration? defaultDuration,
    bool? enableHaptics,
    bool? respectSystemReduceMotion,
    Duration? defaultTransitionDuration,
    Duration? defaultReverseTransitionDuration,
    FluentBarPosition? defaultPosition,
    DismissDirection? defaultDismissDirection,
    FluentBarTimeoutBarPosition? defaultTimeoutBarPosition,
    FluentBarQueueStrategy? defaultQueueStrategy,
    FluentBarRelocationStrategy? defaultRelocationStrategy,
    FluentBarUpdateRate? defaultTimeoutUpdateInterval,
    FluentBarThemeStyle? themeStyle,
    FluentBarDuplicatePolicy? defaultDuplicatePolicy,
    FluentBarTheme? defaultTheme,
    FluentBarThemeMode? defaultThemeMode,
    FluentBarTimeoutBarDirection? defaultTimeoutBarDirection,
    FluentBarEntranceAnimation? defaultEntranceAnimation,
    FluentBarProgressTheme? progressTheme,
    Map<FluentBarType, FluentBarType>? typeOverrides,
    Set<FluentBarAnalyticsEvent>? disabledAnalyticsEvents,
    FluentBarDuplicateComparator? duplicateComparator,
    Widget Function(BuildContext context, Widget child)? defaultPositionBuilder,
    Widget Function(BuildContext context, Animation<double> animation, Widget child)? defaultTransitionBuilder,
    Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? defaultBuilder,
    // null in copyWith means "keep", so clearing needs separate flags.
    bool clearBottomInset = false,
    bool clearTopInset = false,
    bool clearDefaultTheme = false,
    bool clearCloseButtonLabel = false,
    bool clearTypeOverrides = false,
    bool clearDuplicateComparator = false,
    bool clearDefaultPositionBuilder = false,
    bool clearDefaultTransitionBuilder = false,
    bool clearDefaultBuilder = false,
  }) => FluentBarConfig(
    enableMultiRegion: enableMultiRegion ?? this.enableMultiRegion,
    defaultShowIcons: defaultShowIcons ?? this.defaultShowIcons,
    defaultDisableAnimations: defaultDisableAnimations ?? this.defaultDisableAnimations,
    defaultUseSafeArea: defaultUseSafeArea ?? this.defaultUseSafeArea,
    defaultShowTimeoutBar: defaultShowTimeoutBar ?? this.defaultShowTimeoutBar,
    defaultShowCloseButton: defaultShowCloseButton ?? this.defaultShowCloseButton,
    closeButtonLabel: clearCloseButtonLabel ? null : (closeButtonLabel ?? this.closeButtonLabel),
    defaultIsSwipeEnabled: defaultIsSwipeEnabled ?? this.defaultIsSwipeEnabled,
    defaultDismissOnTap: defaultDismissOnTap ?? this.defaultDismissOnTap,
    defaultPauseOnTouch: defaultPauseOnTouch ?? this.defaultPauseOnTouch,
    defaultSemantics: defaultSemantics ?? this.defaultSemantics,
    maxQueueLength: maxQueueLength ?? this.maxQueueLength,
    bottomInset: clearBottomInset ? null : (bottomInset ?? this.bottomInset),
    topInset: clearTopInset ? null : (topInset ?? this.topInset),
    defaultDuration: defaultDuration ?? this.defaultDuration,
    enableHaptics: enableHaptics ?? this.enableHaptics,
    respectSystemReduceMotion: respectSystemReduceMotion ?? this.respectSystemReduceMotion,
    defaultTransitionDuration: defaultTransitionDuration ?? this.defaultTransitionDuration,
    defaultReverseTransitionDuration: defaultReverseTransitionDuration ?? this.defaultReverseTransitionDuration,
    defaultPosition: defaultPosition ?? this.defaultPosition,
    defaultDismissDirection: defaultDismissDirection ?? this.defaultDismissDirection,
    defaultTimeoutBarPosition: defaultTimeoutBarPosition ?? this.defaultTimeoutBarPosition,
    defaultQueueStrategy: defaultQueueStrategy ?? this.defaultQueueStrategy,
    defaultRelocationStrategy: defaultRelocationStrategy ?? this.defaultRelocationStrategy,
    defaultTimeoutUpdateInterval: defaultTimeoutUpdateInterval ?? this.defaultTimeoutUpdateInterval,
    themeStyle: themeStyle ?? this.themeStyle,
    defaultDuplicatePolicy: defaultDuplicatePolicy ?? this.defaultDuplicatePolicy,
    defaultTheme: clearDefaultTheme ? null : (defaultTheme ?? this.defaultTheme),
    defaultThemeMode: defaultThemeMode ?? this.defaultThemeMode,
    defaultTimeoutBarDirection: defaultTimeoutBarDirection ?? this.defaultTimeoutBarDirection,
    defaultEntranceAnimation: defaultEntranceAnimation ?? this.defaultEntranceAnimation,
    progressTheme: progressTheme ?? this.progressTheme,
    typeOverrides: clearTypeOverrides ? null : (typeOverrides ?? this.typeOverrides),
    disabledAnalyticsEvents: disabledAnalyticsEvents ?? this.disabledAnalyticsEvents,
    duplicateComparator: clearDuplicateComparator ? null : (duplicateComparator ?? this.duplicateComparator),
    defaultPositionBuilder: clearDefaultPositionBuilder ? null : (defaultPositionBuilder ?? this.defaultPositionBuilder),
    defaultTransitionBuilder: clearDefaultTransitionBuilder ? null : (defaultTransitionBuilder ?? this.defaultTransitionBuilder),
    defaultBuilder: clearDefaultBuilder ? null : (defaultBuilder ?? this.defaultBuilder),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluentBarConfig &&
          runtimeType == other.runtimeType &&
          enableMultiRegion == other.enableMultiRegion &&
          defaultShowIcons == other.defaultShowIcons &&
          defaultDisableAnimations == other.defaultDisableAnimations &&
          defaultUseSafeArea == other.defaultUseSafeArea &&
          defaultShowTimeoutBar == other.defaultShowTimeoutBar &&
          defaultShowCloseButton == other.defaultShowCloseButton &&
          closeButtonLabel == other.closeButtonLabel &&
          defaultIsSwipeEnabled == other.defaultIsSwipeEnabled &&
          defaultDismissOnTap == other.defaultDismissOnTap &&
          defaultPauseOnTouch == other.defaultPauseOnTouch &&
          defaultSemantics == other.defaultSemantics &&
          maxQueueLength == other.maxQueueLength &&
          bottomInset == other.bottomInset &&
          topInset == other.topInset &&
          defaultDuration == other.defaultDuration &&
          enableHaptics == other.enableHaptics &&
          respectSystemReduceMotion == other.respectSystemReduceMotion &&
          defaultTransitionDuration == other.defaultTransitionDuration &&
          defaultReverseTransitionDuration == other.defaultReverseTransitionDuration &&
          defaultPosition == other.defaultPosition &&
          defaultDismissDirection == other.defaultDismissDirection &&
          defaultTimeoutBarPosition == other.defaultTimeoutBarPosition &&
          defaultQueueStrategy == other.defaultQueueStrategy &&
          defaultRelocationStrategy == other.defaultRelocationStrategy &&
          defaultTimeoutUpdateInterval == other.defaultTimeoutUpdateInterval &&
          themeStyle == other.themeStyle &&
          defaultDuplicatePolicy == other.defaultDuplicatePolicy &&
          defaultTheme == other.defaultTheme &&
          defaultThemeMode == other.defaultThemeMode &&
          defaultTimeoutBarDirection == other.defaultTimeoutBarDirection &&
          defaultEntranceAnimation == other.defaultEntranceAnimation &&
          progressTheme == other.progressTheme &&
          mapEquals(typeOverrides, other.typeOverrides) &&
          setEquals(disabledAnalyticsEvents, other.disabledAnalyticsEvents);

  /// Whether motion must be avoided right now: the system asks for it and the app follows the
  /// setting (see [respectSystemReduceMotion]).
  bool reducesMotion(BuildContext context) {
    if (!respectSystemReduceMotion) return false;

    // Android: "Remove animations".
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return true;

    // iOS: "Reduce Motion" arrives as a separate flag that MediaQuery does not carry.
    return View.maybeOf(context)?.platformDispatcher.accessibilityFeatures.reduceMotion ?? false;
  }

  /// Whether the functions (duplicate rule and builders) are the same as in [other].
  ///
  /// Functions are not part of `==`: two configs with closures that mean the same must be equal,
  /// and closures cannot be compared by meaning. Yet the library must notice a changed function,
  /// hence this separate check.
  @internal
  bool hasSameFunctionsAs(FluentBarConfig other) =>
      duplicateComparator == other.duplicateComparator &&
      defaultPositionBuilder == other.defaultPositionBuilder &&
      defaultTransitionBuilder == other.defaultTransitionBuilder &&
      defaultBuilder == other.defaultBuilder &&
      progressTheme.labelBuilder == other.progressTheme.labelBuilder &&
      progressTheme.progressBuilder == other.progressTheme.progressBuilder;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    enableMultiRegion,
    defaultShowIcons,
    defaultDisableAnimations,
    defaultUseSafeArea,
    defaultShowTimeoutBar,
    defaultShowCloseButton,
    closeButtonLabel,
    defaultIsSwipeEnabled,
    defaultDismissOnTap,
    defaultPauseOnTouch,
    defaultSemantics,
    maxQueueLength,
    bottomInset,
    topInset,
    defaultDuration,
    enableHaptics,
    respectSystemReduceMotion,
    defaultTransitionDuration,
    defaultReverseTransitionDuration,
    defaultPosition,
    defaultDismissDirection,
    defaultTimeoutBarPosition,
    defaultQueueStrategy,
    defaultRelocationStrategy,
    defaultTimeoutUpdateInterval,
    themeStyle,
    defaultDuplicatePolicy,
    defaultTheme,
    defaultThemeMode,
    defaultTimeoutBarDirection,
    defaultEntranceAnimation,
    progressTheme,
    if (typeOverrides == null) null else Object.hashAllUnordered(typeOverrides!.entries.map((MapEntry<FluentBarType, FluentBarType> e) => Object.hash(e.key, e.value))),
    Object.hashAllUnordered(disabledAnalyticsEvents),
  ]);
}
