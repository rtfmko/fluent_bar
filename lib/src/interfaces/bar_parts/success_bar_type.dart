part of '../fluent_bar_type.dart';

class _SuccessBarType extends FluentBarType {
  const _SuccessBarType();

  @override
  String get name => 'success';

  @override
  FluentBarHapticType get haptic => FluentBarHapticType.medium;
}
