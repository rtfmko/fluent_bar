import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarAnalyticsPayload> events = <FluentBarAnalyticsPayload>[];

  void onEvent(FluentBarAnalyticsPayload payload) => events.add(payload);

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero)}) async {
    manager.resetForTesting();
    events.clear();
    manager.addAnalyticsListener(onEvent);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
  }

  FluentBarAnalyticsPayload last(FluentBarAnalyticsEvent event) => events.lastWhere((FluentBarAnalyticsPayload e) => e.event == event);

  testWidgets('a bar dropped by a full queue reports metrics with the reason dropped', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(maxQueueLength: 1, defaultTransitionDuration: Duration.zero));
    FluentBar.info<void>('On screen').persistent().show();
    FluentBar.info<void>('Waiting').persistent().show();
    final FluentBarEntry<void>? dropped = FluentBar.warning<void>('Too many').withId('extra').persistent().show();

    expect(dropped, isNull);

    final FluentBarMetrics metrics = last(FluentBarAnalyticsEvent.queueOverflow).metrics!;
    expect(metrics.dismissReason, FluentBarDismissReason.dropped);
    expect(metrics.wasVisible, isFalse);
    expect(metrics.visibleDuration, Duration.zero);
    expect(metrics.id, 'extra');
    expect(metrics.typeName, 'warning');
    expect(metrics.toMap()['dismiss_reason'], 'dropped');

    await cleanup(tester);
  });

  testWidgets('a bar closed while it waits in the queue reports how long it waited', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('On screen').persistent().show();
    final FluentBarEntry<void> waiting = FluentBar.info<void>('Waiting').withId('waiting').persistent().show()!;
    await tester.pump(const Duration(milliseconds: 50));

    waiting.close();

    final FluentBarAnalyticsPayload payload = last(FluentBarAnalyticsEvent.dismissed);
    expect(payload.item.id, 'waiting');
    expect(payload.metrics!.dismissReason, FluentBarDismissReason.manual);
    expect(payload.metrics!.wasVisible, isFalse);
    expect(payload.metrics!.queuedDuration, greaterThan(Duration.zero));

    await cleanup(tester);
  });

  testWidgets('clearQueue reports every waiting bar with metrics', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('On screen').persistent().show();
    FluentBar.info<void>('First').persistent().show();
    FluentBar.info<void>('Second').persistent().show();
    events.clear();

    FluentBar.clearQueue();

    expect(events.map((FluentBarAnalyticsPayload e) => e.event), everyElement(FluentBarAnalyticsEvent.dismissed));
    expect(events, hasLength(2));
    expect(events.every((FluentBarAnalyticsPayload e) => e.metrics != null && !e.metrics!.wasVisible), isTrue);

    await cleanup(tester);
  });

  testWidgets('relocated says where the bar was before', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().atTop().show()!;
    await tester.pump();

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
    await settle(tester);

    final FluentBarAnalyticsPayload payload = last(FluentBarAnalyticsEvent.relocated);
    expect(payload.previousPosition, FluentBarPosition.top);
    expect(payload.item.behavior.position, FluentBarPosition.bottom);
    expect(last(FluentBarAnalyticsEvent.shown).previousPosition, isNull);

    await cleanup(tester);
  });

  testWidgets('relocated through the queue also says where the bar was', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('Bottom').persistent().atBottom().show();
    final FluentBarEntry<void> entry = FluentBar.info<void>('Top').persistent().atTop().show()!;
    await tester.pump();

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
    await settle(tester);

    expect(last(FluentBarAnalyticsEvent.relocated).previousPosition, FluentBarPosition.top);

    await cleanup(tester);
  });

  testWidgets('metrics count updates and tell whether the bar had an action', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withId('counted').persistent().withAction('Undo').show()!;
    await tester.pump();

    entry.update(message: 'One');
    entry.patchAppearance((FluentBarAppearance<void> appearance) => appearance.copyWith(backgroundColor: Colors.teal));
    FluentBar.info<void>('Again').withId('counted').persistent().withAction('Undo').show();
    entry.close();
    await settle(tester);

    final FluentBarMetrics metrics = last(FluentBarAnalyticsEvent.dismissed).metrics!;
    expect(metrics.updateCount, 3);
    expect(metrics.hadAction, isTrue);
    expect(metrics.wasActionTapped, isFalse);
    expect(metrics.toMap()['update_count'], 3);
    expect(metrics.toMap()['had_action'], isTrue);

    await cleanup(tester);
  });

  testWidgets('a bar without an action and without updates says so', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().show()!;
    await tester.pump();
    entry.close();
    await settle(tester);

    final FluentBarMetrics metrics = last(FluentBarAnalyticsEvent.dismissed).metrics!;
    expect(metrics.updateCount, 0);
    expect(metrics.hadAction, isFalse);
    expect(metrics.progressOutcome, isNull);
    expect(metrics.toMap().containsKey('progress_outcome'), isFalse);
    expect(metrics.wasUntouched, isTrue);

    await cleanup(tester);
  });

  for (final (String name, void Function(FluentBarEntry<void> entry) finish, FluentBarProgressOutcome outcome) in <(String, void Function(FluentBarEntry<void>), FluentBarProgressOutcome)>[
    ('completed', (FluentBarEntry<void> e) => e.completeProgress(), FluentBarProgressOutcome.completed),
    ('failed', (FluentBarEntry<void> e) => e.failProgress(), FluentBarProgressOutcome.failed),
    ('canceled', (FluentBarEntry<void> e) => e.cancelProgress(), FluentBarProgressOutcome.canceled),
  ]) {
    testWidgets('the outcome of a progress ($name) comes with the final metrics', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').withLinearProgress(value: 0.2).show()!;
      await tester.pump();

      finish(entry);
      entry.close();
      await settle(tester);

      final FluentBarMetrics metrics = last(FluentBarAnalyticsEvent.dismissed).metrics!;
      expect(metrics.progressOutcome, outcome);
      expect(metrics.toMap()['progress_outcome'], name);

      await cleanup(tester);
    });
  }

  testWidgets('progress ticks through the controller are not counted as updates', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').withLinearProgress(value: 0).show()!;
    await tester.pump();

    for (int i = 1; i <= 5; i++) {
      entry.updateValue(i / 10);
    }
    entry.close();
    await settle(tester);

    expect(last(FluentBarAnalyticsEvent.dismissed).metrics!.updateCount, 0);

    await cleanup(tester);
  });

  testWidgets('plannedDuration is null for a persistent bar and the lifetime otherwise', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> persistent = FluentBar.info<void>('Stays').persistent().show()!;
    await tester.pump();
    persistent.close();
    await settle(tester);
    expect(last(FluentBarAnalyticsEvent.dismissed).metrics!.plannedDuration, isNull);

    final FluentBarEntry<void> timed = FluentBar.info<void>('Leaves').withDuration(const Duration(seconds: 3)).show()!;
    await tester.pump();
    timed.close();
    await settle(tester);
    expect(last(FluentBarAnalyticsEvent.dismissed).metrics!.plannedDuration, const Duration(seconds: 3));

    await cleanup(tester);
  });

  test('toFlatMap holds only strings and numbers, with one key per interaction', () {
    const FluentBarMetrics metrics = FluentBarMetrics(
      id: 'upload',
      visibleDuration: Duration(milliseconds: 1500),
      plannedDuration: null,
      dismissReason: FluentBarDismissReason.actionButton,
      timedOut: false,
      interactions: <FluentBarInteraction, int>{FluentBarInteraction.tap: 2, FluentBarInteraction.action: 1},
      position: FluentBarPosition.bottom,
      hadAction: true,
      progressOutcome: FluentBarProgressOutcome.completed,
      typeName: 'info',
    );

    final Map<String, Object> flat = metrics.toFlatMap();

    expect(flat.values.every((Object value) => value is String || value is num), isTrue);
    expect(flat['id'], 'upload');
    expect(flat['visible_ms'], 1500);
    expect(flat['dismiss_reason'], 'actionButton');
    expect(flat['timed_out'], 0);
    expect(flat['had_action'], 1);
    expect(flat['was_action_tapped'], 1);
    expect(flat['interaction_tap'], 2);
    expect(flat['interaction_action'], 1);
    expect(flat['progress_outcome'], 'completed');
    expect(flat.containsKey('interactions'), isFalse, reason: 'a nested map is not allowed');
    expect(flat.containsKey('planned_ms'), isFalse, reason: 'absent values are left out');
    expect(flat.containsKey('preset'), isFalse);
  });

  testWidgets('the payload gives a flat map for every event, with metrics when it has them', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.snack<void>('Archived', id: 'archive').atBottom().show()!;
    await tester.pump();

    final Map<String, Object> shown = last(FluentBarAnalyticsEvent.shown).toFlatMap();
    expect(shown, <String, Object>{'id': 'archive', 'type_name': 'info', 'preset': 'snack', 'position': 'bottom'});

    entry.close();
    await settle(tester);

    final Map<String, Object> dismissed = last(FluentBarAnalyticsEvent.dismissed).toFlatMap();
    expect(dismissed['id'], 'archive');
    expect(dismissed['dismiss_reason'], 'manual');
    expect(dismissed['was_visible'], 1);
    expect(dismissed.values.every((Object value) => value is String || value is num), isTrue);

    await cleanup(tester);
  });

  testWidgets('the flat map of a pause and of a relocation carries their extras', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withDuration(const Duration(seconds: 30)).atTop().show()!;
    await tester.pump();

    entry.pause();
    expect(last(FluentBarAnalyticsEvent.paused).toFlatMap()['pause_reason'], 'manual');

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
    await settle(tester);
    final Map<String, Object> relocated = last(FluentBarAnalyticsEvent.relocated).toFlatMap();
    expect(relocated['previous_position'], 'top');
    expect(relocated['position'], 'bottom');

    await cleanup(tester);
  });

  test('the convenience flags of metrics follow the interactions', () {
    const FluentBarMetrics metrics = FluentBarMetrics(
      id: null,
      visibleDuration: Duration(seconds: 1),
      plannedDuration: null,
      dismissReason: FluentBarDismissReason.timeout,
      timedOut: true,
      interactions: <FluentBarInteraction, int>{FluentBarInteraction.tap: 1},
    );

    expect(metrics.wasTapped, isTrue);
    expect(metrics.wasActionTapped, isFalse);
    expect(metrics.wasUntouched, isFalse);
    expect(metrics.toMap()['was_tapped'], isTrue);
    expect(metrics.toMap()['was_untouched'], isFalse);
    expect(metrics.toMap()['planned_ms'], isNull);
  });
}
