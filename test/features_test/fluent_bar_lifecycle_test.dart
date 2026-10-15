import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarAnalyticsPayload> events = <FluentBarAnalyticsPayload>[];

  void onEvent(FluentBarAnalyticsPayload payload) => events.add(payload);

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    events.clear();
  });

  tearDown(() => FluentBarControllerImpl.stopwatchFactory = Stopwatch.new);

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig()}) async {
    manager.resetForTesting();
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

  Future<void> advance(WidgetTester tester, int milliseconds) async {
    for (int passed = 0; passed < milliseconds; passed += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  List<FluentBarLifecycleState> record(FluentBarEntry<void> entry) {
    final List<FluentBarLifecycleState> states = <FluentBarLifecycleState>[entry.controller.stateNotifier.value];
    entry.controller.stateNotifier.addListener(() => states.add(entry.controller.stateNotifier.value));
    return states;
  }

  FluentBarMetrics metricsOfDismissed() => events.lastWhere((FluentBarAnalyticsPayload e) => e.event == FluentBarAnalyticsEvent.dismissed).metrics!;

  FluentBarLifecycleState stateOf(FluentBarEntry<void> entry) => entry.controller.stateNotifier.value;

  Duration remaining(FluentBarEntry<void> entry) => entry.controller.remainingDurationNotifier.value;

  testWidgets('a bar is showing while it moves in and visible when it is in place', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withDuration(const Duration(seconds: 5)).show()!;
    final List<FluentBarLifecycleState> states = record(entry);

    expect(stateOf(entry), FluentBarLifecycleState.showing);

    await advance(tester, 200);
    expect(stateOf(entry), FluentBarLifecycleState.showing, reason: 'the 300 ms entrance is still playing');

    await advance(tester, 250);
    expect(stateOf(entry), FluentBarLifecycleState.visible);
    expect(states, <FluentBarLifecycleState>[FluentBarLifecycleState.showing, FluentBarLifecycleState.visible]);

    await cleanup(tester);
  });

  testWidgets('visible comes from the animation, not from the fallback timer', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().show()!;

    await advance(tester, 400);
    expect(stateOf(entry), FluentBarLifecycleState.visible);
    expect((entry.controller as FluentBarControllerImpl<void>).showingDuration, lessThan(const Duration(milliseconds: 300) + FluentBarControllerImpl.entranceFallbackDelay));

    await cleanup(tester);
  });

  testWidgets('without an entrance animation showing and visible come together', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withoutAnimations().show()!;

    expect(stateOf(entry), FluentBarLifecycleState.visible, reason: 'visible before show() returns');

    await cleanup(tester);
  });

  testWidgets('the countdown starts at visible, not while the bar is appearing', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration(seconds: 2)));
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withDuration(const Duration(seconds: 1)).show()!;

    await advance(tester, 1500);
    expect(stateOf(entry), FluentBarLifecycleState.showing);
    expect(remaining(entry), const Duration(seconds: 1), reason: 'a 1 s bar with a 2 s entrance must not leave half way');
    expect(FluentBar.activeItems, contains(entry));

    await advance(tester, 700);
    expect(stateOf(entry), FluentBarLifecycleState.visible);
    expect(remaining(entry), greaterThan(const Duration(milliseconds: 700)));
    expect(FluentBar.activeItems, contains(entry));

    await advance(tester, 1200);
    await tester.pump(const Duration(seconds: 3));
    expect(FluentBar.activeItems, isEmpty);

    await cleanup(tester);
  });

  testWidgets('time added or taken while the bar is appearing is kept', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration(seconds: 1)));
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withDuration(const Duration(seconds: 4)).show()!;

    await advance(tester, 500);
    expect(stateOf(entry), FluentBarLifecycleState.showing);

    entry.controller.addDuration(const Duration(seconds: 5));
    expect(remaining(entry), const Duration(seconds: 9));

    entry.controller.subtractDuration(const Duration(seconds: 1));
    expect(remaining(entry), const Duration(seconds: 8));

    await advance(tester, 400);
    expect(stateOf(entry), FluentBarLifecycleState.showing);
    expect(remaining(entry), const Duration(seconds: 8), reason: 'nothing is spent during the entrance');

    await advance(tester, 300);
    expect(stateOf(entry), FluentBarLifecycleState.visible);
    expect(remaining(entry), greaterThan(const Duration(milliseconds: 7700)));

    await cleanup(tester);
  });

  testWidgets('a tap works while the bar is still appearing', (WidgetTester tester) async {
    await boot(
      tester,
      config: const FluentBarConfig(defaultTransitionDuration: Duration(seconds: 1), defaultEntranceAnimation: FluentBarEntranceAnimation.fade),
    );
    int taps = 0;
    final FluentBarEntry<void> entry = FluentBar.info<void>('Tap me').persistent().dismissOnTap(false).onTap((_) => taps++).show()!;

    await advance(tester, 300);
    expect(stateOf(entry), FluentBarLifecycleState.showing);

    await tester.tap(find.text('Tap me'));
    await tester.pump();
    expect(taps, 1);

    await cleanup(tester);
  });

  testWidgets('an effect requested during the entrance waits for visible', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration(seconds: 1)));
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().show()!;
    final List<FluentBarEffectEvent> played = <FluentBarEffectEvent>[];
    (entry.controller as FluentBarControllerImpl<void>).effectStream.listen(played.add);

    await advance(tester, 400);
    entry.shake();
    entry.pulse();
    await tester.pump();
    expect(played, isEmpty);

    await advance(tester, 800);
    expect(stateOf(entry), FluentBarLifecycleState.visible);
    expect(played.single.type, FluentBarEffect.pulse, reason: 'only the last requested effect plays');

    await cleanup(tester);
  });

  testWidgets('a bar closed while appearing goes showing, hiding, dismissed and says so in metrics', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration(seconds: 1)));
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withDuration(const Duration(seconds: 4)).show()!;
    final List<FluentBarLifecycleState> states = record(entry);

    await advance(tester, 400);
    entry.close();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(states, <FluentBarLifecycleState>[FluentBarLifecycleState.showing, FluentBarLifecycleState.hiding, FluentBarLifecycleState.dismissed]);

    final FluentBarMetrics metrics = metricsOfDismissed();
    expect(metrics.wasVisible, isFalse);
    expect(metrics.visibleDuration, Duration.zero);
    expect(metrics.showingDuration, const Duration(milliseconds: 400));
    expect(metrics.toMap()['was_visible'], isFalse);
    expect(metrics.toMap()['showing_ms'], 400);
    expect(events.map((FluentBarAnalyticsPayload e) => e.event), contains(FluentBarAnalyticsEvent.shown), reason: 'shown is reported when the bar appears');

    await cleanup(tester);
  });

  testWidgets('metrics of a bar that lived its time: visible, with the entrance counted apart', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('Message').withDuration(const Duration(seconds: 1)).show();

    await advance(tester, 1600);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    final FluentBarMetrics metrics = metricsOfDismissed();
    expect(metrics.wasVisible, isTrue);
    expect(metrics.dismissReason, FluentBarDismissReason.timeout);
    expect(metrics.showingDuration.inMilliseconds, inInclusiveRange(300, 450));

    await cleanup(tester);
  });

  testWidgets('visibleDuration counts only the time in place, apart from the entrance and the exit', (WidgetTester tester) async {
    await boot(
      tester,
      config: const FluentBarConfig(defaultTransitionDuration: Duration(seconds: 1), defaultReverseTransitionDuration: Duration(seconds: 1)),
    );
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().show()!;

    await advance(tester, 1200);
    expect(stateOf(entry), FluentBarLifecycleState.visible);

    await advance(tester, 2000);
    entry.close();
    await advance(tester, 1500);
    await tester.pump(const Duration(seconds: 2));

    final FluentBarMetrics metrics = metricsOfDismissed();
    expect(metrics.showingDuration.inMilliseconds, inInclusiveRange(1000, 1150));
    expect(metrics.visibleDuration.inMilliseconds, inInclusiveRange(2000, 2200));
    expect((metrics.showingDuration + metrics.visibleDuration).inMilliseconds, 3200, reason: 'the exit animation is counted in neither');

    await cleanup(tester);
  });

  testWidgets('a bar that waits in the other region goes back to queued and appears again', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> occupant = FluentBar.info<void>('Bottom').persistent().atBottom().show()!;
    final FluentBarEntry<void> entry = FluentBar.info<void>('Top').persistent().atTop().show()!;
    await advance(tester, 500);
    final List<FluentBarLifecycleState> states = record(entry);

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
    await advance(tester, 600);
    expect(stateOf(entry), FluentBarLifecycleState.queued);

    occupant.close();
    await advance(tester, 1200);

    expect(states, <FluentBarLifecycleState>[
      FluentBarLifecycleState.visible,
      FluentBarLifecycleState.hiding,
      FluentBarLifecycleState.queued,
      FluentBarLifecycleState.showing,
      FluentBarLifecycleState.visible,
    ]);

    await cleanup(tester);
  });

  testWidgets('the fallback moves a bar to visible when no widget reports the entrance', (WidgetTester tester) async {
    manager.resetForTesting();
    final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(FluentBar.info<void>('Message'));

    controller.changeState(FluentBarLifecycleState.showing);
    controller.startTimersOnShow(const Duration(seconds: 4), manager, entrance: const Duration(milliseconds: 300));
    expect(controller.stateNotifier.value, FluentBarLifecycleState.showing);

    await tester.pump(const Duration(milliseconds: 300) + FluentBarControllerImpl.entranceFallbackDelay);
    expect(controller.stateNotifier.value, FluentBarLifecycleState.visible);
    expect(controller.wasVisible, isTrue);

    controller.markEntranceCompleted();
    expect(controller.stateNotifier.value, FluentBarLifecycleState.visible);

    controller.dispose();
  });
}
