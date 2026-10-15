part of '../fluent_bar_theme.dart';

class _MinimalBarTheme extends FluentBarTheme {
  const _MinimalBarTheme();

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(8);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return BoxDecoration(
      color: theme.backgroundColor(context, type, themeMode: themeMode),
      borderRadius: theme.borderRadius(context, type, themeMode: themeMode),
      border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08), width: 1.0),
    );
  }

  @override
  Color backgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    if (type.backgroundColor != null) return type.backgroundColor!;

    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return dark ? const Color(0xFF18181B) : const Color(0xFFFAFAFA);
  }

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13);
  }

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(color: dark ? Colors.white70 : Colors.black54, fontSize: 12);
  }

  @override
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 12);
  }

  @override
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
}
