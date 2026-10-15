import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _LongType extends FluentBarType {
  const _LongType();

  @override
  String get name => 'long';

  @override
  Duration get duration => const Duration(seconds: 20);
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarException> errors = <FluentBarException>[];
  final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
  void onAnalytics(FluentBarAnalyticsPayload payload) => events.add(payload.event);

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    errors.clear();
    events.clear();
    FluentBar.addErrorHandler(onError);
    FluentBar.addAnalyticsListener(onAnalytics);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBar.removeAnalyticsListener(onAnalytics);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
  });

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
    events.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  group('progress outcome of a bar that is still queued', () {
    testWidgets('a future finishing before the bar is shown still reports completion and failure', (WidgetTester tester) async {
      await boot(tester);
      int completed = 0;
      int failed = 0;
      FluentBar.showInfo<void>('Active', isPersistent: true);

      final Completer<int> ok = Completer<int>();
      final Completer<int> bad = Completer<int>();
      unawaited(
        FluentBar.future<int>(
          ok.future,
          loading: 'Loading 1',
          id: 'l1',
          success: (int value) => 'Done $value',
          options: FluentBarOptions<void>(callbacks: FluentBarCallbacks<void>(onProgressCompleted: (_) => completed++)),
        ),
      );
      unawaited(
        FluentBar.future<int>(
          bad.future,
          loading: 'Loading 2',
          id: 'l2',
          error: (Object e) => 'Failed',
          options: FluentBarOptions<void>(callbacks: FluentBarCallbacks<void>(onProgressFailed: (_) => failed++)),
        ).catchError((Object _) => 0),
      );
      await tester.pump();
      expect(FluentBar.allQueueLength, 2);

      ok.complete(7);
      bad.completeError(StateError('boom'));
      await tester.pump();
      await tester.pump();

      expect(completed, 1);
      expect(failed, 1);
      expect(events, containsAll(<FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.progressCompleted, FluentBarAnalyticsEvent.progressFailed]));

      expect(FluentBar.find('l1')!.currentItem.message, 'Done 7');
      expect(FluentBar.find('l1')!.currentItem.progressState?.isCompleted, isTrue);
      expect(FluentBar.find('l2')!.currentItem.message, 'Failed');
      expect(FluentBar.find('l2')!.currentItem.progressState, isNull);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('cancelProgress on a queued bar reports the cancellation', (WidgetTester tester) async {
      await boot(tester);
      int canceled = 0;
      FluentBar.showInfo<void>('Active', isPersistent: true);
      final FluentBarEntry<void>? queued = FluentBar.show<void>(
        message: 'Loading',
        options: FluentBarOptions<void>(
          progressState: const FluentBarProgressState.indeterminate(),
          callbacks: FluentBarCallbacks<void>(onProgressCanceled: (_) => canceled++),
        ),
      );
      await tester.pump();
      expect(FluentBar.allQueueLength, 1);

      queued!.controller.cancelProgress(fallbackMessage: 'Canceled');
      await tester.pump();

      expect(canceled, 1);
      expect(events, contains(FluentBarAnalyticsEvent.progressCanceled));
      expect(queued.currentItem.message, 'Canceled');

      await cleanup(tester);
    });
  });

  group('updateContent with another type', () {
    testWidgets('applies the duration of the new type at once and keeps the time already spent', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Message');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(entry!.controller.totalDurationNotifier.value, const Duration(seconds: 4));

      entry.controller.updateContent(type: const _LongType());
      await tester.pump();

      expect(entry.controller.totalDurationNotifier.value, const Duration(seconds: 20));
      expect(entry.controller.remainingDurationNotifier.value, const Duration(seconds: 19));

      entry.controller.addDuration(const Duration(seconds: 5));
      entry.controller.updateContent(message: 'Other');
      expect(entry.controller.totalDurationNotifier.value, const Duration(seconds: 25));

      await cleanup(tester);
    });

    testWidgets('an explicit item duration wins over the new type', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Message', duration: const Duration(seconds: 7));
      await tester.pump();

      entry!.controller.updateContent(type: const _LongType());

      expect(entry.controller.totalDurationNotifier.value, const Duration(seconds: 7));
      await cleanup(tester);
    });
  });
}
