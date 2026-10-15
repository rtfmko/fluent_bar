import 'package:fluent_bar/src/internal.dart';

/// Plays the built-in haptic feedback.
class HapticHelper {
  HapticHelper._();

  /// The single instance.
  static final HapticHelper instance = HapticHelper._();

  /// Never throws: a synchronous failure (platform services not initialized) and a platform error
  /// both go to the error handler. A vibration must not prevent a bar from showing.
  void triggerHaptic(FluentBarHapticType hapticType) {
    final Future<void> Function() haptic;
    switch (hapticType) {
      case FluentBarHapticType.none:
        return;
      case FluentBarHapticType.light:
        haptic = HapticFeedback.lightImpact;
      case FluentBarHapticType.medium:
        haptic = HapticFeedback.mediumImpact;
      case FluentBarHapticType.heavy:
        haptic = HapticFeedback.heavyImpact;
    }

    unawaited(FluentBarErrorHandler.instance.executeSafeAsync<void>(overrideCall: haptic, type: FluentBarErrorType.hapticInternal));
  }
}
