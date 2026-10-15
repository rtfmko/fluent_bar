import 'dart:ui';

import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part '../interfaces/proxy/proxy_fluent_bar_theme.dart';
part '../interfaces/theme_parts/cupertino_bar_theme.dart';
part '../interfaces/theme_parts/liquid_glass_bar_theme.dart';
part '../interfaces/theme_parts/material_bar_theme.dart';
part '../interfaces/theme_parts/minimal_bar_theme.dart';
part '../interfaces/theme_parts/modern_dashboard_bar_theme.dart';
part '../interfaces/theme_parts/windows_bar_theme.dart';

/// The countdown line shared by the built-in themes.
///
/// Colors come from the theme (`timeoutBarColor` / `timeoutBarBackgroundColor`), otherwise from the fallbacks.
Widget _buildLinearTimeoutBar(
  BuildContext context,
  FluentBarEntry<dynamic> entry,
  FluentBarTheme theme,
  FluentBarType type, {
  required FluentBarThemeMode? themeMode,
  required Color fallbackColor,
  required Color fallbackBackgroundColor,
}) {
  final FluentBarTimeoutBarDirection direction = entry.resolveTimeoutBarDirection(FluentBarManager.instance.config);
  final Color color = theme.timeoutBarColor(context, type, themeMode: themeMode) ?? fallbackColor;
  final Color themeBackground = theme.timeoutBarBackgroundColor(context, type, themeMode: themeMode);
  final Color backgroundColor = themeBackground == Colors.transparent ? fallbackBackgroundColor : themeBackground;
  final double minHeight = theme.timeoutBarMinHeight(context, type, themeMode: themeMode);
  final BorderRadius? borderRadius = theme.timeoutBarBorderRadius(context, type, themeMode: themeMode);

  final ValueListenable<double> progress = switch (direction) {
    FluentBarTimeoutBarDirection.forward => entry.controller.remainingProgressNotifier,
    FluentBarTimeoutBarDirection.reverse => entry.controller.elapsedProgressNotifier,
  };

  final Duration restyle = entry.resolveDisableAnimations(FluentBarManager.instance.config) ? Duration.zero : kFluentBarRestyleDuration;

  return FluentBarColorFade(
    color: color,
    duration: restyle,
    builder: (BuildContext context, Color? barColor) => FluentBarColorFade(
      color: backgroundColor,
      duration: restyle,
      builder: (BuildContext context, Color? trackColor) => ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (BuildContext context, double value, Widget? child) => LinearProgressIndicator(
          value: value,
          backgroundColor: trackColor ?? backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(barColor ?? color),
          minHeight: minHeight,
          borderRadius: borderRadius,
        ),
      ),
    ),
  );
}

/// The brightness of the theme nearest to [context], Material or Cupertino, whichever is closer.
///
/// They cannot be asked separately:
///  * without a Material theme `Theme.maybeBrightnessOf` silently returns the platform brightness,
///    which is wrong in a Cupertino app;
///  * in a Material app `CupertinoTheme.maybeBrightnessOf` hits the derived Cupertino theme that
///    every `Theme` inserts below itself, and its brightness need not match that `Theme`
///    (for a nested dark `Theme` it stays light).
/// So this walks up to the first "real" theme and skips derived Cupertino themes: the `Theme`
/// that produced each of them sits right above it.
Brightness? _nearestThemeBrightness(BuildContext context) {
  Brightness? brightness;

  context.visitAncestorElements((Element element) {
    final Widget widget = element.widget;
    if (widget is Theme) {
      brightness = widget.data.brightness;
    } else if (widget is CupertinoTheme && widget.data is! MaterialBasedCupertinoThemeData) {
      brightness = widget.data.brightness;
    }
    return brightness == null;
  });

  return brightness;
}

/// How bars look: shape, colors, text styles, spacing.
///
/// Use a built-in theme, tweak one with [copyWith], or extend this class. A custom theme
/// must provide [boxDecoration], [titleStyle] and [messageStyle]; everything else has a default.
///
/// ```dart
/// class BrandTheme extends FluentBarTheme {
///   const BrandTheme();
///
///   @override
///   BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) =>
///       BoxDecoration(color: const Color(0xFF1E293B), borderRadius: theme.borderRadius(context, type, themeMode: themeMode));
///
///   @override
///   TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
///       const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
///
///   @override
///   TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
///       const TextStyle(color: Colors.white70);
/// }
///
/// FluentBar.patchConfig((config) => config.copyWith(defaultTheme: const BrandTheme()));
/// ```
abstract class FluentBarTheme {
  /// Lets subclasses be const.
  const FluentBarTheme();

