import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  setUp(() => FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch());
  tearDown(() => FluentBarControllerImpl.stopwatchFactory = Stopwatch.new);

  group('time ticker', () {
    FluentBarControllerImpl<void> shown(int seconds) {
      final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(
        FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'm',
          duration: Duration(seconds: seconds),
        ),
      );
      controller
        ..changeState(FluentBarLifecycleState.visible)
        ..startTimersOnShow(Duration(seconds: seconds), manager);
      return controller;
    }

    test('does not run while nobody listens, yet the values stay up to date', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<void> controller = shown(10);

        expect(async.periodicTimerCount, 0);
        expect(async.nonPeriodicTimerCount, 1);

        async.elapse(const Duration(seconds: 4));
        expect(controller.remainingDurationNotifier.value, const Duration(seconds: 6));
        expect(controller.elapsedDurationNotifier.value, const Duration(seconds: 4));
        expect(controller.remainingProgressNotifier.value, closeTo(0.6, 0.001));
        expect(controller.elapsedProgressNotifier.value, closeTo(0.4, 0.001));

        controller.dispose();
      });
    });

    test('starts with the first listener and stops with the last one', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<void> controller = shown(10);
        int notifications = 0;
        void listener() => notifications++;
        void other() {}

        controller.remainingProgressNotifier.addListener(listener);
        expect(async.periodicTimerCount, 1);

        async.elapse(const Duration(seconds: 1));
        expect(notifications, greaterThan(5));

        controller.remainingDurationNotifier.addListener(other);
        expect(async.periodicTimerCount, 1);

        controller.remainingProgressNotifier.removeListener(listener);
        expect(async.periodicTimerCount, 1);
        controller.remainingDurationNotifier.removeListener(other);
        expect(async.periodicTimerCount, 0);

        final int before = notifications;
        async.elapse(const Duration(seconds: 1));
        expect(notifications, before);

        controller.dispose();
      });
    });

    test('a listener added while the bar is paused starts the ticker only on resume', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<void> controller = shown(10);
        controller.pause();
        controller.remainingProgressNotifier.addListener(() {});
        expect(async.periodicTimerCount, 0);

        controller.resume();
        expect(async.periodicTimerCount, 1);

        controller.dispose();
        expect(async.periodicTimerCount, 0);
        expect(async.nonPeriodicTimerCount, 0);
      });
    });

    test('an expired bar reports the final values and removing a listener after dispose is safe', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<void> controller = shown(2);
        final List<double> seen = <double>[];
        void listener() => seen.add(controller.remainingProgressNotifier.value);
        controller.remainingProgressNotifier.addListener(listener);

        async.elapse(const Duration(seconds: 3));
        expect(seen.last, 0.0);
        expect(controller.remainingDurationNotifier.value, Duration.zero);
        expect(controller.elapsedProgressNotifier.value, 1.0);
        expect(async.periodicTimerCount, 0);

        controller.dispose();
        controller.remainingProgressNotifier.removeListener(listener);
      });
    });

    testWidgets('a bar without a timeout bar keeps no periodic timer, a bar with one does', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      final FluentBarControllerImpl<void> plain = FluentBar.info<void>('Plain').withId('plain').show()!.controller as FluentBarControllerImpl<void>;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(plain.remainingProgressNotifier, isA<ChangeNotifier>());
      // ignore: invalid_use_of_protected_member
      expect((plain.remainingProgressNotifier as ChangeNotifier).hasListeners, isFalse);

      final FluentBarControllerImpl<void> timed = FluentBar.info<void>('Timed').withId('timed').atBottom().withTimeoutBar().show()!.controller as FluentBarControllerImpl<void>;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // ignore: invalid_use_of_protected_member
      expect((timed.remainingProgressNotifier as ChangeNotifier).hasListeners, isTrue);

      manager.resetForTesting();
      await tester.pump();
    });
  });

  group('repeated show', () {
    testWidgets('updating a bar by its id creates no new entry or controller', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      FluentBarItem<void> upload(double value) => FluentBar.info<void>('Uploading').withId('upload').withLinearProgress(value: value);

      final FluentBarEntry<void> first = upload(0).show()!;
      await tester.pump();

      for (int step = 1; step <= 20; step++) {
        expect(upload(step / 40).show(), same(first));
      }
      final FluentBarEntry<void> queued = FluentBar.info<void>('Queued').withId('queued').show()!;
      for (int i = 0; i < 5; i++) {
        expect(FluentBar.info<void>('Queued $i').withId('queued').show(), same(queued));
      }
      expect(FluentBar.info<void>('Ignored').withId('queued').withDuplicatePolicy(FluentBarDuplicatePolicy.ignore).show(), same(queued));

      final FluentBarEntry<void> next = FluentBar.info<void>('Next').withId('next').show()!;
      expect(queued.sequence, first.sequence + 1);
      expect(next.sequence, first.sequence + 2);

      expect(first.controller.progressStateNotifier.value, const FluentBarProgressState.value(0.5));
      expect(queued.item.message, 'Queued 4');

      manager.resetForTesting();
      await tester.pump();
    });

    testWidgets('find returns shown and queued bars', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      final FluentBarEntry<void> top = FluentBar.info<void>('Top').withId('top').show()!;
      final FluentBarEntry<void> bottom = FluentBar.info<void>('Bottom').withId('bottom').atBottom().show()!;
      final FluentBarEntry<void> waitingTop = FluentBar.info<void>('Waiting').withId('waiting_top').show()!;
      final FluentBarEntry<void> waitingBottom = FluentBar.info<void>('Waiting').withId('waiting_bottom').atBottom().show()!;
      await tester.pump();

      expect(FluentBar.find('top'), same(top));
      expect(FluentBar.find('bottom'), same(bottom));
      expect(FluentBar.find('waiting_top'), same(waitingTop));
      expect(FluentBar.find('waiting_bottom'), same(waitingBottom));
      expect(FluentBar.find('missing'), isNull);

      manager.resetForTesting();
      await tester.pump();
    });
  });
}
