import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CustomDefaultBarType extends FluentBarType {
  const _CustomDefaultBarType();
}

void main() {
  group('FluentBarType.copyWith & _ProxyFluentBarType Comprehensive Tests', () {
    const List<FluentBarType> allBaseTypes = <FluentBarType>[FluentBarType.info, FluentBarType.success, FluentBarType.warning, FluentBarType.error];

    testWidgets('should use overridden values when copyWith is applied for all types', (WidgetTester tester) async {
      const FluentBarPosition customPosition = FluentBarPosition.bottom;
      const bool customIsSwipeEnabled = false;
      const bool customIsPersistent = true;
      const bool customDisableAnimations = true;
      const DismissDirection customDismissDirection = DismissDirection.down;
      const FluentBarHapticType customHaptic = FluentBarHapticType.heavy;
      const FluentBarHapticType customProgressCompletedHaptic = FluentBarHapticType.medium;
      const Duration customDuration = Duration(seconds: 10);
      const FluentBarPriority customPriority = FluentBarPriority.high;
      const FluentBarTimeoutBarDirection customProgressDirection = FluentBarTimeoutBarDirection.reverse;
      const FluentBarProgressTheme customProgressTheme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear);

      Widget customTransitionBuilder(BuildContext context, Animation<double> animation, Widget child) {
        return FadeTransition(opacity: animation, child: child);
      }

      Widget customPositionBuilder(BuildContext context, Widget child) {
        return Padding(padding: const EdgeInsets.all(8), child: child);
      }

      Widget customBuilder(BuildContext context, FluentBarEntry<dynamic> entry) {
        return const Text('Custom Builder');
      }

      const Duration customTransitionDuration = Duration(milliseconds: 500);
      const Duration customReverseTransitionDuration = Duration(milliseconds: 300);
      const Color customBackgroundColor = Colors.purple;
      const Color customTimeoutBarColor = Colors.orange;
      const Icon customIcon = Icon(Icons.star);

      Future<void> customCustomHaptic() async {}
      Future<void> customCustomProgressCompletedHaptic() async {}

      for (final FluentBarType baseType in allBaseTypes) {
        final FluentBarType proxyType = baseType.copyWith(
          position: customPosition,
          isSwipeEnabled: customIsSwipeEnabled,
          isPersistent: customIsPersistent,
          disableAnimations: customDisableAnimations,
          dismissDirection: customDismissDirection,
          haptic: customHaptic,
          progressCompletedHaptic: customProgressCompletedHaptic,
          duration: customDuration,
          priority: customPriority,
          timeoutBarDirection: customProgressDirection,
          progressTheme: customProgressTheme,
          transitionBuilder: customTransitionBuilder,
          positionBuilder: customPositionBuilder,
          builder: customBuilder,
          transitionDuration: customTransitionDuration,
          reverseTransitionDuration: customReverseTransitionDuration,
          backgroundColor: customBackgroundColor,
          timeoutBarColor: customTimeoutBarColor,
          icon: customIcon,
          customHaptic: customCustomHaptic,
          customProgressCompletedHaptic: customCustomProgressCompletedHaptic,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                expect(proxyType.position, customPosition);
                expect(proxyType.isSwipeEnabled, customIsSwipeEnabled);
                expect(proxyType.isPersistent, customIsPersistent);
                expect(proxyType.disableAnimations, customDisableAnimations);
                expect(proxyType.dismissDirection, customDismissDirection);
                expect(proxyType.haptic, customHaptic);
                expect(proxyType.progressCompletedHaptic, customProgressCompletedHaptic);
                expect(proxyType.duration, customDuration);
                expect(proxyType.priority, customPriority);
                expect(proxyType.timeoutBarDirection, customProgressDirection);
                expect(proxyType.progressTheme, customProgressTheme);
                expect(proxyType.transitionBuilder, customTransitionBuilder);
                expect(proxyType.positionBuilder, customPositionBuilder);
                expect(proxyType.builder, customBuilder);
                expect(proxyType.transitionDuration, customTransitionDuration);
                expect(proxyType.reverseTransitionDuration, customReverseTransitionDuration);
                expect(proxyType.backgroundColor, customBackgroundColor);
                expect(proxyType.timeoutBarColor, customTimeoutBarColor);
                expect(proxyType.icon, customIcon);
                expect(proxyType.customHaptic, customCustomHaptic);
                expect(proxyType.customProgressCompletedHaptic, customCustomProgressCompletedHaptic);

                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }
    });

    testWidgets('should fallback to baseType values when overrides are null for all types', (WidgetTester tester) async {
      for (final FluentBarType baseType in allBaseTypes) {
        final FluentBarType proxyType = baseType.copyWith();

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                expect(proxyType.name, baseType.name);
                expect(proxyType.position, baseType.position);
                expect(proxyType.isSwipeEnabled, baseType.isSwipeEnabled);
                expect(proxyType.isPersistent, baseType.isPersistent);
                expect(proxyType.disableAnimations, baseType.disableAnimations);
                expect(proxyType.dismissDirection, baseType.dismissDirection);
                expect(proxyType.haptic, baseType.haptic);
                expect(proxyType.progressCompletedHaptic, baseType.progressCompletedHaptic);
                expect(proxyType.duration, baseType.duration);
                expect(proxyType.priority, baseType.priority);
                expect(proxyType.timeoutBarDirection, baseType.timeoutBarDirection);
                expect(proxyType.progressTheme, baseType.progressTheme);
                expect(proxyType.transitionBuilder, baseType.transitionBuilder);
                expect(proxyType.positionBuilder, baseType.positionBuilder);
                expect(proxyType.builder, baseType.builder);
                expect(proxyType.transitionDuration, baseType.transitionDuration);
                expect(proxyType.reverseTransitionDuration, baseType.reverseTransitionDuration);
                expect(proxyType.backgroundColor, baseType.backgroundColor);
                expect(proxyType.timeoutBarColor, baseType.timeoutBarColor);
                expect(proxyType.icon?.runtimeType, baseType.icon?.runtimeType);
                expect(proxyType.customHaptic, baseType.customHaptic);
                expect(proxyType.customProgressCompletedHaptic, baseType.customProgressCompletedHaptic);

                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }
    });
  });

  testWidgets('should use default getters from abstract FluentBarType when not overridden', (WidgetTester tester) async {
    const FluentBarType defaultType = _CustomDefaultBarType();
    final FluentBarType proxyType = defaultType.copyWith();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            expect(defaultType.name, 'custom');
            expect(defaultType.haptic, FluentBarHapticType.none);

            expect(proxyType.name, 'custom');
            expect(proxyType.haptic, FluentBarHapticType.none);

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
