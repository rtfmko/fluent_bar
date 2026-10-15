part of '../fluent_bar_theme.dart';

class _CupertinoBarTheme extends FluentBarTheme {
  const _CupertinoBarTheme();

  @override
  Widget closeIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const Icon(CupertinoIcons.xmark);

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(16);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);

    return BoxDecoration(
      color: theme.backgroundColor(context, type, themeMode: themeMode),
      borderRadius: theme.borderRadius(context, type, themeMode: themeMode),
      boxShadow: <BoxShadow>[BoxShadow(color: dark ? CupertinoColors.black.withValues(alpha: 0.4) : CupertinoColors.systemGrey2.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
    );
  }

  @override
  Color backgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    if (type.backgroundColor != null) return type.backgroundColor!;

    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return dark ? CupertinoColors.systemBackground.darkColor.withValues(alpha: 0.85) : CupertinoColors.systemBackground.color.withValues(alpha: 0.85);
  }

  @override
  Widget defaultIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode, double? overrideSize}) {
    if (type.icon != null) return type.icon!;

    final double effectiveSize = overrideSize ?? iconSize(context, type, themeMode: themeMode);

    if (type.kind == FluentBarType.success) return Icon(CupertinoIcons.check_mark_circled, size: effectiveSize);
    if (type.kind == FluentBarType.error) return Icon(CupertinoIcons.clear_thick_circled, size: effectiveSize);
    if (type.kind == FluentBarType.warning) return Icon(CupertinoIcons.exclamationmark_triangle, size: effectiveSize);
    return Icon(CupertinoIcons.info, size: effectiveSize);
  }

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(color: dark ? CupertinoColors.label.darkColor : CupertinoColors.label.color, fontWeight: FontWeight.w600, fontSize: 14);
  }

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(color: dark ? CupertinoColors.secondaryLabel.darkColor : CupertinoColors.secondaryLabel.color, fontSize: 13);
  }

  @override
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool dark = isDarkMode(context, type, themeMode: themeMode);
    return TextStyle(color: dark ? CupertinoColors.activeBlue.darkColor : CupertinoColors.activeBlue.color, fontWeight: FontWeight.w600, fontSize: 14);
  }

  @override
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
}
