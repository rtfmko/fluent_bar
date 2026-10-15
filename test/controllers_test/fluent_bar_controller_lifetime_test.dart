import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const FluentBarOptions<void> _bottom = FluentBarOptions<void>(behavior: FluentBarBehavior(position: FluentBarPosition.bottom));

Future<void> _boot(WidgetTester tester) async {
  FluentBarManager.instance.resetForTesting();
  await tester.pumpWidget(
    MaterialApp(
      builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
      home: const Scaffold(body: SizedBox()),
    ),
  );
  await tester.pump();
}

Future<void> _settle(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
  await tester.pump(const Duration(seconds: 2));
}

Duration _remaining(FluentBarEntry<void> entry) => entry.controller.remainingDurationNotifier.value;

void main() {
  setUp(() => FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch());
  tearDown(() => FluentBarControllerImpl.stopwatchFactory = Stopwatch.new);

  group('Auto-dismiss per region', () {
    testWidgets('untouched bars auto-dismiss in both regions', (WidgetTester tester) async {
      await _boot(tester);
      FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2));
      FluentBar.show<void>(message: 'bottom', duration: const Duration(seconds: 2), options: _bottom);
      await tester.pump(const Duration(milliseconds: 600));
      expect(FluentBar.mainActiveItem, isNotNull);
      expect(FluentBar.bottomActiveItem, isNotNull);

      await _settle(tester, const Duration(seconds: 2));
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.bottomActiveItem, isNull);
    });

    testWidgets('bottom bar still auto-dismisses after pause/resume', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'bottom', duration: const Duration(seconds: 2), options: _bottom)!;
      await tester.pump(const Duration(milliseconds: 600));

      entry.controller.pause();
      entry.controller.resume();

      await _settle(tester, const Duration(seconds: 2));
      expect(FluentBar.bottomActiveItem, isNull);
    });

    testWidgets('pausing one region does not affect the other', (WidgetTester tester) async {
      await _boot(tester);
      FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2));
      final FluentBarEntry<void> bottom = FluentBar.show<void>(message: 'bottom', duration: const Duration(seconds: 2), options: _bottom)!;
      await tester.pump(const Duration(milliseconds: 600));

      bottom.controller.pause();

      await _settle(tester, const Duration(seconds: 10));
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.bottomActiveItem, same(bottom));

      bottom.controller.resume();
      await _settle(tester, const Duration(seconds: 2));
      expect(FluentBar.bottomActiveItem, isNull);
    });

    testWidgets('timeout reports the timeout reason', (WidgetTester tester) async {
      await _boot(tester);
      FluentBarDismissReason? reason;
      FluentBar.show<void>(
        message: 'bottom',
        duration: const Duration(seconds: 1),
        options: FluentBarOptions<void>(
          behavior: const FluentBarBehavior(position: FluentBarPosition.bottom),
          callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => reason = m.dismissReason),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await _settle(tester, const Duration(seconds: 1));
      expect(reason, FluentBarDismissReason.timeout);
    });
  });

  group('Pause', () {
    testWidgets('time does not pass while paused, repeated pause is a no-op', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 5))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.pause();
      final Duration atPause = _remaining(entry);
      expect(atPause, const Duration(seconds: 4));

      await tester.pump(const Duration(seconds: 3));
      entry.controller.pause();
      expect(_remaining(entry), atPause);

      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));

      entry.controller.resume();
      await tester.pump(const Duration(seconds: 3));
      expect(FluentBar.mainActiveItem, same(entry));
      await _settle(tester, const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });
  });

  group('setLoading', () {
    testWidgets('add/subtractDuration while loading change the budget without resuming', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 5))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.setLoading(isLoading: true);
      expect(_remaining(entry), const Duration(seconds: 4));

      entry.controller.addDuration(const Duration(seconds: 3));
      expect(_remaining(entry), const Duration(seconds: 7));
      expect(entry.controller.totalDurationNotifier.value, const Duration(seconds: 8));

      entry.controller.subtractDuration(const Duration(seconds: 2));
      expect(_remaining(entry), const Duration(seconds: 5));

      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));
      expect(_remaining(entry), const Duration(seconds: 5));

      entry.controller.setLoading(isLoading: false);
      expect(_remaining(entry), const Duration(seconds: 5));

      await tester.pump(const Duration(seconds: 4));
      expect(FluentBar.mainActiveItem, same(entry));
      await _settle(tester, const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('updateDuration while loading is applied and stays held', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 5))!;
      await tester.pump(const Duration(seconds: 1));
      entry.controller.setLoading(isLoading: true);

      entry.controller.updateDuration(const Duration(seconds: 10));
      expect(_remaining(entry), const Duration(seconds: 9));

      entry.controller.updateDuration(const Duration(seconds: 3), resetTimer: true);
      expect(_remaining(entry), const Duration(seconds: 3));

      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));

      entry.controller.setLoading(isLoading: false);
      await _settle(tester, const Duration(seconds: 3));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('loading and explicit pause are independent holds', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2))!;
      await tester.pump(const Duration(milliseconds: 500));

      entry.controller.pause();
      entry.controller.setLoading(isLoading: true);
      entry.controller.setLoading(isLoading: false);

      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));

      entry.controller.resume();
      await _settle(tester, const Duration(seconds: 2));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('gestures are restored after loading', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 5))!;
      await tester.pump(const Duration(milliseconds: 500));

      entry.controller.setLoading(isLoading: true);
      expect(entry.controller.itemNotifier.value.behavior.isSwipeEnabled, isFalse);
      expect(entry.controller.itemNotifier.value.behavior.dismissOnTap, isFalse);
      expect(entry.controller.isActionExecutingNotifier.value, isTrue);

      entry.controller.setLoading(isLoading: false);
      expect(entry.controller.itemNotifier.value.behavior.isSwipeEnabled, isNull);
      expect(entry.controller.itemNotifier.value.behavior.dismissOnTap, isNull);
      expect(entry.controller.isActionExecutingNotifier.value, isFalse);

      await FluentBar.closeAll(skipAnimation: true);
    });
  });

  group('Duration updates', () {
    testWidgets('updateDuration(resetTimer) on a running bar restarts the countdown', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.updateDuration(const Duration(seconds: 3), resetTimer: true);

      await tester.pump(const Duration(milliseconds: 2500));
      expect(FluentBar.mainActiveItem, same(entry));
      await _settle(tester, const Duration(milliseconds: 500));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('updateDuration without reset keeps the elapsed time', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.updateDuration(const Duration(seconds: 4));
      expect(_remaining(entry), const Duration(seconds: 3));

      await _settle(tester, const Duration(seconds: 3));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('addDuration survives an unrelated item rebind', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.addDuration(const Duration(seconds: 5));
      entry.controller.updateBehavior(behavior: const FluentBarBehavior(dismissOnTap: false));
      expect(_remaining(entry), const Duration(seconds: 6));

      await FluentBar.closeAll(skipAnimation: true);
    });

    testWidgets('subtractDuration that would expire the bar is rejected', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.subtractDuration(const Duration(seconds: 5));
      expect(_remaining(entry), const Duration(seconds: 1));

      await FluentBar.closeAll(skipAnimation: true);
    });
  });

  group('Progress', () {
    testWidgets('bar is persistent while progress runs and times out after completion', (WidgetTester tester) async {
      await _boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'main', duration: const Duration(seconds: 2))!;
      await tester.pump(const Duration(seconds: 1));

      entry.controller.updateProgress(const FluentBarProgressFraction(1, 2));
      expect(entry.controller.totalDurationNotifier.value, isNull);

      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));

      entry.controller.updateProgress(const FluentBarProgressFraction(2, 2));
      expect(_remaining(entry), const Duration(seconds: 2));

      await _settle(tester, const Duration(seconds: 2));
      expect(FluentBar.mainActiveItem, isNull);
    });
  });

  group('Manager', () {
    testWidgets('closeAll honours the dismiss reason', (WidgetTester tester) async {
      await _boot(tester);
      FluentBarDismissReason? reason;
      FluentBar.show<void>(
        message: 'main',
        duration: const Duration(seconds: 5),
        options: FluentBarOptions<void>(callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => reason = m.dismissReason)),
      );
      FluentBar.show<void>(message: 'queued', duration: const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));
      expect(FluentBar.mainQueueLength, 1);

      final Future<void> closing = FluentBar.closeAll(reason: FluentBarDismissReason.swipe);
      await tester.pump(const Duration(seconds: 2));
      await closing;

      expect(reason, FluentBarDismissReason.swipe);
      expect(FluentBar.mainQueueLength, 0);
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('dismissAndClear keeps a bar shown from onDismiss', (WidgetTester tester) async {
      await _boot(tester);
      FluentBar.show<void>(
        message: 'first',
        duration: const Duration(seconds: 5),
        options: FluentBarOptions<void>(
          callbacks: FluentBarCallbacks<void>(
            onDismiss: (_, _) => FluentBar.show<void>(message: 'second', duration: const Duration(seconds: 5)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      FluentBar.dismissAndClear();
      await tester.pump(const Duration(milliseconds: 600));

      expect(FluentBar.mainActiveItem?.currentItem.message, 'second');
      expect(find.text('second'), findsOneWidget);

      await FluentBar.closeAll(skipAnimation: true);
    });
  });
}
