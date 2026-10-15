import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<String> log = <String>[];
  void onAnalytics(FluentBarAnalyticsPayload payload) => log.add('${payload.item.id}:${payload.event.name}');

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    FluentBar.addAnalyticsListener(onAnalytics);
  });

  tearDown(() {
    FluentBar.removeAnalyticsListener(onAnalytics);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
  });

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    log.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  List<String> eventsOf(String id) => log.where((String line) => line.startsWith('$id:')).map((String line) => line.split(':').last).toList();

  testWidgets('queued is reported only for a bar that has to wait', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('First').withId('first').persistent().show();
    FluentBar.info<void>('Second').withId('second').persistent().show();
    FluentBar.info<void>('Forced A').withId('fa').persistent().atBottom().forced().show();
    FluentBar.info<void>('Forced B').withId('fb').persistent().atBottom().forced().show();
    await settle(tester);

    expect(eventsOf('first'), <String>['requested', 'shown']);
    expect(eventsOf('second'), <String>['requested', 'queued']);
    expect(eventsOf('fa'), <String>['requested', 'shown']);
    expect(eventsOf('fb'), <String>['requested', 'queued']);

    await cleanup(tester);
  });

  testWidgets('tapped is reported for a tap on the bar itself', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('Tap me').withId('tap').persistent().dismissOnTap().show();
    await settle(tester);

    await tester.tap(find.text('Tap me'));
    await settle(tester);

    expect(eventsOf('tap'), <String>['requested', 'shown', 'tapped', 'dismissed']);

    await cleanup(tester);
  });

  testWidgets('paused / resumed follow the countdown, whatever stops it', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Timed').withId('timed').withDuration(const Duration(seconds: 10)).show()!;
    await settle(tester);

    entry.pause();
    entry.pause();
    entry.controller.setLoading(isLoading: true);
    entry.resume();
    expect(eventsOf('timed'), <String>['requested', 'shown', 'paused']);

    entry.controller.setLoading(isLoading: false);
    expect(eventsOf('timed'), <String>['requested', 'shown', 'paused', 'resumed']);

    final FluentBarEntry<void> sticky = FluentBar.info<void>('Sticky').withId('sticky').persistent().atBottom().show()!;
    await settle(tester);
    sticky
      ..pause()
      ..resume();
    expect(eventsOf('sticky'), <String>['requested', 'shown']);

    await cleanup(tester);
  });

  group('pause reason', () {
    final List<String> pauses = <String>[];
    void onPause(FluentBarAnalyticsPayload payload) {
      if (payload.pauseReason != null) pauses.add('${payload.event.name}:${payload.pauseReason!.name}');
    }

    setUp(() {
      pauses.clear();
      FluentBar.addAnalyticsListener(onPause);
    });

    tearDown(() => FluentBar.removeAnalyticsListener(onPause));

    testWidgets('every code-driven pause carries its reason, and resumed repeats it', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Timed').withId('timed').withDuration(const Duration(seconds: 30)).show()!;
      await settle(tester);

      entry
        ..pause()
        ..resume();
      entry.controller
        ..setLoading(isLoading: true)
        ..setLoading(isLoading: false);
      expect(pauses, <String>['paused:manual', 'resumed:manual', 'paused:loading', 'resumed:loading']);

      pauses.clear();
      final Completer<void> work = Completer<void>();
      unawaited(entry.controller.handleAction(onPressed: (_, _) => work.future, closeOnAction: false));
      expect(pauses, <String>['paused:action']);
      work.complete();
      await tester.pump();
      expect(pauses, <String>['paused:action', 'resumed:action']);

      expect(log.where((String line) => line.endsWith(':shown')), isNotEmpty);
      await cleanup(tester);
    });

    testWidgets('a tap is not a pause; holding the bar longer than the threshold is', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Hold me').withId('hold').withDuration(const Duration(seconds: 30)).dismissOnTap(false).onTap((_) {}).show()!;
      await settle(tester);

      await tester.tap(find.text('Hold me'));
      await tester.tap(find.text('Hold me'));
      await tester.pump(const Duration(seconds: 1));
      expect(pauses, isEmpty);
      expect(eventsOf('hold'), <String>['requested', 'shown', 'tapped', 'tapped']);

      final Duration before = entry.controller.remainingDurationNotifier.value;
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
      await tester.pump(FluentBarControllerImpl.touchPauseReportDelay - const Duration(milliseconds: 50));
      expect(pauses, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      expect(pauses, <String>['paused:touch']);

      await tester.pump(const Duration(seconds: 5));
      expect(entry.controller.remainingDurationNotifier.value, before);

      await gesture.up();
      await tester.pump();
      expect(pauses, <String>['paused:touch', 'resumed:touch']);

      await cleanup(tester);
    });

    testWidgets('a touch on top of a code pause does not add events', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Hold me').withId('hold').withDuration(const Duration(seconds: 30)).dismissOnTap(false).show()!;
      await settle(tester);

      entry.pause();
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      expect(pauses, <String>['paused:manual']);

      entry.resume();
      expect(pauses, <String>['paused:manual', 'resumed:manual']);

      await cleanup(tester);
    });
  });

  testWidgets('disabled events are not delivered to listeners', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.patchConfig(
      (FluentBarConfig c) => c.copyWith(disabledAnalyticsEvents: <FluentBarAnalyticsEvent>{FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.paused, FluentBarAnalyticsEvent.resumed}),
    );

    final FluentBarEntry<void> entry = FluentBar.info<void>('Quiet').withId('quiet').withDuration(const Duration(seconds: 30)).show()!;
    await settle(tester);
    entry
      ..pause()
      ..resume();
    entry.close();
    await settle(tester);

    expect(eventsOf('quiet'), <String>['shown', 'dismissed']);

    expect(FluentBar.currentConfig, isNot(const FluentBarConfig()));
    expect(FluentBar.currentConfig.hashCode, isNot(const FluentBarConfig().hashCode));
    FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(disabledAnalyticsEvents: <FluentBarAnalyticsEvent>{}));
    expect(FluentBar.currentConfig, const FluentBarConfig());

    await cleanup(tester);
  });

  testWidgets('relocated is reported when a bar moves to another region', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> free = FluentBar.info<void>('Free').withId('free').persistent().show()!;
    await settle(tester);

    free.controller.updateBehavior(behavior: free.currentItem.behavior.copyWith(position: FluentBarPosition.bottom));
    await settle(tester);
    expect(eventsOf('free'), <String>['requested', 'shown', 'relocated']);

    final FluentBarEntry<void> pushy = FluentBar.info<void>('Pushy').withId('pushy').persistent().withRelocationStrategy(FluentBarRelocationStrategy.forceReplace).show()!;
    await settle(tester);
    pushy.controller.updateBehavior(behavior: pushy.currentItem.behavior.copyWith(position: FluentBarPosition.bottom));
    await settle(tester);
    expect(eventsOf('pushy'), <String>['requested', 'shown', 'relocated']);
    expect(eventsOf('free').last, 'dismissed');

    final FluentBarEntry<void> patient = FluentBar.info<void>('Patient').withId('patient').persistent().show()!;
    await settle(tester);
    patient.controller.updateBehavior(behavior: patient.currentItem.behavior.copyWith(position: FluentBarPosition.bottom));
    await settle(tester);
    expect(eventsOf('patient'), <String>['requested', 'shown', 'relocated']);
    expect(FluentBar.bottomQueue.single, same(patient));

    await cleanup(tester);
  });
}
