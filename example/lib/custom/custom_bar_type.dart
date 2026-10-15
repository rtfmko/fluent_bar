import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

// A custom type bundles the defaults of one kind of bar. Override only what differs.
class CustomBarType extends FluentBarType {
  const CustomBarType();

  @override
  String get name => 'custom_type';

  @override
  Duration get duration => const Duration(seconds: 7);

  @override
  FluentBarHapticType get haptic => FluentBarHapticType.heavy;

  @override
  FluentBarEntranceAnimation get entranceAnimation => FluentBarEntranceAnimation.scale;

  // Bars of this type are always dark, whatever the config says. A single bar can still override it.
  @override
  FluentBarThemeMode? get themeMode => FluentBarThemeMode.dark;

  @override
  Color? get timeoutBarColor => Colors.yellowAccent;

  @override
  Widget? get icon => const Icon(Icons.auto_awesome, color: Colors.yellowAccent, size: 30);
}
