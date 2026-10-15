import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FluentBarConfig config = FluentBarConfig();

  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });
  tearDown(() => FluentBar.removeErrorHandler(onError));

  FluentBarEntry<void> entryOf({FluentBarAppearance<void>? appearance, FluentBarBehavior? behavior, bool visible = true}) {
    final FluentBarEntry<void> entry = FluentBarEntry<void>(
      item: FluentBarItem<void>(type: FluentBarType.info, message: 'Bar', appearance: appearance, behavior: behavior),
    );
    if (visible) entry.internalController.changeState(FluentBarLifecycleState.visible);
    addTearDown(entry.internalController.dispose);
    return entry;
  }

  Widget host(FluentBarEntry<void> entry) => MaterialApp(
    home: Scaffold(
      body: Stack(
        children: <Widget>[FluentBarWrapper<void>(entry: entry, config: config)],
      ),
    ),
  );

  Future<void> pumpShown(WidgetTester tester, FluentBarEntry<void> entry) async {
    await tester.pumpWidget(host(entry));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  List<Matrix4> transforms(WidgetTester tester) => tester.widgetList<Transform>(find.ancestor(of: find.text('Bar'), matching: find.byType(Transform))).map((Transform t) => t.transform).toList();

  double shift(WidgetTester tester) => transforms(tester).map((Matrix4 m) => m.getTranslation().x.abs()).reduce((double a, double b) => a > b ? a : b);

  double scale(WidgetTester tester) => transforms(tester).map((Matrix4 m) => m.getMaxScaleOnAxis()).reduce((double a, double b) => a > b ? a : b);

  bool atRest(WidgetTester tester) => transforms(tester).every((Matrix4 m) => m == Matrix4.identity());

  group('effects', () {
    testWidgets('shake moves the bar horizontally and returns it back', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      await pumpShown(tester, entry);

      entry.controller.shake(intensity: 10, duration: const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(shift(tester), greaterThan(0));

      await tester.pumpAndSettle();
      expect(atRest(tester), isTrue);
    });

    for (final (String name, void Function(FluentBarController<void>) trigger) in <(String, void Function(FluentBarController<void>))>[
      ('bounce', (FluentBarController<void> c) => c.bounce(scale: 0.3)),
      ('pulse', (FluentBarController<void> c) => c.pulse(scale: 1.4)),
      ('heartbeat', (FluentBarController<void> c) => c.heartbeat(scale: 1.4)),
    ]) {
      testWidgets('$name scales the bar up and returns it back', (WidgetTester tester) async {
        final FluentBarEntry<void> entry = entryOf();
        await pumpShown(tester, entry);

        trigger(entry.controller);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(scale(tester), greaterThan(1.0));

        await tester.pumpAndSettle();
        expect(atRest(tester), isTrue);
      });
    }

    testWidgets('a repeating effect keeps playing until another effect replaces it', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      await pumpShown(tester, entry);

      entry.controller.shake(repeat: true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.hasRunningAnimations, isTrue, reason: 'still repeating long after one cycle');

      entry.controller.pulse();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a one-shot effect is not interrupted by another call (no spam)', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      await pumpShown(tester, entry);

      entry.controller.shake(duration: const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      entry.controller.bounce(scale: 1.0);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(scale(tester), closeTo(1.0, 0.0001));
      await tester.pumpAndSettle();
    });

    testWidgets('an effect requested before the entrance animation ends is played after it', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      await tester.pumpWidget(host(entry));
      entry.controller.bounce(scale: 0.3);
      await tester.pump();
      expect(atRest(tester), isTrue);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(tester), greaterThan(1.0));
      await tester.pumpAndSettle();
    });

    testWidgets('a custom effect builder wraps the bar', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf(
        appearance: FluentBarAppearance<void>(
          customEffectBuilder: (BuildContext context, AnimationController controller, Widget child) => Opacity(key: const Key('custom_effect'), opacity: 0.5, child: child),
        ),
      );
      await pumpShown(tester, entry);

      entry.controller.customEffect();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('custom_effect')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('custom_effect')), findsNothing);
    });

    testWidgets('a throwing custom effect builder is reported and the bar stays on screen', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf(
        appearance: FluentBarAppearance<void>(customEffectBuilder: (BuildContext context, AnimationController controller, Widget child) => throw Exception('effect failed')),
      );
      await pumpShown(tester, entry);

      entry.controller.customEffect();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('Bar'), findsOneWidget);
      expect(errors.map((FluentBarException e) => e.type), contains(FluentBarErrorType.customBuilderEffect));
      await tester.pumpAndSettle();
    });

    testWidgets('a custom effect without a builder leaves the bar untouched', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      await pumpShown(tester, entry);

      entry.controller.customEffect();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(atRest(tester), isTrue);
      await tester.pumpAndSettle();
    });
  });

  group('entrance animation', () {
    testWidgets('changing the entrance animation on the fly switches the transition', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf(appearance: const FluentBarAppearance<void>(entranceAnimation: FluentBarEntranceAnimation.slide));
      await pumpShown(tester, entry);
      expect(find.ancestor(of: find.text('Bar'), matching: find.byType(ScaleTransition)), findsNothing);

      entry.controller.updateAppearance(const FluentBarAppearance<void>(entranceAnimation: FluentBarEntranceAnimation.scale));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.ancestor(of: find.text('Bar'), matching: find.byType(ScaleTransition)), findsOneWidget);
    });

    for (final FluentBarEntranceAnimation animation in FluentBarEntranceAnimation.values) {
      for (final FluentBarPosition position in FluentBarPosition.values) {
        testWidgets('${animation.name} at ${position.name}: appears and disappears without errors', (WidgetTester tester) async {
          final FluentBarEntry<void> entry = entryOf(
            appearance: FluentBarAppearance<void>(entranceAnimation: animation),
            behavior: FluentBarBehavior(position: position),
          );

          await tester.pumpWidget(host(entry));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('Bar'), findsOneWidget);

          bool dismissed = false;
          unawaited(entry.internalController.dismiss().then((_) => dismissed = true));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(dismissed, isFalse);

          await tester.pump(const Duration(seconds: 1));
          expect(dismissed, isTrue);
        });
      }
    }
  });

  group('dismissal', () {
    testWidgets('a bar that is already hiding when the wrapper is built completes its dismissal', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      bool dismissed = false;
      unawaited(entry.internalController.dismiss().then((_) => dismissed = true));
      expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.hiding);

      await tester.pumpWidget(host(entry));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('removing the wrapper in the middle of the exit animation still completes the dismissal', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      await pumpShown(tester, entry);
      bool dismissed = false;
      unawaited(entry.internalController.dismiss().then((_) => dismissed = true));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(dismissed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(dismissed, isTrue);
    });
  });
}
