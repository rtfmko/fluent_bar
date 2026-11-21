import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  final List<FluentBarAnalyticsPayload> analytics = <FluentBarAnalyticsPayload>[];
  final Map<String, List<FluentBarDismissReason>> ends = <String, List<FluentBarDismissReason>>{};
  void onAnalytics(FluentBarAnalyticsPayload payload) => analytics.add(payload);

  setUp(() {
    analytics.clear();
    ends.clear();
    FluentBar.addAnalyticsListener(onAnalytics);
  });

  tearDown(() => FluentBar.removeAnalyticsListener(onAnalytics));

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero)}) async {
    manager.resetForTesting();
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    analytics.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarItem<void> bar(String id) => FluentBar.info<void>(id, id: id).persistent().onDismiss((FluentBarItem<void> item, FluentBarMetrics metrics) {
    ends.putIfAbsent(item.id!, () => <FluentBarDismissReason>[]).add(metrics.dismissReason);
  });

  List<FluentBarDismissReason?> dismissedEvents(String id) =>
      analytics.where((FluentBarAnalyticsPayload p) => p.item.id == id && p.event == FluentBarAnalyticsEvent.dismissed).map((FluentBarAnalyticsPayload p) => p.metrics?.dismissReason).toList();

  List<String?> waitingIds() => FluentBar.allQueue.map((FluentBarEntry<dynamic> e) => e.item.id).toList();

  group('a waiting bar removed from the queue gets onDismiss once', () {
    testWidgets('on close by id', (WidgetTester tester) async {
      await boot(tester);
      bar('front').show();
      bar('waiting').show();
      await settle(tester);

      FluentBar.close('waiting');
      await settle(tester);

      expect(ends['waiting'], <FluentBarDismissReason>[FluentBarDismissReason.manual]);
      expect(dismissedEvents('waiting'), <FluentBarDismissReason>[FluentBarDismissReason.manual]);
      expect(ends['front'], isNull);
      await cleanup(tester);
    });

    testWidgets('on closeAll', (WidgetTester tester) async {
      await boot(tester);
      bar('t0').show();
      bar('t1').show();
      bar('b0').atBottom().show();
      bar('b1').atBottom().show();
      await settle(tester);

      unawaited(FluentBar.closeAll());
      await settle(tester);

      for (final String id in <String>['t0', 't1', 'b0', 'b1']) {
        expect(ends[id], <FluentBarDismissReason>[FluentBarDismissReason.manual], reason: id);
        expect(dismissedEvents(id), hasLength(1), reason: id);
      }
      await cleanup(tester);
    });

    testWidgets('on closeTag', (WidgetTester tester) async {
      await boot(tester);
      bar('a').withTag('t').show();
      bar('b').withTag('t').show();
      bar('c').show();
      await settle(tester);

      FluentBar.closeTag('t');
      await settle(tester);

      expect(ends['a'], <FluentBarDismissReason>[FluentBarDismissReason.manual]);
      expect(ends['b'], <FluentBarDismissReason>[FluentBarDismissReason.manual]);
      expect(ends['c'], isNull);
      expect(FluentBar.mainActiveItem?.item.id, 'c');
      await cleanup(tester);
    });

    testWidgets('on clearQueue', (WidgetTester tester) async {
      await boot(tester);
      bar('front').show();
      bar('a').show();
      bar('b').atBottom().show();
      bar('c').atBottom().show();
      await settle(tester);

      FluentBar.clearQueue();
      await settle(tester);

      expect(ends['a'], <FluentBarDismissReason>[FluentBarDismissReason.manual]);
      expect(ends['c'], <FluentBarDismissReason>[FluentBarDismissReason.manual]);
      expect(ends['front'], isNull);
      expect(ends['b'], isNull);
      await cleanup(tester);
    });

    testWidgets('on dismissAndClear', (WidgetTester tester) async {
      await boot(tester);
      bar('t0').show();
      bar('t1').show();
      bar('b0').atBottom().show();
      bar('b1').atBottom().show();
      await settle(tester);

      FluentBar.dismissAndClear();
      await settle(tester);

      for (final String id in <String>['t0', 't1', 'b0', 'b1']) {
        expect(ends[id], <FluentBarDismissReason>[FluentBarDismissReason.manual], reason: id);
      }
      await cleanup(tester);
    });

    testWidgets('when the owner of its tag leaves the tree', (WidgetTester tester) async {
      manager.resetForTesting();
      Widget app(Widget home) => MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: Scaffold(body: home),
      );
      await tester.pumpWidget(app(const FluentBarOwner(tag: 'checkout', child: Text('Checkout'))));
      await tester.pump();
      bar('a').withTag('checkout').show();
      bar('b').withTag('checkout').show();
      await settle(tester);

      await tester.pumpWidget(app(const Text('Another screen')));
      await settle(tester);

      expect(ends['a'], hasLength(1));
      expect(ends['b'], hasLength(1));
      await cleanup(tester);
    });
  });

  testWidgets('a waiting bar that gives way to a forced bar ends once with dropped', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, maxQueueLength: 1));
    bar('f0').forced().show();
    bar('r1').show();
    await settle(tester);

    bar('f2').forced().show();
    await settle(tester);

    expect(waitingIds(), <String>['f2']);
    expect(ends['r1'], <FluentBarDismissReason>[FluentBarDismissReason.dropped]);
    expect(dismissedEvents('r1'), <FluentBarDismissReason>[FluentBarDismissReason.dropped]);
    expect(analytics.where((FluentBarAnalyticsPayload p) => p.item.id == 'r1' && p.event == FluentBarAnalyticsEvent.queueOverflow), hasLength(1));
    await cleanup(tester);
  });

  group('the reason of a close call reaches waiting bars', () {
    testWidgets('closeAll', (WidgetTester tester) async {
      await boot(tester);
      bar('front').show();
      bar('waiting').show();
      await settle(tester);

      unawaited(FluentBar.closeAll(reason: FluentBarDismissReason.timeout));
      await settle(tester);

      expect(ends['front'], <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      expect(ends['waiting'], <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      expect(dismissedEvents('waiting'), <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      await cleanup(tester);
    });

    testWidgets('close by id', (WidgetTester tester) async {
      await boot(tester);
      bar('front').show();
      bar('waiting').show();
      await settle(tester);

      FluentBar.close('waiting', reason: FluentBarDismissReason.timeout);
      await settle(tester);

      expect(ends['waiting'], <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      expect(dismissedEvents('waiting'), <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      await cleanup(tester);
    });

    testWidgets('closeTag', (WidgetTester tester) async {
      await boot(tester);
      bar('front').show();
      bar('waiting').withTag('t').show();
      await settle(tester);

      FluentBar.closeTag('t', reason: FluentBarDismissReason.timeout);
      await settle(tester);

      expect(ends['waiting'], <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      expect(dismissedEvents('waiting'), <FluentBarDismissReason>[FluentBarDismissReason.timeout]);
      await cleanup(tester);
    });
  });

  testWidgets('forcing a bar with the id of a live bar leaves the id once on screen and in the queues', (WidgetTester tester) async {
    await boot(tester);
    FluentBar.info<void>('a', id: 'x').persistent().show();
    final FluentBarEntry<void>? y = FluentBar.info<void>('b', id: 'y').persistent().show();
    await settle(tester);

    final FluentBarEntry<void> c = FluentBar.info<void>('c', id: 'y').persistent().force()!;
    await settle(tester);
    final FluentBarEntry<void> d = FluentBar.info<void>('d', id: 'y').persistent().force()!;
    await settle(tester);

    final List<String?> ids = <String?>[...FluentBar.activeItems.map((FluentBarEntry<dynamic> e) => e.item.id), ...waitingIds()];
    expect(ids.where((String? id) => id == 'y'), hasLength(1));
    expect(c, same(y));
    expect(d, same(y));
    expect(FluentBar.mainActiveItem, same(y));
    expect(y!.item.message, 'd');
    await cleanup(tester);
  });

  group('an ignored duplicate of a waiting bar does not change its priority', () {
    for (final bool progress in <bool>[false, true]) {
      testWidgets(progress ? 'with progress: only the progress gets through' : 'without progress', (WidgetTester tester) async {
        await boot(tester);
        FluentBar.info<void>('front', id: 'front').persistent().show();
        FluentBarItem<void> waiting = FluentBar.info<void>('waiting', id: 'w').persistent();
        if (progress) waiting = waiting.withProgress(const FluentBarProgressState.value(0.1));
        final FluentBarEntry<void>? entry = waiting.show();
        FluentBar.info<void>('high', id: 'h').persistent().withPriority(FluentBarPriority.high).show();
        await settle(tester);
        expect(waitingIds(), <String>['h', 'w']);

        FluentBarItem<void> again = FluentBar.info<void>('again', id: 'w').persistent().withPriority(FluentBarPriority.critical).withDuplicatePolicy(FluentBarDuplicatePolicy.ignore);
        if (progress) again = again.withProgress(const FluentBarProgressState.value(0.2));
        again.show();
        await settle(tester);

        expect(waitingIds(), <String>['h', 'w']);
        expect(entry!.item.behavior.priority, isNot(FluentBarPriority.critical));
        if (progress) expect(entry.item.progressState, const FluentBarProgressState.value(0.2));
        await cleanup(tester);
      });
    }
  });
}
