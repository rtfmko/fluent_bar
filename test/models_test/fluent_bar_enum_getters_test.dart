import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FluentBarLifecycleState queued = FluentBarLifecycleState.queued;
  const FluentBarLifecycleState showing = FluentBarLifecycleState.showing;
  const FluentBarLifecycleState visible = FluentBarLifecycleState.visible;
  const FluentBarLifecycleState hiding = FluentBarLifecycleState.hiding;
  const FluentBarLifecycleState dismissed = FluentBarLifecycleState.dismissed;

  Set<T> where<T>(Iterable<T> values, bool Function(T value) test) => values.where(test).toSet();

  group('FluentBarLifecycleState', () {
    const List<FluentBarLifecycleState> all = FluentBarLifecycleState.values;

    test('each getter names its exact set of states', () {
      expect(where(all, (FluentBarLifecycleState s) => s.isQueued), <FluentBarLifecycleState>{queued});
      expect(where(all, (FluentBarLifecycleState s) => s.isShowing), <FluentBarLifecycleState>{showing});
      expect(where(all, (FluentBarLifecycleState s) => s.isVisible), <FluentBarLifecycleState>{visible});
      expect(where(all, (FluentBarLifecycleState s) => s.isHiding), <FluentBarLifecycleState>{hiding});
      expect(where(all, (FluentBarLifecycleState s) => s.isOnScreen), <FluentBarLifecycleState>{showing, visible, hiding});
      expect(where(all, (FluentBarLifecycleState s) => s.isInteractive), <FluentBarLifecycleState>{showing, visible});
      expect(where(all, (FluentBarLifecycleState s) => s.isAnimating), <FluentBarLifecycleState>{showing, hiding});
      expect(where(all, (FluentBarLifecycleState s) => s.isFinished), <FluentBarLifecycleState>{hiding, dismissed});
      expect(where(all, (FluentBarLifecycleState s) => s.isDismissed), <FluentBarLifecycleState>{dismissed});
    });

    test('a state is queued, on screen or dismissed, and never two of them', () {
      for (final FluentBarLifecycleState state in all) {
        expect(<bool>[state.isQueued, state.isOnScreen, state.isDismissed].where((bool v) => v), hasLength(1), reason: state.name);
      }
    });
  });

  group('FluentBarAnalyticsEvent', () {
    const List<FluentBarAnalyticsEvent> all = FluentBarAnalyticsEvent.values;

    test('each getter names its exact set of events', () {
      expect(where(all, (FluentBarAnalyticsEvent e) => e.isLifecycle), <FluentBarAnalyticsEvent>{
        FluentBarAnalyticsEvent.requested,
        FluentBarAnalyticsEvent.queued,
        FluentBarAnalyticsEvent.shown,
        FluentBarAnalyticsEvent.dismissed,
      });
      expect(where(all, (FluentBarAnalyticsEvent e) => e.isInteraction), <FluentBarAnalyticsEvent>{FluentBarAnalyticsEvent.tapped, FluentBarAnalyticsEvent.actionTapped});
      expect(where(all, (FluentBarAnalyticsEvent e) => e.isProgress), <FluentBarAnalyticsEvent>{
        FluentBarAnalyticsEvent.progressCompleted,
        FluentBarAnalyticsEvent.progressFailed,
        FluentBarAnalyticsEvent.progressCanceled,
      });
      expect(where(all, (FluentBarAnalyticsEvent e) => e.isRejected), <FluentBarAnalyticsEvent>{FluentBarAnalyticsEvent.ignoredDuplicate, FluentBarAnalyticsEvent.queueOverflow});
      expect(where(all, (FluentBarAnalyticsEvent e) => e.isCountdown), <FluentBarAnalyticsEvent>{FluentBarAnalyticsEvent.paused, FluentBarAnalyticsEvent.resumed});
      expect(where(all, (FluentBarAnalyticsEvent e) => e.hasMetrics), <FluentBarAnalyticsEvent>{FluentBarAnalyticsEvent.dismissed, FluentBarAnalyticsEvent.queueOverflow});
    });

    test('the groups do not overlap', () {
      for (final FluentBarAnalyticsEvent event in all) {
        final int groups = <bool>[event.isLifecycle, event.isInteraction, event.isProgress, event.isRejected, event.isCountdown].where((bool v) => v).length;
        expect(groups, lessThanOrEqualTo(1), reason: event.name);
      }
    });
  });

  group('FluentBarDismissReason', () {
    const List<FluentBarDismissReason> all = FluentBarDismissReason.values;

    test('each getter names its exact set of reasons', () {
      expect(where(all, (FluentBarDismissReason r) => r.isByUser), <FluentBarDismissReason>{
        FluentBarDismissReason.swipe,
        FluentBarDismissReason.tap,
        FluentBarDismissReason.actionButton,
        FluentBarDismissReason.closeButton,
        FluentBarDismissReason.accessibility,
      });
      expect(where(all, (FluentBarDismissReason r) => r.isByCode), <FluentBarDismissReason>{FluentBarDismissReason.manual, FluentBarDismissReason.force});
      expect(where(all, (FluentBarDismissReason r) => r.isAutomatic), <FluentBarDismissReason>{FluentBarDismissReason.timeout, FluentBarDismissReason.dropped});
    });

    test('every reason has exactly one author', () {
      for (final FluentBarDismissReason reason in all) {
        expect(<bool>[reason.isByUser, reason.isByCode, reason.isAutomatic].where((bool v) => v), hasLength(1), reason: reason.name);
      }
    });
  });

  group('FluentBarErrorSeverity', () {
    test('each severity answers its own getter', () {
      expect(FluentBarErrorSeverity.warning.isWarning, isTrue);
      expect(FluentBarErrorSeverity.warning.isError, isFalse);
      expect(FluentBarErrorSeverity.error.isError, isTrue);
      expect(FluentBarErrorSeverity.error.isWarning, isFalse);
    });
  });

  group('with real bars', () {
    testWidgets('a tap, a close call and a timeout are told apart by the reason', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final Map<String?, FluentBarDismissReason> reasons = <String?, FluentBarDismissReason>{};
      void record(FluentBarAnalyticsPayload payload) {
        if (payload.event.hasMetrics) reasons[payload.item.id] = payload.metrics!.dismissReason;
      }

      FluentBar.addAnalyticsListener(record);
      addTearDown(() => FluentBar.removeAnalyticsListener(record));

      FluentBar.info<void>('Tap me').withId('tapped').persistent().show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      FluentBar.info<void>('Closed from code').withId('closed').persistent().show();
      await tester.pump();
      FluentBar.close('closed');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      FluentBar.info<void>('Short').withId('timed').withDuration(const Duration(seconds: 1)).show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      expect(reasons['tapped']!.isByUser, isTrue);
      expect(reasons['closed']!.isByCode, isTrue);
      expect(reasons['timed']!.isAutomatic, isTrue);

      FluentBar.dismissAndClear();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('hasMetrics tells exactly which events carry metrics', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, maxQueueLength: 1)),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final List<FluentBarAnalyticsPayload> payloads = <FluentBarAnalyticsPayload>[];
      FluentBar.addAnalyticsListener(payloads.add);
      addTearDown(() => FluentBar.removeAnalyticsListener(payloads.add));

      FluentBar.info<void>('One').persistent().show();
      FluentBar.info<void>('Two').persistent().show();
      FluentBar.info<void>('Three').persistent().show();
      await tester.pump();
      FluentBar.dismissAndClear();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(payloads.where((FluentBarAnalyticsPayload p) => p.event == FluentBarAnalyticsEvent.dismissed), isNotEmpty);
      expect(payloads.where((FluentBarAnalyticsPayload p) => p.event == FluentBarAnalyticsEvent.queueOverflow), isNotEmpty);
      for (final FluentBarAnalyticsPayload payload in payloads) {
        expect(payload.metrics != null, payload.event.hasMetrics, reason: payload.event.name);
      }
    });

    testWidgets('the state getters follow a bar from the queue to the end', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(config: const FluentBarConfig()),
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final FluentBarEntry<void> first = FluentBar.info<void>('First').persistent().show()!;
      final FluentBarEntry<void> second = FluentBar.info<void>('Second').persistent().show()!;
      FluentBarLifecycleState of(FluentBarEntry<void> entry) => entry.controller.stateNotifier.value;

      await tester.pump();
      expect(of(second).isQueued, isTrue);
      expect(of(first).isInteractive, isTrue);
      expect(of(first).isAnimating, isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(of(first), FluentBarLifecycleState.visible);
      expect(of(first).isAnimating, isFalse);

      first.close();
      await tester.pump();
      expect(of(first).isFinished, isTrue);
      expect(of(first).isOnScreen, isTrue);
      expect(of(first).isInteractive, isFalse);

      await tester.pump(const Duration(seconds: 1));
      expect(of(first).isDismissed, isTrue);
      expect(of(first).isOnScreen, isFalse);

      FluentBar.dismissAndClear();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
