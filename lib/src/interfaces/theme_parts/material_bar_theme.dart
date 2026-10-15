part of '../fluent_bar_theme.dart';

class _MaterialBarTheme extends FluentBarTheme {
  const _MaterialBarTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return BoxDecoration(
      color: theme.backgroundColor(context, type, themeMode: themeMode),
      borderRadius: theme.borderRadius(context, type, themeMode: themeMode),
      boxShadow: <BoxShadow>[BoxShadow(color: dark ? Colors.black.withValues(alpha: 0.5) : Colors.black26, blurRadius: 12, offset: const Offset(0, 4))],
    );
  }

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Colors.white, fontSize: 13);

  @override
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13);

  @override
  BoxDecoration? actionDecoration(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8));

  @override
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  @override
  Color? iconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => Colors.white;

  @override
  Widget? buildTimeoutBar(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return _buildLinearTimeoutBar(
      context,
      entry,
      theme,
      type,
      themeMode: themeMode,
      fallbackColor: dark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
      fallbackBackgroundColor: Colors.white.withValues(alpha: 0.3),
    );
  }
}
