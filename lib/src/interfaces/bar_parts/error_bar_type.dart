part of '../fluent_bar_type.dart';

class _ErrorBarType extends FluentBarType {
  const _ErrorBarType();

  @override
  String get name => 'error';

  @override
  bool get isSwipeEnabled => false;

  @override
  FluentBarHapticType get haptic => FluentBarHapticType.heavy;

  @override
  Duration get duration => const Duration(seconds: 6);

  @override
  FluentBarPriority get priority => FluentBarPriority.high;
}
