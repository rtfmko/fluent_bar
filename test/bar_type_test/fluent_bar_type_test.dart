import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

class _CustomType extends FluentBarType {
  const _CustomType();
}

void main() {
  const List<FluentBarType> builtIn = <FluentBarType>[FluentBarType.info, FluentBarType.success, FluentBarType.warning, FluentBarType.error];

  group('built-in types', () {
    test('have distinct names and are their own kind', () {
      expect(builtIn.map((FluentBarType t) => t.name), <String>['info', 'success', 'warning', 'error']);
      for (final FluentBarType type in builtIn) {
        expect(type.kind, same(type));
      }
    });

    test('info, success and warning differ only by haptic', () {
      expect(FluentBarType.info.haptic, FluentBarHapticType.light);
      expect(FluentBarType.success.haptic, FluentBarHapticType.medium);
      expect(FluentBarType.warning.haptic, FluentBarHapticType.medium);

      for (final FluentBarType type in <FluentBarType>[FluentBarType.info, FluentBarType.success, FluentBarType.warning]) {
        expect(type.duration, isNull, reason: 'null = FluentBarConfig.defaultDuration');
        expect(type.priority, FluentBarPriority.normal);
        expect(type.isSwipeEnabled, isNull);
      }
    });

    test('error is more insistent: longer, higher priority, not swipeable, heavy haptic', () {
      const FluentBarType type = FluentBarType.error;

      expect(type.duration, const Duration(seconds: 6));
      expect(type.priority, FluentBarPriority.high);
      expect(type.isSwipeEnabled, isFalse);
      expect(type.haptic, FluentBarHapticType.heavy);
    });

    test('leave everything else to the config (null) so that global defaults apply', () {
      for (final FluentBarType type in builtIn) {
        expect(type.isPersistent, isNull);
        expect(type.disableAnimations, isNull);
        expect(type.dismissOnTap, isNull);
        expect(type.showIcon, isNull);
        expect(type.showTimeoutBar, isNull);
        expect(type.useSafeArea, isNull);
        expect(type.backgroundColor, isNull);
        expect(type.timeoutBarColor, isNull);
        expect(type.transitionDuration, isNull);
        expect(type.reverseTransitionDuration, isNull);
        expect(type.position, isNull);
        expect(type.dismissDirection, isNull);
        expect(type.entranceAnimation, isNull);
        expect(type.timeoutBarDirection, isNull);
        expect(type.progressTheme, isNull);
        expect(type.duplicatePolicy, isNull);
        expect(type.relocationStrategy, isNull);
        expect(type.timeoutUpdateInterval, isNull);
        expect(type.icon, isNull);
        expect(type.positionBuilder, isNull);
        expect(type.transitionBuilder, isNull);
        expect(type.builder, isNull);
        expect(type.customEffectBuilder, isNull);
        expect(type.customHaptic, isNull);
        expect(type.customProgressCompletedHaptic, isNull);
        expect(type.progressCompletedHaptic, FluentBarHapticType.none);
      }
    });
  });

  group('custom type', () {
    test('gets neutral defaults', () {
      const FluentBarType type = _CustomType();

      expect(type.name, 'custom');
      expect(type.kind, same(type));
      expect(type.duration, isNull, reason: 'null = FluentBarConfig.defaultDuration');
      expect(type.priority, FluentBarPriority.normal);
      expect(type.haptic, FluentBarHapticType.none);
    });
  });

  group('copyWith', () {
    test('keeps the name and kind of the base type, also through several copies', () {
      final FluentBarType copy = FluentBarType.error.copyWith(duration: const Duration(seconds: 1)).copyWith(priority: FluentBarPriority.low);

      expect(copy.name, 'error');
      expect(copy.kind, same(FluentBarType.error));
      expect(copy, isNot(same(FluentBarType.error)));
    });

    test('overrides only what was passed; later copies win', () {
      final FluentBarType first = FluentBarType.error.copyWith(duration: const Duration(seconds: 1), position: FluentBarPosition.bottom);
      final FluentBarType second = first.copyWith(duration: const Duration(seconds: 2));

      expect(second.duration, const Duration(seconds: 2));
      expect(second.position, FluentBarPosition.bottom);
      expect(second.priority, FluentBarPriority.high, reason: 'untouched values come from the base type');
      expect(second.haptic, FluentBarHapticType.heavy);
      expect(FluentBarType.error.duration, const Duration(seconds: 6), reason: 'the base type is not modified');
    });

    test('builders of the base type survive a copy that does not touch them', () {
      Widget position(BuildContext context, Widget child) => child;
      Widget transition(BuildContext context, Animation<double> animation, Widget child) => child;
      Widget builder(BuildContext context, FluentBarEntry<dynamic> entry) => const SizedBox();
      Widget effect(BuildContext context, AnimationController controller, Widget child) => child;

      final FluentBarType base = FluentBarType.info.copyWith(positionBuilder: position, transitionBuilder: transition, builder: builder, customEffectBuilder: effect);
      final FluentBarType copy = base.copyWith(duration: const Duration(seconds: 1));

      expect(copy.positionBuilder, position);
      expect(copy.transitionBuilder, transition);
      expect(copy.builder, builder);
      expect(copy.customEffectBuilder, effect);
    });

    test('queue-related settings can be overridden', () {
      final FluentBarType copy = FluentBarType.info.copyWith(
        timeoutUpdateInterval: FluentBarUpdateRate.fps60,
        duplicatePolicy: FluentBarDuplicatePolicy.ignore,
        relocationStrategy: FluentBarRelocationStrategy.forceReplace,
        showTimeoutBar: true,
        showIcon: false,
        useSafeArea: false,
        dismissOnTap: false,
        entranceAnimation: FluentBarEntranceAnimation.fade,
      );

      expect(copy.timeoutUpdateInterval, FluentBarUpdateRate.fps60);
      expect(copy.duplicatePolicy, FluentBarDuplicatePolicy.ignore);
      expect(copy.relocationStrategy, FluentBarRelocationStrategy.forceReplace);
      expect(copy.showTimeoutBar, isTrue);
      expect(copy.showIcon, isFalse);
      expect(copy.useSafeArea, isFalse);
      expect(copy.dismissOnTap, isFalse);
      expect(copy.entranceAnimation, FluentBarEntranceAnimation.fade);
      expect(copy.copyWith().timeoutUpdateInterval, FluentBarUpdateRate.fps60);
    });

    test('timeoutBarDirection is overridden under the same name as the getter', () {
      final FluentBarType copy = FluentBarType.info.copyWith(timeoutBarDirection: FluentBarTimeoutBarDirection.reverse);
      expect(copy.timeoutBarDirection, FluentBarTimeoutBarDirection.reverse);
    });
  });

  group('config.typeOverrides', () {
    test('replaces a built-in type everywhere it is resolved', () {
      final FluentBarType customError = FluentBarType.error.copyWith(duration: const Duration(seconds: 30));
      final FluentBarConfig config = FluentBarConfig(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.error: customError});

      final FluentBarType resolved = config.resolveType(FluentBarType.error);
      expect(resolved.duration, const Duration(seconds: 30));
      expect(resolved.kind, same(FluentBarType.error));
      expect(resolved.name, 'error');
      expect(config.resolveType(FluentBarType.info), same(FluentBarType.info));
      expect(const FluentBarConfig().resolveType(FluentBarType.error), same(FluentBarType.error));
    });
  });
}
