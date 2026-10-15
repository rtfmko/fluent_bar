import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarException> errors = <FluentBarException>[];
  final List<String> dismissed = <String>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    errors.clear();
    dismissed.clear();
    FluentBar.addErrorHandler(onError);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
  });

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero)}) async {
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
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarEntry<void> show(String message, {bool bottom = false, FluentBarRelocationStrategy? strategy, Duration? duration}) => FluentBar.show<void>(
    message: message,
    id: message,
    duration: duration,
    isPersistent: duration == null,
    options: FluentBarOptions<void>(
      behavior: FluentBarBehavior(position: bottom ? FluentBarPosition.bottom : FluentBarPosition.top, relocationStrategy: strategy),
      callbacks: FluentBarCallbacks<void>(onDismiss: (FluentBarItem<void> item, FluentBarMetrics metrics) => dismissed.add('${item.message}:${metrics.dismissReason.name}')),
    ),
  )!;

  void moveTo(FluentBarEntry<void> entry, FluentBarPosition position) => entry.controller.updateBehavior(behavior: entry.currentItem.behavior.copyWith(position: position));

  bool isAtBottom(WidgetTester tester, String message) => tester.getCenter(find.text(message)).dy > 300;

  testWidgets('moving to a free region takes its slot and frees the old one', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> moved = show('Moved');
    show('Next top');
    await settle(tester);
    expect(FluentBar.mainQueueLength, 1);

    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);

    expect(FluentBar.bottomActiveItem, same(moved));
    expect(FluentBar.mainActiveItem?.currentItem.message, 'Next top');
    expect(FluentBar.mainQueueLength, 0);
    expect(isAtBottom(tester, 'Moved'), isTrue);
    expect(isAtBottom(tester, 'Next top'), isFalse);
    expect(dismissed, isEmpty);

    moved.controller.close();
    await settle(tester);
    expect(FluentBar.bottomActiveItem, isNull);
    expect(dismissed, <String>['Moved:manual']);
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  testWidgets('ignore: the target region is busy, so the bar stays where it was', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> moved = show('Moved', strategy: FluentBarRelocationStrategy.ignore);
    final FluentBarEntry<void> snack = show('Snack', bottom: true);
    await settle(tester);

    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);

    expect(FluentBar.mainActiveItem, same(moved));
    expect(FluentBar.bottomActiveItem, same(snack));
    expect(moved.resolvePosition(manager.config), FluentBarPosition.top);
    expect(isAtBottom(tester, 'Moved'), isFalse);
    expect(dismissed, isEmpty);

    snack.controller.close();
    await settle(tester);
    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);
    expect(FluentBar.bottomActiveItem, same(moved));
    expect(isAtBottom(tester, 'Moved'), isTrue);
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  testWidgets('forceReplace: the bar in the target region is dismissed and replaced', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> moved = show('Moved', strategy: FluentBarRelocationStrategy.forceReplace);
    final FluentBarEntry<void> snack = show('Snack', bottom: true);
    show('Next top');
    show('Next bottom', bottom: true);
    await settle(tester);

    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);

    expect(FluentBar.bottomActiveItem, same(moved));
    expect(FluentBar.mainActiveItem?.currentItem.message, 'Next top');
    expect(dismissed, <String>['Snack:force']);
    expect(snack.internalController.isDisposed, isTrue);
    expect(find.text('Snack'), findsNothing);
    expect(isAtBottom(tester, 'Moved'), isTrue);
    expect(FluentBar.bottomQueue.single.currentItem.message, 'Next bottom');
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  testWidgets('queueNext: the bar hides and waits first in the queue of the target region', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> moved = show('Moved', duration: const Duration(seconds: 10));
    final FluentBarEntry<void> snack = show('Snack', bottom: true);
    show('Next top');
    show('Next bottom', bottom: true);
    await settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(moved.controller.remainingDurationNotifier.value, lessThan(const Duration(seconds: 7)));

    moveTo(moved, FluentBarPosition.bottom);
    await tester.pump();
    expect(isAtBottom(tester, 'Moved'), isFalse);
    await settle(tester);

    expect(find.text('Moved'), findsNothing);
    expect(moved.internalController.isDisposed, isFalse);
    expect(moved.controller.stateNotifier.value, FluentBarLifecycleState.queued);
    expect(FluentBar.bottomQueue.map((FluentBarEntry<dynamic> e) => e.currentItem.message), <String>['Moved', 'Next bottom']);
    expect(FluentBar.mainActiveItem?.currentItem.message, 'Next top');
    expect(FluentBar.bottomActiveItem, same(snack));
    expect(dismissed, isEmpty);

    snack.controller.close();
    await settle(tester);
    expect(FluentBar.bottomActiveItem, same(moved));
    expect(isAtBottom(tester, 'Moved'), isTrue);
    expect(moved.controller.stateNotifier.value, FluentBarLifecycleState.visible);
    expect(moved.controller.remainingDurationNotifier.value, greaterThan(const Duration(seconds: 8)));

    moved.controller.close();
    await settle(tester);
    expect(dismissed, <String>['Snack:manual', 'Moved:manual']);
    expect(FluentBar.bottomActiveItem?.currentItem.message, 'Next bottom');
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  for (final FluentBarRelocationStrategy strategy in FluentBarRelocationStrategy.values) {
    testWidgets('bottom to a busy top with ${strategy.name}', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> moved = show('Moved', bottom: true, strategy: strategy);
      final FluentBarEntry<void> occupant = show('Occupant');
      show('Next bottom', bottom: true);
      await settle(tester);

      moveTo(moved, FluentBarPosition.top);
      await settle(tester);

      switch (strategy) {
        case FluentBarRelocationStrategy.ignore:
          expect(FluentBar.bottomActiveItem, same(moved));
          expect(FluentBar.mainActiveItem, same(occupant));
          expect(isAtBottom(tester, 'Moved'), isTrue);
          expect(dismissed, isEmpty);

        case FluentBarRelocationStrategy.forceReplace:
          expect(FluentBar.mainActiveItem, same(moved));
          expect(isAtBottom(tester, 'Moved'), isFalse);
          expect(find.text('Occupant'), findsNothing);
          expect(dismissed, <String>['Occupant:force']);
          expect(FluentBar.bottomActiveItem?.currentItem.message, 'Next bottom');

        case FluentBarRelocationStrategy.queueNext:
          expect(find.text('Moved'), findsNothing);
          expect(FluentBar.mainActiveItem, same(occupant));
          expect(FluentBar.mainQueue.single, same(moved));
          expect(FluentBar.bottomActiveItem?.currentItem.message, 'Next bottom');
          expect(dismissed, isEmpty);

          occupant.controller.close();
          await settle(tester);
          expect(FluentBar.mainActiveItem, same(moved));
          expect(isAtBottom(tester, 'Moved'), isFalse);
      }
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  }

  testWidgets('queueNext: a bar closed for real while it was leaving is not re-queued', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> moved = show('Moved');
    show('Snack', bottom: true);
    await settle(tester);

    moveTo(moved, FluentBarPosition.bottom);
    await tester.pump();
    FluentBar.dismissAndClear();
    await settle(tester);

    expect(FluentBar.activeItems, isEmpty);
    expect(FluentBar.allQueueLength, 0);
    expect(moved.internalController.isDisposed, isTrue);
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  testWidgets('queueNext: forced bars keep their place ahead, and the queue limit still holds', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(maxQueueLength: 2));
    final FluentBarEntry<void> moved = show('Moved');
    FluentBar.info<void>('Forced active').withId('fa').persistent().atBottom().forced().show();
    FluentBar.info<void>('Forced queued').withId('fq').persistent().atBottom().forced().show();
    show('Last bottom', bottom: true);
    await settle(tester);
    expect(FluentBar.bottomQueue.map((FluentBarEntry<dynamic> e) => e.currentItem.message), <String>['Forced queued', 'Last bottom']);

    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);

    expect(FluentBar.bottomQueue.map((FluentBarEntry<dynamic> e) => e.currentItem.message), <String>['Forced queued', 'Moved']);
    expect(FluentBar.find('Last bottom'), isNull);
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  testWidgets('clearQueue drops only waiting bars', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> active = show('Active');
    final FluentBarEntry<void> queued = show('Queued');
    await settle(tester);

    FluentBar.clearQueue();
    await settle(tester);

    expect(FluentBar.allQueueLength, 0);
    expect(queued.internalController.isDisposed, isTrue);
    expect(FluentBar.mainActiveItem, same(active));
    expect(find.text('Active'), findsOneWidget);
    expect(dismissed, isEmpty);

    await cleanup(tester);
  });

  testWidgets('the strategy falls back to the config default', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(defaultRelocationStrategy: FluentBarRelocationStrategy.ignore));
    final FluentBarEntry<void> moved = show('Moved');
    show('Snack', bottom: true);
    await settle(tester);

    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);

    expect(FluentBar.mainActiveItem, same(moved));
    expect(isAtBottom(tester, 'Moved'), isFalse);

    await cleanup(tester);
  });

  testWidgets('a queued bar that changes position moves to the queue of its new region', (WidgetTester tester) async {
    await boot(tester);
    show('Top');
    final FluentBarEntry<void> queued = show('Queued');
    await settle(tester);
    expect(FluentBar.mainQueueLength, 1);

    moveTo(queued, FluentBarPosition.bottom);
    await settle(tester);
    expect(FluentBar.mainQueueLength, 0);
    expect(FluentBar.bottomActiveItem, same(queued));
    expect(isAtBottom(tester, 'Queued'), isTrue);

    final FluentBarEntry<void> second = show('Second');
    await settle(tester);
    moveTo(second, FluentBarPosition.bottom);
    expect(FluentBar.mainQueueLength, 0);
    expect(FluentBar.bottomQueue.single, same(second));
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  testWidgets('single queue mode: the bar just moves on screen, the slot is shared', (WidgetTester tester) async {
    await boot(tester, config: const FluentBarConfig(enableMultiRegion: false));
    final FluentBarEntry<void> moved = show('Moved');
    show('Queued', bottom: true);
    await settle(tester);

    moveTo(moved, FluentBarPosition.bottom);
    await settle(tester);

    expect(FluentBar.mainActiveItem, same(moved));
    expect(FluentBar.bottomActiveItem, isNull);
    expect(FluentBar.mainQueueLength, 1);
    expect(isAtBottom(tester, 'Moved'), isTrue);
    expect(errors, isEmpty);

    await cleanup(tester);
  });
}
