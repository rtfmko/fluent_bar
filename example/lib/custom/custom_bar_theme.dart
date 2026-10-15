import 'package:fluent_bar/fluent_bar.dart';
import 'package:fluent_bar_example/custom/perimeter_timeout_bar.dart';
import 'package:flutter/material.dart';

// A custom theme: boxDecoration, titleStyle and messageStyle are required, the rest is optional.
class CustomBarTheme extends FluentBarTheme {
  const CustomBarTheme();

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => BorderRadius.circular(20);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => BoxDecoration(
    color: const Color(0xFF0F051D),
    borderRadius: borderRadius(context, type, themeMode: themeMode),
    boxShadow: [BoxShadow(color: const Color(0xFF00FF66).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
    border: Border.all(color: const Color(0xFF8A2BE2).withValues(alpha: 0.5), width: 1.5),
  );

  @override
  EdgeInsets padding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.8);

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500);

  @override
  Color? iconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const Color(0xFF00FF66);

  @override
  Widget defaultIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode, double? overrideSize}) => const Icon(Icons.bolt, color: Color(0xFF00FF66), size: 28);

  @override
  Widget wrapContainer(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    return PerimeterTimeoutBar(
      progressNotifier: entry.controller.remainingProgressNotifier,
      borderRadius: borderRadius(context, type, themeMode: themeMode),
      strokeColor: const Color(0xFFA855F7),
      strokeWidth: 2.0,
      inset: 4,
      child: child,
    );
  }
}
