import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DropRestOnDequeueStrategy extends FluentBarQueueStrategy {
  const _DropRestOnDequeueStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) =>
      QueueOperationResult(queue: <FluentBarEntry<dynamic>>[...queue, incoming]);

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) => (queue.first, <FluentBarEntry<dynamic>>[]);
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<String> ends = <String>[];

  setUp(ends.clear);

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero)}) async {
    manager.resetForTesting();
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
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarItem<void> bar(String id, {void Function()? onEnd}) => FluentBar.info<void>(id, id: id).persistent().onDismiss((FluentBarItem<void> item, FluentBarMetrics metrics) {
    ends.add(id);
    onEnd?.call();
  });

  void showLate({bool bottom = false}) {
    final FluentBarItem<void> late = bar('late');
    (bottom ? late.atBottom() : late).show();
  }

  List<String?> ids(List<FluentBarEntry<dynamic>> entries) => entries.map((FluentBarEntry<dynamic> e) => e.item.id).toList();

  group('a bar shown from onDismiss of a waiting bar survives the call that ended it', () {
    testWidgets('clearQueue', (WidgetTester tester) async {
      await boot(tester);
      bar('top').show();
      bar('waiting', onEnd: () => showLate(bottom: true)).show();
      bar('bottom').atBottom().show();
      await settle(tester);

      FluentBar.clearQueue();
      await settle(tester);

      expect(ids(FluentBar.bottomQueue), <String>['late']);
      expect(ends, <String>['waiting']);
      await cleanup(tester);
    });

    testWidgets('closeAll', (WidgetTester tester) async {
      await boot(tester);
      bar('top').show();
      bar('waiting', onEnd: () => showLate(bottom: true)).show();
      await settle(tester);

      await FluentBar.closeAll(skipAnimation: true);
      await settle(tester);

      expect(FluentBar.bottomActiveItem?.item.id, 'late');
      expect(ends, isNot(contains('late')));
      await cleanup(tester);
    });

    testWidgets('a forced bar that pushes it out', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, maxQueueLength: 1));
      bar('f0').forced().show();
      bar('r1', onEnd: showLate).show();
      await settle(tester);

      bar('f2').forced().show();
      await settle(tester);

      expect(FluentBar.mainActiveItem?.item.id, 'f0');
      expect(ids(FluentBar.mainQueue), contains('f2'));
      FluentBar.close('f0');
      await settle(tester);
      expect(FluentBar.mainActiveItem?.item.id, 'f2');
      await cleanup(tester);
    });

    testWidgets('a strategy that drops it while the next bar is taken', (WidgetTester tester) async {
      await boot(
        tester,
        config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, defaultQueueStrategy: _DropRestOnDequeueStrategy()),
      );
      bar('front').show();
      bar('a').show();
      bar('b', onEnd: showLate).show();
      await settle(tester);

      FluentBar.close('front');
      await settle(tester);

      expect(FluentBar.mainActiveItem?.item.id, 'a');
      expect(ids(FluentBar.mainQueue), <String>['late']);
      expect(find.text('late'), findsNothing);
      await cleanup(tester);
    });

    testWidgets('a bar moved into its full queue', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, maxQueueLength: 1));
      final FluentBarEntry<void> moved = bar('moved').withRelocationStrategy(FluentBarRelocationStrategy.queueNext).show()!;
      bar('bottom').atBottom().show();
      bar('waiting', onEnd: () => showLate(bottom: true)).atBottom().show();
      await settle(tester);

      moved.controller.updateBehavior(behavior: moved.currentItem.behavior.copyWith(position: FluentBarPosition.bottom));
      await settle(tester);

      expect(ends, contains('waiting'));
      expect(ids(FluentBar.bottomQueue), contains('moved'));
      await cleanup(tester);
    });
  });

  group('force with the ignore duplicate policy still shows the waiting bar', () {
    Future<void> expectForced(WidgetTester tester, FluentBarItem<void> again, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero)}) async {
      await boot(tester, config: config);
      bar('front').show();
      final FluentBarEntry<void>? waiting = bar('w').show();
      await settle(tester);

      final FluentBarEntry<void> forced = again.force()!;
      await settle(tester);

      expect(forced, same(waiting));
      expect(FluentBar.mainActiveItem, same(waiting));
      await cleanup(tester);
    }

    testWidgets('from the bar', (WidgetTester tester) async {
      await expectForced(tester, FluentBar.info<void>('again', id: 'w').persistent().withDuplicatePolicy(FluentBarDuplicatePolicy.ignore));
    });

    testWidgets('from its type', (WidgetTester tester) async {
      await expectForced(tester, FluentBar.custom<void>(FluentBarType.info.copyWith(duplicatePolicy: FluentBarDuplicatePolicy.ignore), 'again', id: 'w').persistent());
    });

    testWidgets('from the config', (WidgetTester tester) async {
      await expectForced(
        tester,
        FluentBar.info<void>('again', id: 'w').persistent(),
        config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, defaultDuplicatePolicy: FluentBarDuplicatePolicy.ignore),
      );
    });
  });
}