  /// The iOS look.
  static const FluentBarTheme cupertino = _CupertinoBarTheme();

  /// A translucent, blurred "glass" look.
  static const FluentBarTheme liquidGlass = _LiquidGlassBarTheme();

  /// The Material look.
  static const FluentBarTheme material = _MaterialBarTheme();

  /// The Windows (Fluent) look.
  static const FluentBarTheme windows = _WindowsBarTheme();

  /// A flat look with a thin border.
  static const FluentBarTheme minimal = _MinimalBarTheme();

  /// A dashboard look with an accent stripe.
  static const FluentBarTheme modern = _ModernDashboardBarTheme();

  /// Whether the bar is drawn in its dark variant: decided by [themeMode], or by the app theme when it is `system`.
  bool isDarkMode(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final FluentBarThemeMode configMode = FluentBarManager.instance.config.defaultThemeMode;
    final FluentBarThemeMode activeMode = themeMode ?? configMode;

    try {
      switch (activeMode) {
        case FluentBarThemeMode.light:
          return false;
        case FluentBarThemeMode.dark:
          return true;
        case FluentBarThemeMode.system:
          // Both lookups register a dependency, so the bar rebuilds when the app theme changes. They also
          // give the fallback: the platform brightness when there is no theme above the bar at all.
          final Brightness? platformOrCupertino = CupertinoTheme.maybeBrightnessOf(context);
          final Brightness? platformOrMaterial = Theme.maybeBrightnessOf(context);

          return (_nearestThemeBrightness(context) ?? platformOrCupertino ?? platformOrMaterial) == Brightness.dark;
      }
    } catch (e, st) {
      FluentBarErrorHandler.instance.handle(e, FluentBarErrorType.darkMode, st);
      return false;
    }
  }

  /// The size limits of a bar.
  BoxConstraints constraints(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const BoxConstraints(maxWidth: 480);

  /// The size limits of the action button.
  BoxConstraints actionsConstraints(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const BoxConstraints(maxWidth: 160);

  /// The background color of a bar of the given type.
  Color backgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    if (type.backgroundColor != null) {
      return type.backgroundColor!;
    }

    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    if (type.kind == FluentBarType.success) {
      return dark ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32);
    }
    if (type.kind == FluentBarType.error) {
      return dark ? const Color(0xFFB71C1C) : const Color(0xFFC62828);
    }
    if (type.kind == FluentBarType.warning) {
      return dark ? const Color(0xFFE65100) : const Color(0xFFEF6C00);
    }

    return dark ? const Color(0xFF0D47A1) : const Color(0xFF1565C0);
  }

  /// The color of the icon; by default the color of the title.
  Color? iconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => titleStyle(context, type, themeMode: themeMode).color;

  /// The color of the countdown line; `null` derives it from the icon color.
  Color? timeoutBarColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => type.timeoutBarColor;

  /// The color of the track under the countdown line; transparent derives it from the icon color.
  Color timeoutBarBackgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => Colors.transparent;

  /// The color of the loader shown on the action button while its handler runs.
  Color actionLoaderColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      iconColor(context, type, themeMode: themeMode) ?? (isDarkMode(context, type, themeMode: themeMode) ? Colors.white : Colors.black);

