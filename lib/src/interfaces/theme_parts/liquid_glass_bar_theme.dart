part of '../fluent_bar_theme.dart';

class _LiquidGlassBarTheme extends _CupertinoBarTheme {
  const _LiquidGlassBarTheme();

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(22);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    final Color baseColor = type.backgroundColor ?? (dark ? CupertinoColors.systemBackground.darkColor : CupertinoColors.systemBackground.color);

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          baseColor.withValues(alpha: dark ? 0.65 : 0.75),
          baseColor.withValues(alpha: dark ? 0.35 : 0.45),
        ],
      ),
      borderRadius: theme.borderRadius(context, type, themeMode: themeMode),
      border: Border.all(color: CupertinoColors.white.withValues(alpha: dark ? 0.2 : 0.4), width: 1.0),
    );
  }

  @override
  BoxDecoration? actionDecoration(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    final Color greyColor = dark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6.color;

    return BoxDecoration(
      color: greyColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CupertinoColors.white.withValues(alpha: dark ? 0.15 : 0.2), width: 0.5),
    );
  }

  @override
  Widget wrapContainer(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: dark ? 0.3 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: borderRadius(context, type, themeMode: themeMode),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: child),
        ),
      ),
    );
  }
}
