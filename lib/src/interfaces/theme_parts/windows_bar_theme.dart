part of '../fluent_bar_theme.dart';

class _WindowsBarTheme extends FluentBarTheme {
  const _WindowsBarTheme();

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(6);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return BoxDecoration(
      color: theme.backgroundColor(context, type, themeMode: themeMode),
      borderRadius: theme.borderRadius(context, type, themeMode: themeMode),
      border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), width: 1),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Color backgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    if (type.backgroundColor != null) return type.backgroundColor!;

    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return dark ? const Color(0xFF202020).withValues(alpha: 0.9) : const Color(0xFFF3F3F3).withValues(alpha: 0.9);
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
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFF0067C0), fontWeight: FontWeight.w600, fontSize: 12);

  @override
  BoxDecoration? actionDecoration(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(4));

  @override
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
}
