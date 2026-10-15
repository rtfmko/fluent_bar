part of '../fluent_bar_theme.dart';

class _ModernDashboardBarTheme extends FluentBarTheme {
  const _ModernDashboardBarTheme();

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(10);

  @override
  EdgeInsets padding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return BoxDecoration(
      color: theme.backgroundColor(context, type, themeMode: themeMode),
      borderRadius: theme.borderRadius(context, type, themeMode: themeMode),
      border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08), width: 1),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
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
    return dark ? const Color(0xFF1E1E2E).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95);
  }

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark ? Colors.white : const Color(0xFF111827));
  }

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: dark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF4B5563));
  }

  @override
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5));
  }

  @override
  BoxDecoration? actionDecoration(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return BoxDecoration(color: dark ? const Color(0xFF818CF8).withValues(alpha: 0.15) : const Color(0xFF4F46E5).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6));
  }

  @override
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  @override
  Widget? buildTimeoutBar(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return _buildLinearTimeoutBar(
      context,
      entry,
      theme,
      type,
      themeMode: themeMode,
      fallbackColor: dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
      fallbackBackgroundColor: Colors.transparent,
    );
  }
}
