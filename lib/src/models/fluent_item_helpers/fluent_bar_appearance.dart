import 'package:fluent_bar/src/internal.dart';

/// The look of one bar.
///
/// Whatever is left `null` comes from the type of the bar, then from the theme and the config.
///
/// ```dart
/// FluentBar.info('Bonus points').copyWith(
///   appearance: const FluentBarAppearance(
///     backgroundColor: Color(0xFF7C3AED),
///     themeMode: FluentBarThemeMode.dark,
///     maxMessageLines: 2,
///   ),
/// ).show();
/// ```
class FluentBarAppearance<T> {
  /// Whether the icon is shown.
  final bool? showIcon;

  /// Turns off every animation of the bar.
  final bool? disableAnimations;

  /// Whether the countdown line is shown.
  final bool? showTimeoutBar;

  /// Whether the close button is shown.
  final bool? showCloseButton;

  /// The icon of the close button; `null` takes it from the theme.
  final Widget? closeIcon;

  /// How many lines the title may take.
  final int? maxTitleLines;

  /// How many lines the message may take.
  final int? maxMessageLines;

  /// The theme of this bar.
  final FluentBarTheme? theme;

  /// The light or dark look of this bar.
  final FluentBarThemeMode? themeMode;

  /// Which way the countdown line moves.
  final FluentBarTimeoutBarDirection? timeoutBarDirection;

  /// The look of the progress indicator; merged field by field over the type and the config.
  final FluentBarProgressTheme? progressTheme;

  /// How the bar enters and leaves the screen.
  final FluentBarEntranceAnimation? entranceAnimation;

  /// Where the countdown line sits inside the bar.
  final FluentBarTimeoutBarPosition? timeoutBarPosition;

  /// A custom icon.
  final Widget? icon;

  /// The size of the icon.
  final double? iconSize;

  /// The color of the icon.
  final Color? iconColor;

  /// The background color; it also removes a gradient that comes from the theme.
  final Color? backgroundColor;

  /// Overrides parts of the decoration of the theme: color, border, radius, shadow, gradient, image.
  final BoxDecoration? decoration;

  /// The size limits of the bar.
  final BoxConstraints? constraints;

  /// The size limits of the action button.
  final BoxConstraints? actionsConstraints;

  /// How the title is aligned.
  final TextAlign? titleTextAlign;

  /// How the message is aligned.
  final TextAlign? messageTextAlign;

  /// How the action label is aligned.
  final TextAlign? actionTextAlign;

  /// The space around the bar.
  final EdgeInsets? margin;

  /// The space inside the bar.
  final EdgeInsets? padding;

  /// How a title that does not fit is cut.
  final TextOverflow? titleOverflow;

  /// How a message that does not fit is cut.
  final TextOverflow? messageOverflow;

  /// How long the bar takes to appear.
  final Duration? transitionDuration;

  /// How long the bar takes to leave.
  final Duration? reverseTransitionDuration;

  /// Replaces the whole content of the bar.
  final Widget Function(BuildContext context, FluentBarEntry<T> entry)? builder;

  /// Draws the entrance and exit of the bar.
  final Widget Function(BuildContext context, Animation<double> animation, Widget child)? transitionBuilder;

  /// Draws the attention effect started with `customEffect()`.
  final Widget Function(BuildContext context, AnimationController controller, Widget child)? customEffectBuilder;

  /// Creates a look; everything left out comes from the type, the theme and the config.
  const FluentBarAppearance({
    this.showIcon,
    this.disableAnimations,
    this.showTimeoutBar,
    this.showCloseButton,
    this.closeIcon,
    this.maxTitleLines,
    this.maxMessageLines,
    this.theme,
    this.themeMode,
    this.timeoutBarDirection,
    this.progressTheme,
    this.entranceAnimation,
    this.timeoutBarPosition,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.decoration,
    this.constraints,
    this.actionsConstraints,
    this.titleTextAlign,
    this.messageTextAlign,
    this.actionTextAlign,
    this.margin,
    this.padding,
    this.titleOverflow,
    this.messageOverflow,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.builder,
    this.transitionBuilder,
    this.customEffectBuilder,
  });

