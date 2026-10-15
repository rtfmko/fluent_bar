import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final HapticHelper helper = HapticHelper.instance;
  final List<String> haptics = <String>[];
  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  void mockPlatform(Future<Object?> Function(MethodCall call)? handler) => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, handler);

  setUp(() {
    haptics.clear();
    errors.clear();
    FluentBar.addErrorHandler(onError);
    mockPlatform((MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
      return null;
    });
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    mockPlatform(null);
  });

  group('HapticHelper', () {
    test('is a singleton', () {
      expect(HapticHelper.instance, same(helper));
    });

    test('maps every haptic type to its platform feedback', () async {
      helper.triggerHaptic(FluentBarHapticType.light);
      helper.triggerHaptic(FluentBarHapticType.medium);
      helper.triggerHaptic(FluentBarHapticType.heavy);
      await pumpEventQueue();

      expect(haptics, <String>['HapticFeedbackType.lightImpact', 'HapticFeedbackType.mediumImpact', 'HapticFeedbackType.heavyImpact']);
      expect(errors, isEmpty);
    });

    test('none does not touch the platform at all', () async {
      helper.triggerHaptic(FluentBarHapticType.none);
      await pumpEventQueue();

      expect(haptics, isEmpty);
      expect(errors, isEmpty);
    });

    test('every type is handled (a new enum value must not be forgotten)', () async {
      for (final FluentBarHapticType type in FluentBarHapticType.values) {
        helper.triggerHaptic(type);
      }
      await pumpEventQueue();

      expect(haptics, hasLength(FluentBarHapticType.values.length - 1), reason: 'every type except none vibrates');
    });

    test('a platform failure is reported as hapticInternal and does not throw', () async {
      mockPlatform((MethodCall call) async => throw PlatformException(code: 'ERROR', message: 'Haptic failed'));

      expect(() => helper.triggerHaptic(FluentBarHapticType.heavy), returnsNormally);
      await pumpEventQueue();

      expect(errors.single.type, FluentBarErrorType.hapticInternal);
      expect(errors.single.severity, FluentBarErrorSeverity.error);
      expect(errors.single.error, isA<PlatformException>());
    });

    test('a platform without haptics (no handler) is not an error', () async {
      mockPlatform(null);

      helper.triggerHaptic(FluentBarHapticType.light);
      await pumpEventQueue();

      expect(errors, isEmpty);
    });

    test('one failure does not prevent the next haptic', () async {
      bool fail = true;
      mockPlatform((MethodCall call) async {
        if (fail) throw PlatformException(code: 'ERROR');
        haptics.add(call.arguments as String);
        return null;
      });

      helper.triggerHaptic(FluentBarHapticType.light);
      await pumpEventQueue();
      fail = false;
      helper.triggerHaptic(FluentBarHapticType.medium);
      await pumpEventQueue();

      expect(errors, hasLength(1));
      expect(haptics, <String>['HapticFeedbackType.mediumImpact']);
    });
  });
}
