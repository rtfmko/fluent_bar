import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig()}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
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

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarItem<void> upload(double value, {FluentBarDuplicatePolicy? policy, String message = 'Uploading'}) {
    final FluentBarItem<void> item = FluentBar.info<void>(message).withId('upload').withLinearProgress(value: value, showText: true);
    return policy == null ? item : item.withDuplicatePolicy(policy);
  }

  double? progressOf(FluentBarEntry<dynamic> entry) => entry.controller.progressStateNotifier.value?.progress;

  group('through the controller', () {
    testWidgets('updates the value, keeps the bar alive and finishes it on completion', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = upload(0.1).show()!;
      await settle(tester);
      expect(find.text('10%'), findsOneWidget);

      entry.controller.updateProgress(const FluentBarProgressState.value(0.6));
      await settle(tester);
      expect(progressOf(entry), 0.6);
      expect(find.text('60%'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));

      entry.controller.updateProgress(const FluentBarProgressState.value(1.0), completedMessage: 'Uploaded', completedType: FluentBarType.success);
      await settle(tester);
      expect(entry.currentItem.message, 'Uploaded');
      expect(entry.currentItem.type, FluentBarType.success);
      expect(events, contains(FluentBarAnalyticsEvent.progressCompleted));

      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
      expect(FluentBar.mainActiveItem, isNull);
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });

  group('through the bar itself', () {
    testWidgets('updateValue / updateFraction / updateProgress with a completion text', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = upload(0.0).show()!;
      await settle(tester);

      entry.updateValue(0.25);
      expect(progressOf(entry), 0.25);

      entry.updateFraction(3, 4);
      await settle(tester);
      expect(progressOf(entry), 0.75);
      expect(find.text('3 / 4'), findsOneWidget);

      entry.updateFraction(4, 4, completedMessage: 'All files sent', completedTitle: 'Done', completedType: FluentBarType.success);
      await settle(tester);
      expect(entry.currentItem.message, 'All files sent');
      expect(entry.currentItem.title, 'Done');
      expect(entry.currentItem.type, FluentBarType.success);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('cancelProgress can switch the type', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = upload(0.4).show()!;
      await settle(tester);

      entry.cancelProgress(fallbackMessage: 'Canceled', fallbackType: FluentBarType.warning);
      await settle(tester);

      expect(entry.currentItem.message, 'Canceled');
      expect(entry.currentItem.type, FluentBarType.warning);
      expect(entry.currentItem.progressState, isNull);

      await cleanup(tester);
    });

    testWidgets('works for a bar that is still queued', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.showInfo<void>('Active', isPersistent: true);
      final FluentBarEntry<void> queued = upload(0.1).show()!;
      await settle(tester);
      expect(FluentBar.mainQueueLength, 1);

      queued.updateValue(0.8);

      expect(progressOf(queued), 0.8);
      expect(FluentBar.mainQueue.single, same(queued));
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });

  group('by showing a bar with the same id', () {
    testWidgets('default policy: the shown bar is updated in place, no second bar appears', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = upload(0.1).show()!;
      await settle(tester);

      final FluentBarEntry<void>? again = upload(0.5, message: 'Half way').show();
      await settle(tester);

      expect(again, same(entry));
      expect(progressOf(entry), 0.5);
      expect(entry.currentItem.message, 'Half way');
      expect(find.text('50%'), findsOneWidget);
      expect(FluentBar.allQueueLength, 0);
      expect(events.where((FluentBarAnalyticsEvent e) => e == FluentBarAnalyticsEvent.shown), hasLength(1));

      events.clear();
      upload(1.0, message: 'Uploaded').show();
      await settle(tester);
      expect(entry.currentItem.progressState?.isCompleted, isTrue);
      expect(events, contains(FluentBarAnalyticsEvent.progressCompleted));
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
      expect(FluentBar.mainActiveItem, isNull);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a progress update keeps the action, callbacks, behavior and look of the bar', (WidgetTester tester) async {
      await boot(tester);
      int dismissed = 0;
      final FluentBarEntry<void> entry = upload(
        0.1,
      ).withTitle('Files').withAction('Cancel', closeOnAction: false).undismissible().withBackground(Colors.purple).onDismiss((_, _) => dismissed++).show()!;
      await settle(tester);

      upload(0.5, message: 'Half way').show();
      await settle(tester);

      expect(progressOf(entry), 0.5);
      expect(entry.currentItem.message, 'Half way');
      expect(entry.currentItem.title, 'Files');
      expect(entry.currentItem.actions?.label, 'Cancel');
      expect(entry.currentItem.behavior.isSwipeEnabled, isFalse);
      expect(entry.currentItem.appearance.backgroundColor, Colors.purple);
      expect(find.text('Cancel'), findsOneWidget);

      FluentBar.success<void>('Uploaded').withId('upload').withTitle('Done').withLinearProgress(value: 1.0).show();
      await settle(tester);
      expect(entry.currentItem.type, FluentBarType.success);
      expect(entry.currentItem.title, 'Done');
      expect(entry.currentItem.actions?.label, 'Cancel');

      entry.close();
      await settle(tester);
      expect(dismissed, 1);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a bar without progress replaces the existing one entirely', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.loading<void>('Loading', id: 'job').withAction('Cancel').show()!;
      await settle(tester);
      expect(entry.currentItem.behavior.isSwipeEnabled, isFalse);

      final FluentBarEntry<void>? again = FluentBar.showSuccess<void>('Done', id: 'job');
      await settle(tester);

      expect(again, same(entry));
      expect(entry.currentItem.message, 'Done');
      expect(entry.currentItem.progressState, isNull);
      expect(entry.currentItem.actions, isNull);
      expect(entry.currentItem.behavior.isSwipeEnabled, isNull);
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
      expect(FluentBar.mainActiveItem, isNull);

      await cleanup(tester);
    });

    testWidgets('allow policy: a running progress with the same id is updated, not duplicated', (WidgetTester tester) async {
      await boot(tester);
      const FluentBarDuplicatePolicy allow = FluentBarDuplicatePolicy.allow;

      final FluentBarEntry<void> shown = upload(0.1, policy: allow).show()!;
      await settle(tester);
      expect(upload(0.6, policy: allow).show(), same(shown));
      expect(progressOf(shown), 0.6);
      expect(FluentBar.allQueueLength, 0);

      final FluentBarEntry<void> queued = FluentBar.info<void>('Second').withId('second').withDuplicatePolicy(allow).withLinearProgress(value: 0.2).show()!;
      expect(FluentBar.info<void>('Second').withId('second').withDuplicatePolicy(allow).withLinearProgress(value: 0.9).show(), same(queued));
      expect(progressOf(queued), 0.9);
      expect(FluentBar.mainQueueLength, 1);

      shown.completeProgress();
      final FluentBarEntry<void>? fresh = upload(0.1, policy: allow).show();
      expect(fresh, isNot(same(shown)));
      expect(FluentBar.mainQueueLength, 2);

      FluentBar.info<void>('Plain').withId('plain').withDuplicatePolicy(allow).persistent().show();
      FluentBar.info<void>('Plain').withId('plain').withDuplicatePolicy(allow).persistent().show();
      expect(FluentBar.mainQueueLength, 4);
      expect(errors, isEmpty);

      await cleanup(tester);
    });
    testWidgets('default policy: a queued bar is updated in the queue', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.showInfo<void>('Active', isPersistent: true);
      final FluentBarEntry<void> queued = upload(0.1).show()!;
      await settle(tester);

      final FluentBarEntry<void>? again = upload(0.7).show();

      expect(again, same(queued));
      expect(progressOf(queued), 0.7);
      expect(FluentBar.mainQueueLength, 1);

      await cleanup(tester);
    });

    testWidgets('ignore policy still lets a new progress through, shown or queued', (WidgetTester tester) async {
      await boot(tester);
      const FluentBarDuplicatePolicy ignore = FluentBarDuplicatePolicy.ignore;

      final FluentBarEntry<void> shown = upload(0.1, policy: ignore).show()!;
      await settle(tester);
      upload(0.4, policy: ignore).show();
      expect(progressOf(shown), 0.4);

      events.clear();
      upload(0.4, policy: ignore, message: 'Other text').show();
      expect(shown.currentItem.message, 'Uploading');
      expect(events, contains(FluentBarAnalyticsEvent.ignoredDuplicate));

      final FluentBarEntry<void> queued = FluentBar.info<void>('Second').withId('second').withDuplicatePolicy(ignore).withLinearProgress(value: 0.2).show()!;
      expect(FluentBar.mainQueue.single, same(queued));

      FluentBar.info<void>('Second').withId('second').withDuplicatePolicy(ignore).withLinearProgress(value: 0.9).show();
      expect(progressOf(queued), 0.9);
      expect(FluentBar.mainQueueLength, 1);

      events.clear();
      FluentBar.info<void>('Second again').withId('second').withDuplicatePolicy(ignore).withLinearProgress(value: 0.9).show();
      expect(queued.currentItem.message, 'Second');
      expect(events, contains(FluentBarAnalyticsEvent.ignoredDuplicate));
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });
}
