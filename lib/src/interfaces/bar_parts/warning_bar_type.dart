part of '../fluent_bar_type.dart';

class _WarningBarType extends FluentBarType {
  const _WarningBarType();

  @override
  String get name => 'warning';

  @override
  FluentBarHapticType get haptic => FluentBarHapticType.medium;
}