  /// The space inside the action button.
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  /// The space inside a bar.
  EdgeInsets padding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// The space around a bar.
  EdgeInsets margin(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.all(16.0);

  /// The background, border, radius and shadow of a bar. Read shared values from [theme] so that [copyWith] overrides apply.
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode});

  /// The decoration of the action button; `null` for a plain text button.
  BoxDecoration? actionDecoration(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => null;

  /// The text style of the title.
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode});

  /// The text style of the message.
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode});

  /// The text style of the action label; by default the style of the title.
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => titleStyle(context, type, themeMode: themeMode);

  /// How the title is aligned.
  TextAlign? titleTextAlign(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => null;

  /// How the message is aligned.
  TextAlign? messageTextAlign(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => null;

  /// How the action label is aligned.
  TextAlign? actionTextAlign(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => null;

  /// How a title that does not fit is cut.
  TextOverflow? titleOverflow(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => TextOverflow.ellipsis;

  /// How a message that does not fit is cut.
  TextOverflow? messageOverflow(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => TextOverflow.ellipsis;

  /// How an action label that does not fit is cut.
  TextOverflow? actionOverflow(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => TextOverflow.ellipsis;

  /// How many lines the title may take.
  int maxTitleLines(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 1;

  /// How many lines the message may take.
  int maxMessageLines(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 3;

  /// How many lines the action label may take.
  int actionMaxLines(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 1;

  /// The size of the icon.
  double iconSize(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 24.0;

  /// The gap between the icon, the texts and the action.
  double spacing(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 12;

  /// The gap between the title and the message.
  double titleSpacing(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 2.0;

  /// The thickness of the countdown line.
  double timeoutBarMinHeight(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 2.5;

  /// The corner radius of the countdown line.
  BorderRadius? timeoutBarBorderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => null;

  /// The corner radius of a bar.
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(12);

  /// The icon of a bar that does not set its own: the icon of the type, or a default one for its kind.
  Widget defaultIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode, double? overrideSize}) {
    if (type.icon != null) return type.icon!;

    final double effectiveSize = overrideSize ?? iconSize(context, type, themeMode: themeMode);

    if (type.kind == FluentBarType.success) return Icon(Icons.check_circle_outline, size: effectiveSize);
    if (type.kind == FluentBarType.error) return Icon(Icons.error_outline, size: effectiveSize);
    if (type.kind == FluentBarType.warning) return Icon(Icons.warning_amber_rounded, size: effectiveSize);
    return Icon(Icons.info_outline, size: effectiveSize);
  }

  /// The icon of the close button.
  Widget closeIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const Icon(Icons.close_rounded);

  /// The size of the close icon.
  double closeIconSize(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => 18;

  /// The color of the close icon; by default the color of the message, slightly dimmed.
  Color? closeIconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => messageStyle(context, type, themeMode: themeMode).color?.withValues(alpha: 0.7);

  /// The space around the close icon that also reacts to the tap.
  EdgeInsets closeButtonPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.all(6);

  /// Where the close button sits against the content of a tall bar: `center` (default), `start`
  /// for the top or `end` for the bottom.
  CrossAxisAlignment closeButtonAlignment(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => CrossAxisAlignment.center;

  /// Wraps the bar in a widget that reacts to input, for example an ink effect.
  Widget wrapInteractiveContainer(BuildContext context, Widget child, FluentBarType type, {FluentBarThemeMode? themeMode}) => child;

  /// Wraps the finished bar in another widget, for example a glow or a custom countdown around the border.
  Widget wrapContainer(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, {FluentBarThemeMode? themeMode}) => child;

  /// The countdown line. Every value is read from [theme] (not from `this`) so that [copyWith]
  /// overrides work. Return `null` to draw no line at all.
  Widget? buildTimeoutBar(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final Color fallback = theme.iconColor(context, type, themeMode: themeMode) ?? (isDarkMode(context, type, themeMode: themeMode) ? Colors.white : Colors.black);

    return _buildLinearTimeoutBar(context, entry, theme, type, themeMode: themeMode, fallbackColor: fallback.withValues(alpha: 0.5), fallbackBackgroundColor: fallback.withValues(alpha: 0.12));
  }

  /// A widget shown on the action button while its handler runs; `null` for the default loader.
  Widget? actionLoadingWidget(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => null;

  /// A copy of this theme with some parts replaced.
  ///
  /// Each callback receives `(context, type, themeMode)`; a callback that throws falls back to this theme.
  ///
  /// ```dart
  /// final rounded = FluentBarTheme.material.copyWith(
  ///   borderRadius: (context, type, themeMode) => BorderRadius.circular(24),
  ///   margin: (context, type, themeMode) => const EdgeInsets.all(24),
  /// );
  /// ```
  FluentBarTheme copyWith({
    bool Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? isDarkMode,
    BoxConstraints Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? constraints,
    BoxConstraints Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionsConstraints,
    Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? backgroundColor,
    Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? iconColor,
    Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? timeoutBarColor,
    Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? timeoutBarBackgroundColor,
    Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionLoaderColor,
    EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionInternalPadding,
    EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? padding,
    EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? margin,
    BoxDecoration Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? boxDecoration,
    BoxDecoration Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionDecoration,
    TextStyle Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? titleStyle,
    TextStyle Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? messageStyle,
    TextStyle Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionStyle,
    TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? titleTextAlign,
    TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? messageTextAlign,
    TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionTextAlign,
    TextOverflow Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? titleOverflow,
    TextOverflow Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? messageOverflow,
    TextOverflow Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionOverflow,
    int Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? maxTitleLines,
    int Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? maxMessageLines,
    int Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionMaxLines,
    double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? iconSize,
    double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? spacing,
    double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? titleSpacing,
    double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? timeoutBarMinHeight,
    BorderRadius Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? timeoutBarBorderRadius,
    BorderRadius Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? borderRadius,
    Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode, double? overrideSize)? defaultIcon,
    Widget Function(BuildContext context, Widget child, FluentBarType type, FluentBarThemeMode? themeMode)? wrapInteractiveContainer,
    Widget Function(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode)? wrapContainer,
    Widget Function(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode)? buildTimeoutBar,
    Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? actionLoadingWidget,
    Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? closeIcon,
    double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? closeIconSize,
    Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? closeIconColor,
    EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? closeButtonPadding,
    CrossAxisAlignment Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? closeButtonAlignment,
  }) => _ProxyFluentBarTheme(
    // A new isDarkMode over a theme that already has one: the outer one decides, the inner one is dropped.
    baseType: isDarkMode != null && this is _ProxyFluentBarTheme ? (this as _ProxyFluentBarTheme)._withoutDarkMode() : this,
    overriddenDarkMode: isDarkMode,
    overriddenConstraints: constraints,
    overriddenActionsConstraints: actionsConstraints,
    overriddenBackgroundColor: backgroundColor,
    overriddenIconColor: iconColor,
    overriddenTimeoutBarColor: timeoutBarColor,
    overriddenTimeoutBarBackgroundColor: timeoutBarBackgroundColor,
    overriddenActionLoaderColor: actionLoaderColor,
    overriddenActionInternalPadding: actionInternalPadding,
    overriddenPadding: padding,
    overriddenMargin: margin,
    overriddenBoxDecoration: boxDecoration,
    overriddenActionDecoration: actionDecoration,
    overriddenTitleStyle: titleStyle,
    overriddenMessageStyle: messageStyle,
    overriddenActionStyle: actionStyle,
    overriddenTitleTextAlign: titleTextAlign,
    overriddenMessageTextAlign: messageTextAlign,
    overriddenActionTextAlign: actionTextAlign,
    overriddenTitleOverflow: titleOverflow,
    overriddenMessageOverflow: messageOverflow,
    overriddenActionOverflow: actionOverflow,
    overriddenMaxTitleLines: maxTitleLines,
    overriddenMaxMessageLines: maxMessageLines,
    overriddenActionMaxLines: actionMaxLines,
    overriddenIconSize: iconSize,
    overriddenSpacing: spacing,
    overriddenTitleSpacing: titleSpacing,
    overriddenTimeoutBarMinHeight: timeoutBarMinHeight,
    overriddenTimeoutBarBorderRadius: timeoutBarBorderRadius,
    overriddenBorderRadius: borderRadius,
    overriddenDefaultIcon: defaultIcon,
    overriddenInteractiveContainer: wrapInteractiveContainer,
    overriddenWrapContainer: wrapContainer,
    overriddenBuildTimeoutBar: buildTimeoutBar,
    overriddenActionLoadingWidget: actionLoadingWidget,
    overriddenCloseIcon: closeIcon,
    overriddenCloseIconSize: closeIconSize,
    overriddenCloseIconColor: closeIconColor,
    overriddenCloseButtonPadding: closeButtonPadding,
    overriddenCloseButtonAlignment: closeButtonAlignment,
  );
}