  /// A copy with the given fields replaced; `null` keeps a field.
  FluentBarAppearance<T> copyWith({
    bool? showIcon,
    bool? disableAnimations,
    bool? showTimeoutBar,
    bool? showCloseButton,
    Widget? closeIcon,
    int? maxTitleLines,
    int? maxMessageLines,
    FluentBarTheme? theme,
    FluentBarThemeMode? themeMode,
    FluentBarTimeoutBarDirection? timeoutBarDirection,
    FluentBarProgressTheme? progressTheme,
    FluentBarEntranceAnimation? entranceAnimation,
    FluentBarTimeoutBarPosition? timeoutBarPosition,
    Widget? icon,
    double? iconSize,
    Color? iconColor,
    Color? backgroundColor,
    BoxDecoration? decoration,
    BoxConstraints? constraints,
    BoxConstraints? actionsConstraints,
    TextAlign? titleTextAlign,
    TextAlign? messageTextAlign,
    TextAlign? actionTextAlign,
    EdgeInsets? margin,
    EdgeInsets? padding,
    TextOverflow? titleOverflow,
    TextOverflow? messageOverflow,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    Widget Function(BuildContext context, FluentBarEntry<T> entry)? builder,
    Widget Function(BuildContext context, Animation<double> animation, Widget child)? transitionBuilder,
    Widget Function(BuildContext context, AnimationController controller, Widget child)? customEffectBuilder,
  }) => FluentBarAppearance<T>(
    showIcon: showIcon ?? this.showIcon,
    disableAnimations: disableAnimations ?? this.disableAnimations,
    showTimeoutBar: showTimeoutBar ?? this.showTimeoutBar,
    showCloseButton: showCloseButton ?? this.showCloseButton,
    closeIcon: closeIcon ?? this.closeIcon,
    maxTitleLines: maxTitleLines ?? this.maxTitleLines,
    maxMessageLines: maxMessageLines ?? this.maxMessageLines,
    theme: theme ?? this.theme,
    themeMode: themeMode ?? this.themeMode,
    timeoutBarDirection: timeoutBarDirection ?? this.timeoutBarDirection,
    progressTheme: progressTheme ?? this.progressTheme,
    entranceAnimation: entranceAnimation ?? this.entranceAnimation,
    timeoutBarPosition: timeoutBarPosition ?? this.timeoutBarPosition,
    icon: icon ?? this.icon,
    iconSize: iconSize ?? this.iconSize,
    iconColor: iconColor ?? this.iconColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    decoration: decoration ?? this.decoration,
    constraints: constraints ?? this.constraints,
    actionsConstraints: actionsConstraints ?? this.actionsConstraints,
    titleTextAlign: titleTextAlign ?? this.titleTextAlign,
    messageTextAlign: messageTextAlign ?? this.messageTextAlign,
    actionTextAlign: actionTextAlign ?? this.actionTextAlign,
    margin: margin ?? this.margin,
    padding: padding ?? this.padding,
    titleOverflow: titleOverflow ?? this.titleOverflow,
    messageOverflow: messageOverflow ?? this.messageOverflow,
    transitionDuration: transitionDuration ?? this.transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration ?? this.reverseTransitionDuration,
    builder: builder ?? this.builder,
    transitionBuilder: transitionBuilder ?? this.transitionBuilder,
    customEffectBuilder: customEffectBuilder ?? this.customEffectBuilder,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluentBarAppearance &&
          runtimeType == other.runtimeType &&
          showIcon == other.showIcon &&
          disableAnimations == other.disableAnimations &&
          showTimeoutBar == other.showTimeoutBar &&
          showCloseButton == other.showCloseButton &&
          closeIcon == other.closeIcon &&
          maxTitleLines == other.maxTitleLines &&
          maxMessageLines == other.maxMessageLines &&
          theme == other.theme &&
          themeMode == other.themeMode &&
          timeoutBarDirection == other.timeoutBarDirection &&
          progressTheme == other.progressTheme &&
          entranceAnimation == other.entranceAnimation &&
          timeoutBarPosition == other.timeoutBarPosition &&
          icon == other.icon &&
          iconSize == other.iconSize &&
          iconColor == other.iconColor &&
          backgroundColor == other.backgroundColor &&
          decoration == other.decoration &&
          constraints == other.constraints &&
          actionsConstraints == other.actionsConstraints &&
          titleTextAlign == other.titleTextAlign &&
          messageTextAlign == other.messageTextAlign &&
          actionTextAlign == other.actionTextAlign &&
          margin == other.margin &&
          padding == other.padding &&
          titleOverflow == other.titleOverflow &&
          messageOverflow == other.messageOverflow &&
          transitionDuration == other.transitionDuration &&
          reverseTransitionDuration == other.reverseTransitionDuration;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    showIcon,
    disableAnimations,
    showTimeoutBar,
    showCloseButton,
    closeIcon,
    maxTitleLines,
    maxMessageLines,
    theme,
    themeMode,
    timeoutBarDirection,
    progressTheme,
    entranceAnimation,
    timeoutBarPosition,
    icon,
    iconSize,
    iconColor,
    backgroundColor,
    decoration,
    constraints,
    actionsConstraints,
    titleTextAlign,
    messageTextAlign,
    actionTextAlign,
    margin,
    padding,
    titleOverflow,
    messageOverflow,
    transitionDuration,
    reverseTransitionDuration,
  ]);
}
