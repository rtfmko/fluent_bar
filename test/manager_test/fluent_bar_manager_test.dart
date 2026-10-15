import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowOnEnqueueStrategy extends SmartQueueStrategy {
  const _ThrowOnEnqueueStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) => throw Exception('enqueue failed');
}

class _ThrowOnDequeueStrategy extends FifoQueueStrategy {
  const _ThrowOnDequeueStrategy();

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) => throw Exception('dequeue failed');
}

class _AlwaysForceStrategy extends LifoQueueStrategy {
  const _AlwaysForceStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) =>
      QueueOperationResult(queue: <FluentBarEntry<dynamic>>[incoming, ...queue], shouldForce: true);
}

class _KeepLatestStrategy extends FifoQueueStrategy {
  const _KeepLatestStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) =>
      QueueOperationResult(queue: <FluentBarEntry<dynamic>>[incoming]);
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  final List<FluentBarException> errors = <FluentBarException>[];
  final List<FluentBarAnalyticsPayload> analytics = <FluentBarAnalyticsPayload>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
  void onAnalytics(FluentBarAnalyticsPayload payload) => analytics.add(payload);

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    errors.clear();
    analytics.clear();
    FluentBar.addErrorHandler(onError);
    FluentBar.addAnalyticsListener(onAnalytics);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBar.removeAnalyticsListener(onAnalytics);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
  });

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero)}) async {
    manager.resetForTesting();
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
    analytics.clear();
  }

  Future<void> shown(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  FluentBarEntry<void>? show(
    String message, {
    String? id,
    bool bottom = false,
    FluentBarPosition? position,
    FluentBarPriority? priority,
    bool isForce = false,
    FluentBarDuplicatePolicy? policy,
    FluentBarHapticType? haptic,
    Duration? duration,
    FluentBarType type = FluentBarType.info,
    FluentBarProgressState? progress,
    FluentBarCallbacks<void>? callbacks,
  }) => FluentBar.show<void>(
    message: message,
    id: id,
    type: type,
    duration: duration,
    isPersistent: duration == null ? true : null,
    options: FluentBarOptions<void>(
      behavior: FluentBarBehavior(position: position ?? (bottom ? FluentBarPosition.bottom : null), priority: priority, isForce: isForce, duplicatePolicy: policy, haptic: haptic),
      callbacks: callbacks,
      progressState: progress,
    ),
  );

  List<String> messages(List<FluentBarEntry<dynamic>> entries) => entries.map((FluentBarEntry<dynamic> e) => e.currentItem.message).toList();

  List<FluentBarAnalyticsEvent> eventsOf(String message) => analytics.where((FluentBarAnalyticsPayload p) => p.item.message == message).map((FluentBarAnalyticsPayload p) => p.event).toList();

  List<FluentBarErrorType> errorTypes() => errors.map((FluentBarException e) => e.type).toList();

  group('initialization and config', () {
    testWidgets('a second initialize is reported and does not replace the config', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(maxQueueLength: 7));
      expect(manager.isInitialized, isTrue);

      FluentBar.initialize(config: const FluentBarConfig(maxQueueLength: 3));

      expect(errorTypes(), <FluentBarErrorType>[FluentBarErrorType.initialization]);
      expect(FluentBar.currentConfig.maxQueueLength, 7);
    });

    testWidgets('updateConfig and patchConfig notify the config listenable', (WidgetTester tester) async {
      await boot(tester);
      final List<int> seen = <int>[];
      void listener() => seen.add(FluentBar.configNotifier.value.maxQueueLength);
      FluentBar.configNotifier.addListener(listener);
      addTearDown(() => FluentBar.configNotifier.removeListener(listener));

      FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 4));
      FluentBar.patchConfig((FluentBarConfig current) => current.copyWith(maxQueueLength: current.maxQueueLength + 1));

      expect(seen, <int>[4, 5]);
      expect(FluentBar.currentConfig.maxQueueLength, 5);
    });
  });

  group('overlay resolution', () {
    testWidgets('without any overlay the bar waits in the queue and is shown when the scope appears', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());

      final FluentBarEntry<void>? entry = show('Waiting');
      expect(entry, isNotNull);
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.mainQueueLength, 1);

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      expect(FluentBar.mainActiveItem, same(entry));
      expect(FluentBar.mainQueueLength, 0);
      expect(find.text('Waiting'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('falls back to the navigator overlay when there is no scope', (WidgetTester tester) async {
      manager.resetForTesting();
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      FluentBar.initialize(config: const FluentBarConfig(), navigatorKey: navigatorKey);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      show('Via navigator');
      await tester.pump();

      expect(find.text('Via navigator'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('an explicitly passed overlay wins over the scope overlay', (WidgetTester tester) async {
      await boot(tester);
      final GlobalKey<OverlayState> customOverlay = GlobalKey<OverlayState>();
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: Scaffold(body: Overlay(key: customOverlay)),
        ),
      );

      FluentBar.show<void>(message: 'Custom overlay', isPersistent: true, overlayState: customOverlay.currentState);
      await tester.pump();

      expect(find.descendant(of: find.byKey(customOverlay), matching: find.text('Custom overlay')), findsOneWidget);
      await cleanup(tester);
    });
  });

  group('regions', () {
    testWidgets('top and bottom bars are shown at the same time, each with its own queue', (WidgetTester tester) async {
      await boot(tester);
      final List<int> all = <int>[];
      void listener() => all.add(FluentBar.allQueueLengthNotifier.value);
      FluentBar.allQueueLengthNotifier.addListener(listener);
      addTearDown(() => FluentBar.allQueueLengthNotifier.removeListener(listener));

      final FluentBarEntry<void>? top = show('Top 1');
      final FluentBarEntry<void>? bottom = show('Bottom 1', bottom: true);
      show('Top 2');
      show('Bottom 2', bottom: true);
      show('Bottom 3', bottom: true);
      await tester.pump();

      expect(FluentBar.mainActiveItem, same(top));
      expect(FluentBar.bottomActiveItem, same(bottom));
      expect(FluentBar.activeItems, <FluentBarEntry<dynamic>?>[top, bottom]);
      expect(messages(FluentBar.mainQueue), <String>['Top 2']);
      expect(messages(FluentBar.bottomQueue), <String>['Bottom 2', 'Bottom 3']);
      expect(messages(FluentBar.allQueue), <String>['Top 2', 'Bottom 2', 'Bottom 3']);
      expect(FluentBar.mainQueueLength, 1);
      expect(FluentBar.bottomQueueLength, 2);
      expect(FluentBar.allQueueLength, 3);
      expect(FluentBar.mainQueueLengthNotifier.value, 1);
      expect(FluentBar.bottomQueueLengthNotifier.value, 2);
      expect(all, <int>[1, 2, 3]);
      await cleanup(tester);
    });

    testWidgets('closing a bar shows the next one from the same region only', (WidgetTester tester) async {
      await boot(tester);
      show('Top 1');
      final FluentBarEntry<void>? bottom = show('Bottom 1', bottom: true);
      show('Top 2');
      show('Bottom 2', bottom: true);

      await manager.dismissCurrentMain(skipAnimation: true);
      await tester.pump();

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Top 2');
      expect(FluentBar.bottomActiveItem, same(bottom));
      expect(messages(FluentBar.bottomQueue), <String>['Bottom 2']);

      await manager.dismissCurrentBottom(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.bottomActiveItem?.currentItem.message, 'Bottom 2');
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Top 2');
      await cleanup(tester);
    });

    testWidgets('left, right and center share the main region with top', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? first = show('Center', position: FluentBarPosition.center);
      show('Left', position: FluentBarPosition.left);
      show('Right', position: FluentBarPosition.right);
      show('Top', position: FluentBarPosition.top);

      expect(FluentBar.mainActiveItem, same(first));
      expect(FluentBar.mainQueueLength, 3);
      expect(FluentBar.bottomActiveItem, isNull);
      await cleanup(tester);
    });

    testWidgets('lastActiveItem and dismissLatest follow the order of showing, not the region', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? bottom = show('Bottom', bottom: true);
      final FluentBarEntry<void>? top = show('Top');
      expect(FluentBar.lastActiveItem, same(top));

      await manager.dismissLatest(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.lastActiveItem, same(bottom));

      await manager.dismissLatest(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.lastActiveItem, isNull);
      await manager.dismissLatest(skipAnimation: true);
    });
  });

  group('enableMultiRegion: false (single queue)', () {
    const FluentBarConfig single = FluentBarConfig(enableMultiRegion: false);

    testWidgets('top and bottom bars share one queue and are shown one at a time', (WidgetTester tester) async {
      await boot(tester, config: single);
      final FluentBarEntry<void>? top = show('Top 1');
      show('Bottom 1', bottom: true);
      show('Top 2');
      await tester.pump();

      expect(FluentBar.activeItems, <FluentBarEntry<dynamic>?>[top]);
      expect(FluentBar.bottomActiveItem, isNull);
      expect(messages(FluentBar.mainQueue), <String>['Bottom 1', 'Top 2']);
      expect(FluentBar.bottomQueue, isEmpty);
      expect(FluentBar.bottomQueueLengthNotifier.value, 0);
      expect(find.text('Bottom 1'), findsNothing);

      await FluentBar.closeActive(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Bottom 1');
      expect(FluentBar.activeItems, hasLength(1));
      await cleanup(tester);
    });

    testWidgets('a bottom bar is still drawn at the bottom of the screen', (WidgetTester tester) async {
      await boot(tester, config: single);
      show('Bottom', bottom: true);
      await shown(tester);

      final double screenHeight = tester.getSize(find.byType(MaterialApp)).height;
      expect(tester.getCenter(find.text('Bottom')).dy, greaterThan(screenHeight / 2));
      await cleanup(tester);
    });

    testWidgets('duplicates and force work across positions', (WidgetTester tester) async {
      await boot(tester, config: single);
      final FluentBarEntry<void>? top = show('Top', id: 'same');

      final FluentBarEntry<void>? bottom = show('Bottom', id: 'same', bottom: true);
      expect(bottom, same(top));
      expect(top!.currentItem.message, 'Bottom');

      final FluentBarEntry<void>? forced = show('Forced bottom', bottom: true, isForce: true);
      expect(FluentBar.activeItems, <FluentBarEntry<dynamic>?>[forced]);
      await cleanup(tester);
    });

    testWidgets('the queue limit is shared by all positions', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(enableMultiRegion: false, maxQueueLength: 1));
      show('Active');
      show('Queued bottom', bottom: true);

      expect(show('Rejected top'), isNull);
      expect(show('Rejected bottom', bottom: true), isNull);
      await cleanup(tester);
    });

    testWidgets('switching to a single queue moves waiting bottom bars and lets shown bars finish', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? top = show('Top');
      final FluentBarEntry<void>? bottom = show('Bottom', bottom: true);
      show('Bottom queued', bottom: true);
      show('Top queued');

      FluentBar.updateConfig(single);

      expect(FluentBar.activeItems, <FluentBarEntry<dynamic>?>[top, bottom], reason: 'bars already on screen are not closed');
      expect(FluentBar.bottomQueue, isEmpty);
      expect(messages(FluentBar.mainQueue), <String>['Bottom queued', 'Top queued'], reason: 'merged in the order of requests');

      await manager.dismissCurrentMain(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.activeItems, <FluentBarEntry<dynamic>?>[bottom]);

      await manager.dismissCurrentBottom(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.activeItems.single.currentItem.message, 'Bottom queued');
      expect(FluentBar.bottomActiveItem, isNull);
      await cleanup(tester);
    });

    testWidgets('switching back to two queues returns bottom bars to their own queue and shows them', (WidgetTester tester) async {
      await boot(tester, config: single);
      final FluentBarEntry<void>? top = show('Top');
      show('Bottom 1', bottom: true);
      show('Top queued');
      show('Bottom 2', bottom: true);

      FluentBar.updateConfig(const FluentBarConfig());
      await tester.pump();

      expect(FluentBar.mainActiveItem, same(top));
      expect(FluentBar.bottomActiveItem?.currentItem.message, 'Bottom 1');
      expect(messages(FluentBar.mainQueue), <String>['Top queued']);
      expect(messages(FluentBar.bottomQueue), <String>['Bottom 2']);
      await cleanup(tester);
    });
  });

  group('queue order', () {
    testWidgets('default (smart) strategy shows higher priority first', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('Low', priority: FluentBarPriority.low);
      show('Critical', priority: FluentBarPriority.critical);
      show('Normal');

      expect(messages(FluentBar.mainQueue), <String>['Critical', 'Normal', 'Low']);
      await cleanup(tester);
    });

    testWidgets('FIFO strategy shows bars in the order they were requested', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: FifoQueueStrategy()));
      show('Active');
      show('First', priority: FluentBarPriority.low);
      show('Second', priority: FluentBarPriority.critical);

      await FluentBar.closeActive(skipAnimation: true);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'First');
      await FluentBar.closeActive(skipAnimation: true);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Second');
      await cleanup(tester);
    });

    testWidgets('LIFO strategy shows the most recent bar first', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: LifoQueueStrategy()));
      show('Active');
      show('First');
      show('Second');

      await FluentBar.closeActive(skipAnimation: true);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Second');
      await FluentBar.closeActive(skipAnimation: true);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'First');
      await cleanup(tester);
    });

    testWidgets('a strategy that returns shouldForce replaces the active bar', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: _AlwaysForceStrategy()));
      FluentBarDismissReason? reason;
      show('First', callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => reason = m.dismissReason));
      final FluentBarEntry<void>? second = show('Second');
      await tester.pump();

      expect(FluentBar.mainActiveItem, same(second));
      expect(reason, FluentBarDismissReason.force);
      await cleanup(tester);
    });

    testWidgets('elements dropped by a strategy are disposed and reported as overflow', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: _KeepLatestStrategy()));
      show('Active');
      final FluentBarEntry<void>? dropped = show('Dropped');
      show('Kept');

      expect(messages(FluentBar.mainQueue), <String>['Kept']);
      expect(dropped!.internalController.isDisposed, isTrue);
      expect(eventsOf('Dropped'), contains(FluentBarAnalyticsEvent.queueOverflow));
      await cleanup(tester);
    });

    testWidgets('a strategy failing on enqueue falls back to appending', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: _ThrowOnEnqueueStrategy()));
      final FluentBarEntry<void>? active = show('Active');
      show('Queued 1');
      show('Queued 2');

      expect(FluentBar.mainActiveItem, same(active));
      expect(messages(FluentBar.mainQueue), <String>['Queued 1', 'Queued 2']);
      expect(errorTypes(), everyElement(FluentBarErrorType.queueEnqueue));
      expect(errors, hasLength(3));
      await cleanup(tester);
    });

    testWidgets('a strategy failing on dequeue falls back to the first element', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: _ThrowOnDequeueStrategy()));
      show('Active');
      show('Queued 1');
      show('Queued 2');
      errors.clear();

      await FluentBar.closeActive(skipAnimation: true);

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Queued 1');
      expect(messages(FluentBar.mainQueue), <String>['Queued 2']);
      expect(errorTypes(), <FluentBarErrorType>[FluentBarErrorType.queueDequeue]);
      await cleanup(tester);
    });
  });

  group('queue limits', () {
    testWidgets('a bar that does not fit is rejected with a warning', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(maxQueueLength: 2));
      show('Active');
      show('Queued 1');
      show('Queued 2');

      final FluentBarEntry<void>? rejected = show('Rejected');

      expect(rejected, isNull);
      expect(FluentBar.mainQueueLength, 2);
      expect(eventsOf('Rejected'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.queueOverflow]);
      expect(errors.single.type, FluentBarErrorType.queueOverflow);
      expect(errors.single.severity, FluentBarErrorSeverity.warning);
      await cleanup(tester);
    });

    testWidgets('the limit applies to each region separately', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(maxQueueLength: 1));
      show('Top active');
      show('Top queued');
      show('Bottom active', bottom: true);

      expect(show('Bottom queued', bottom: true), isNotNull);
      expect(show('Top rejected'), isNull);
      await cleanup(tester);
    });

    testWidgets('lowering maxQueueLength drops the tail of the queue', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('Queued 1');
      final FluentBarEntry<void>? dropped = show('Queued 2');

      FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 1));

      expect(messages(FluentBar.mainQueue), <String>['Queued 1']);
      expect(FluentBar.mainQueueLengthNotifier.value, 1);
      expect(dropped!.internalController.isDisposed, isTrue);
      expect(eventsOf('Queued 2'), contains(FluentBarAnalyticsEvent.queueOverflow));
      await cleanup(tester);
    });
  });

  group('duplicates', () {
    testWidgets('active bar, update policy (default): content is replaced in place', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? first = show('One', id: 'a');
      final FluentBarEntry<void>? second = show('Two', id: 'a');
      await tester.pump();

      expect(second, same(first));
      expect(first!.currentItem.message, 'Two');
      expect(FluentBar.mainQueueLength, 0);
      expect(eventsOf('Two'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.updated]);
      expect(find.text('Two'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('active bar, ignore policy: the new request is dropped', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? first = show('One', id: 'a');
      final FluentBarEntry<void>? second = show('Two', id: 'a', policy: FluentBarDuplicatePolicy.ignore);

      expect(second, same(first));
      expect(first!.currentItem.message, 'One');
      expect(eventsOf('Two'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.ignoredDuplicate]);
      await cleanup(tester);
    });

    testWidgets('active bar, ignore policy still lets a progress change through', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? first = show('Loading', id: 'a', progress: const FluentBarProgressValue(0.2));
      show('Loading', id: 'a', policy: FluentBarDuplicatePolicy.ignore, progress: const FluentBarProgressValue(0.6));

      expect(first!.controller.taskProgressNotifier.value, 0.6);
      expect(analytics.map((FluentBarAnalyticsPayload p) => p.event), contains(FluentBarAnalyticsEvent.updated));
      await cleanup(tester);
    });

    testWidgets('active bar, update keeps the countdown, updateAndResetTimer restarts it', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = show('One', id: 'a', duration: const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 2));

      show('Two', id: 'a', duration: const Duration(seconds: 5), policy: FluentBarDuplicatePolicy.update);
      expect(entry!.controller.remainingDurationNotifier.value, const Duration(seconds: 3));

      show('Three', id: 'a', duration: const Duration(seconds: 5), policy: FluentBarDuplicatePolicy.updateAndResetTimer);
      expect(entry.controller.remainingDurationNotifier.value, const Duration(seconds: 5));
      expect(entry.currentItem.message, 'Three');
      await cleanup(tester);
    });

    testWidgets('queued bar, ignore policy keeps the queued one', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      final FluentBarEntry<void>? queued = show('One', id: 'q');
      final FluentBarEntry<void>? again = show('Two', id: 'q', policy: FluentBarDuplicatePolicy.ignore);

      expect(again, same(queued));
      expect(messages(FluentBar.mainQueue), <String>['One']);
      expect(eventsOf('Two'), contains(FluentBarAnalyticsEvent.ignoredDuplicate));
      await cleanup(tester);
    });

    testWidgets('queued bar, update policy replaces the content and re-sorts on a higher priority', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('Normal');
      final FluentBarEntry<void>? queued = show('One', id: 'q', priority: FluentBarPriority.low);
      expect(messages(FluentBar.mainQueue), <String>['Normal', 'One']);

      final FluentBarEntry<void>? merged = show('Two', id: 'q', priority: FluentBarPriority.critical);

      expect(merged, same(queued));
      expect(messages(FluentBar.mainQueue), <String>['Two', 'Normal']);
      expect(eventsOf('Two'), contains(FluentBarAnalyticsEvent.updated));
      await cleanup(tester);
    });

    testWidgets('queued bar keeps its priority when the duplicate has a lower one', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      final FluentBarEntry<void>? queued = show('One', id: 'q', priority: FluentBarPriority.critical);
      show('Normal');

      show('Two', id: 'q', priority: FluentBarPriority.low);

      expect(messages(FluentBar.mainQueue), <String>['Two', 'Normal']);
      expect(queued!.resolvePriority(FluentBar.currentConfig), FluentBarPriority.critical);
      await cleanup(tester);
    });

    testWidgets('allow policy shows every request as a separate bar', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? first = show('One', id: 'a');
      final FluentBarEntry<void>? second = show('One', id: 'a', policy: FluentBarDuplicatePolicy.allow);

      expect(second, isNot(same(first)));
      expect(FluentBar.mainQueueLength, 1);
      await cleanup(tester);
    });

    testWidgets('the same id with another position is the same bar: it moves instead of doubling', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? top = show('Same', id: 'a');
      final FluentBarEntry<void>? bottom = show('Same', id: 'a', bottom: true);

      expect(bottom, same(top));
      expect(FluentBar.activeItems, hasLength(1));
      expect(FluentBar.bottomActiveItem, same(top));
      await cleanup(tester);
    });

    testWidgets('a custom comparator decides what a duplicate is', (WidgetTester tester) async {
      await boot(tester, config: FluentBarConfig(duplicateComparator: (FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => a.message == b.message));
      final FluentBarEntry<void>? first = show('Same', id: 'a');
      final FluentBarEntry<void>? second = show('Same', id: 'b');
      final FluentBarEntry<void>? third = show('Other', id: 'a');

      expect(second, same(first));
      expect(third, isNot(same(first)));
      await cleanup(tester);
    });

    testWidgets('a throwing comparator is reported and treated as "not a duplicate"', (WidgetTester tester) async {
      await boot(tester, config: FluentBarConfig(duplicateComparator: (FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => throw Exception('boom')));
      final FluentBarEntry<void>? first = show('One', id: 'a');
      final FluentBarEntry<void>? second = show('Two', id: 'a');

      expect(second, isNot(same(first)));
      expect(FluentBar.mainQueueLength, 1);
      expect(errorTypes(), contains(FluentBarErrorType.callbackDuplicateComparator));
      await cleanup(tester);
    });
  });

  group('force', () {
    testWidgets('a forced bar replaces a regular active bar immediately', (WidgetTester tester) async {
      await boot(tester);
      FluentBarDismissReason? reason;
      show('Active', callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => reason = m.dismissReason));
      show('Queued');

      final FluentBarEntry<void> forced = FluentBar.forceItem<void>(FluentBarItem<void>(type: FluentBarType.info, message: 'Forced', isPersistent: true));
      await tester.pump();

      expect(FluentBar.mainActiveItem, same(forced));
      expect(forced.isForce, isTrue);
      expect(reason, FluentBarDismissReason.force);
      expect(messages(FluentBar.mainQueue), <String>['Queued']);
      expect(find.text('Forced'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('show() with isForce behaves like forceItem', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      final FluentBarEntry<void>? forced = show('Forced', isForce: true);

      expect(FluentBar.mainActiveItem, same(forced));
      await cleanup(tester);
    });

    testWidgets('forced bars do not interrupt each other and are shown in request order', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? first = show('Forced 1', isForce: true);
      show('Regular', priority: FluentBarPriority.critical);
      show('Forced 2', isForce: true);
      show('Forced 3', isForce: true);

      expect(FluentBar.mainActiveItem, same(first));
      expect(messages(FluentBar.mainQueue), <String>['Forced 2', 'Forced 3', 'Regular']);

      await FluentBar.closeActive(skipAnimation: true);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Forced 2');
      await cleanup(tester);
    });

    testWidgets('a forced bar affects only its own region', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? bottom = show('Bottom', bottom: true);
      show('Top');
      show('Forced top', isForce: true);

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Forced top');
      expect(FluentBar.bottomActiveItem, same(bottom));
      await cleanup(tester);
    });

    testWidgets('forceItemFromQueue and controller.force() promote a queued bar', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('Queued 1');
      show('By id', id: 'target');
      final FluentBarEntry<void>? byController = show('By controller');

      FluentBar.forceItemFromQueue(id: 'target');
      expect(FluentBar.mainActiveItem?.currentItem.message, 'By id');

      byController!.controller.force();
      expect(messages(FluentBar.mainQueue), <String>['By controller', 'Queued 1']);

      FluentBar.forceItemFromQueue(id: 'missing');
      expect(messages(FluentBar.mainQueue), <String>['By controller', 'Queued 1']);
      await cleanup(tester);
    });

    testWidgets('forcing the active bar restarts its countdown', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = show('Active', duration: const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 3));
      expect(entry!.controller.remainingDurationNotifier.value, const Duration(seconds: 2));

      entry.controller.force();

      expect(FluentBar.mainActiveItem, same(entry));
      expect(entry.isForce, isTrue);
      expect(entry.controller.remainingDurationNotifier.value, const Duration(seconds: 5));
      await cleanup(tester);
    });

    testWidgets('forceItem removes queued duplicates of the same id', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      final FluentBarEntry<void>? stale = show('Stale', id: 'x');

      FluentBar.forceItem<void>(FluentBarItem<void>(id: 'x', type: FluentBarType.info, message: 'Fresh', isPersistent: true));

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Fresh');
      expect(FluentBar.mainQueueLength, 0);
      expect(stale!.internalController.isDisposed, isTrue);
      await cleanup(tester);
    });

    testWidgets('a forced bar that is shown right away does not push anything out of a full queue', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(maxQueueLength: 2));
      show('Active');
      show('Queued 1');
      show('Queued 2');

      show('Forced', isForce: true);

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Forced');
      expect(messages(FluentBar.mainQueue), <String>['Queued 1', 'Queued 2']);
      await cleanup(tester);
    });

    testWidgets('a forced bar that has to wait pushes the last regular one out of a full queue', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(maxQueueLength: 2));
      show('Forced active', isForce: true);
      show('Queued 1');
      final FluentBarEntry<void>? last = show('Queued 2');

      show('Forced waiting', isForce: true);

      expect(messages(FluentBar.mainQueue), <String>['Forced waiting', 'Queued 1']);
      expect(last!.internalController.isDisposed, isTrue);
      expect(eventsOf('Queued 2'), contains(FluentBarAnalyticsEvent.queueOverflow));
      await cleanup(tester);
    });
  });

  group('updateItemPriority', () {
    testWidgets('re-sorts a queued bar found by id or by item', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('A', id: 'a');
      show('B', id: 'b');
      final FluentBarEntry<void>? c = show('C', id: 'c');
      expect(messages(FluentBar.mainQueue), <String>['A', 'B', 'C']);

      FluentBar.updateItemPriority(id: 'b', newPriority: FluentBarPriority.high);
      expect(messages(FluentBar.mainQueue), <String>['B', 'A', 'C']);

      FluentBar.updateItemPriority(item: c!.currentItem, newPriority: FluentBarPriority.critical);
      expect(messages(FluentBar.mainQueue), <String>['C', 'B', 'A']);

      FluentBar.updateItemPriority(id: 'a', newPriority: FluentBarPriority.low);
      expect(messages(FluentBar.mainQueue), <String>['C', 'B', 'A']);
      await cleanup(tester);
    });

    testWidgets('does nothing for an unknown bar or without arguments', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('A', id: 'a');

      FluentBar.updateItemPriority(id: 'missing', newPriority: FluentBarPriority.critical);
      FluentBar.updateItemPriority(newPriority: FluentBarPriority.critical);

      expect(messages(FluentBar.mainQueue), <String>['A']);
      expect(errors, isEmpty);
      await cleanup(tester);
    });
  });

  group('dismissal', () {
    testWidgets('an animated close waits for the exit animation, then shows the next bar', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? active = show('Active');
      show('Next');
      await shown(tester);

      bool closed = false;
      unawaited(FluentBar.closeActive().then((_) => closed = true));
      await tester.pump();
      expect(active!.controller.stateNotifier.value, FluentBarLifecycleState.hiding);
      expect(FluentBar.mainActiveItem, same(active));
      expect(closed, isFalse);

      await tester.pump(const Duration(seconds: 1));
      expect(closed, isTrue);
      expect(active.internalController.isDisposed, isTrue);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Next');
      await cleanup(tester);
    });

    testWidgets('repeated close calls during the animation dismiss the bar only once', (WidgetTester tester) async {
      await boot(tester);
      int dismissed = 0;
      final FluentBarEntry<void>? active = show('Active', callbacks: FluentBarCallbacks<void>(onDismiss: (_, _) => dismissed++));
      await shown(tester);

      active!.controller.close();
      active.controller.close();
      unawaited(FluentBar.closeActive());
      await tester.pump(const Duration(seconds: 1));

      expect(dismissed, 1);
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('a swipe closes immediately, even in the middle of an animated close', (WidgetTester tester) async {
      await boot(tester);
      FluentBarDismissReason? reason;
      final FluentBarEntry<void>? active = show('Active', callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => reason = m.dismissReason));
      await shown(tester);

      active!.controller.close();
      active.controller.close(reason: FluentBarDismissReason.swipe);
      await tester.pump();

      expect(FluentBar.mainActiveItem, isNull);
      expect(reason, FluentBarDismissReason.swipe);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('closeActive closes both regions and leaves the queues to continue', (WidgetTester tester) async {
      await boot(tester);
      show('Top');
      show('Bottom', bottom: true);
      show('Top next');

      await FluentBar.closeActive(skipAnimation: true);
      await tester.pump();

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Top next');
      expect(FluentBar.bottomActiveItem, isNull);
      await cleanup(tester);
    });

    testWidgets('closeAll empties the queues and closes active bars with the given reason', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarDismissReason> reasons = <FluentBarDismissReason>[];
      final FluentBarCallbacks<void> callbacks = FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => reasons.add(m.dismissReason));
      show('Top', callbacks: callbacks);
      show('Bottom', bottom: true, callbacks: callbacks);
      final FluentBarEntry<void>? queued = show('Queued', callbacks: callbacks);

      await FluentBar.closeAll(reason: FluentBarDismissReason.tap, skipAnimation: true);
      await tester.pump();

      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.allQueueLength, 0);
      expect(reasons, <FluentBarDismissReason>[FluentBarDismissReason.tap, FluentBarDismissReason.tap]);
      expect(queued!.internalController.isDisposed, isTrue);
      expect(eventsOf('Queued'), contains(FluentBarAnalyticsEvent.dismissed));
    });

    testWidgets('dismissAndClear removes queued and active bars at once', (WidgetTester tester) async {
      await boot(tester);
      show('Top');
      show('Bottom', bottom: true);
      show('Queued');

      FluentBar.dismissAndClear();
      await tester.pump();

      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.allQueueLength, 0);
      expect(find.text('Top'), findsNothing);
      expect(find.text('Bottom'), findsNothing);

      FluentBar.dismissAndClear();
      await FluentBar.closeAll();
      await FluentBar.closeActive();
      expect(errors, isEmpty);
    });

    testWidgets('closing a queued bar removes it from the queue without showing it', (WidgetTester tester) async {
      await boot(tester);
      bool shown = false;
      show('Active');
      final FluentBarEntry<void>? queued = show('Queued', callbacks: FluentBarCallbacks<void>(onShow: (_) => shown = true));
      show('Next');

      queued!.controller.close();

      expect(messages(FluentBar.mainQueue), <String>['Next']);
      expect(queued.internalController.isDisposed, isTrue);
      expect(eventsOf('Queued'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.queued, FluentBarAnalyticsEvent.dismissed]);

      await FluentBar.closeActive(skipAnimation: true);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Next');
      expect(shown, isFalse);
      await cleanup(tester);
    });

    testWidgets('a bar closed while waiting for an overlay is skipped', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      final FluentBarEntry<void>? first = show('First');
      show('Second');
      first!.controller.close();

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      expect(FluentBar.mainActiveItem?.currentItem.message, 'Second');
      await cleanup(tester);
    });
  });

  group('callbacks and analytics', () {
    testWidgets('the full lifecycle is reported with metrics', (WidgetTester tester) async {
      await boot(tester);
      FluentBarItem<void>? shownItem;
      FluentBarMetrics? dismissMetrics;
      show(
        'Tracked',
        id: 'tracked',
        type: FluentBarType.success,
        duration: const Duration(seconds: 3),
        callbacks: FluentBarCallbacks<void>(onShow: (FluentBarItem<void> item) => shownItem = item, onDismiss: (_, FluentBarMetrics m) => dismissMetrics = m),
      );
      await tester.pump();
      expect(shownItem?.message, 'Tracked');
      expect(eventsOf('Tracked'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.shown]);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      expect(eventsOf('Tracked').last, FluentBarAnalyticsEvent.dismissed);
      expect(dismissMetrics?.id, 'tracked');
      expect(dismissMetrics?.dismissReason, FluentBarDismissReason.timeout);
      expect(dismissMetrics?.timedOut, isTrue);
      expect(dismissMetrics?.wasActionTapped, isFalse);
      expect(dismissMetrics?.typeName, 'success');
      expect(dismissMetrics?.plannedDuration, const Duration(seconds: 3));
      expect(analytics.last.metrics, same(dismissMetrics));
    });

    testWidgets('a removed listener stops receiving events; a throwing one does not break the others', (WidgetTester tester) async {
      await boot(tester);
      int removedCalls = 0;
      void removed(FluentBarAnalyticsPayload payload) => removedCalls++;
      void throwing(FluentBarAnalyticsPayload payload) => throw Exception('boom');
      FluentBar.addAnalyticsListener(throwing);
      FluentBar.addAnalyticsListener(removed);
      FluentBar.addAnalyticsListener(removed);
      addTearDown(() => FluentBar.removeAnalyticsListener(throwing));

      show('One');
      expect(removedCalls, 2, reason: 'requested + shown, the listener is registered once');

      FluentBar.removeAnalyticsListener(removed);
      show('Two');

      expect(removedCalls, 2);
      expect(eventsOf('Two'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.queued]);
      expect(errorTypes(), everyElement(FluentBarErrorType.callbackAnalytics));
      await cleanup(tester);
    });

    testWidgets('a throwing onShow or onDismiss is reported and does not break the flow', (WidgetTester tester) async {
      await boot(tester);
      show(
        'Fragile',
        callbacks: FluentBarCallbacks<void>(onShow: (_) => throw Exception('show failed'), onDismiss: (_, _) => throw Exception('dismiss failed')),
      );
      show('Next');
      await tester.pump();
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Fragile');
      expect(errorTypes(), <FluentBarErrorType>[FluentBarErrorType.callbackShow]);

      await FluentBar.closeActive(skipAnimation: true);
      await tester.pump();

      expect(errorTypes(), <FluentBarErrorType>[FluentBarErrorType.callbackShow, FluentBarErrorType.callbackDismiss]);
      expect(FluentBar.mainActiveItem?.currentItem.message, 'Next');
      await cleanup(tester);
    });

    testWidgets('an action tap is reported and closes the bar with the actionButton reason', (WidgetTester tester) async {
      await boot(tester);
      FluentBarMetrics? metrics;
      final FluentBarEntry<void>? entry = show('With action', callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => metrics = m));
      await shown(tester);

      unawaited(entry!.controller.handleAction());
      await tester.pump(const Duration(seconds: 1));

      expect(eventsOf('With action'), contains(FluentBarAnalyticsEvent.actionTapped));
      expect(metrics?.dismissReason, FluentBarDismissReason.actionButton);
      expect(metrics?.wasActionTapped, isTrue);
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('progress completion and cancellation are reported', (WidgetTester tester) async {
      await boot(tester);
      final List<String> calls = <String>[];
      final FluentBarEntry<void>? entry = show(
        'Upload',
        progress: const FluentBarProgressValue(0.1),
        callbacks: FluentBarCallbacks<void>(onProgressCompleted: (_) => calls.add('completed'), onProgressCanceled: (_) => calls.add('canceled')),
      );

      entry!.controller.updateProgress(const FluentBarProgressValue(1.0));
      expect(calls, <String>['completed']);
      expect(analytics.map((FluentBarAnalyticsPayload p) => p.event), contains(FluentBarAnalyticsEvent.progressCompleted));

      entry.controller.cancelProgress();
      expect(calls, <String>['completed', 'canceled']);
      expect(analytics.map((FluentBarAnalyticsPayload p) => p.event), contains(FluentBarAnalyticsEvent.progressCanceled));
      await cleanup(tester);
    });
  });

  group('haptics', () {
    List<String> trackHaptics(WidgetTester tester) {
      final List<String> haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      return haptics;
    }

    testWidgets('the haptic type comes from the item, then from the type', (WidgetTester tester) async {
      await boot(tester);
      final List<String> haptics = trackHaptics(tester);

      show('Local', haptic: FluentBarHapticType.light, type: FluentBarType.error);
      show('From type', bottom: true, type: FluentBarType.error);
      await tester.pump();

      expect(haptics, <String>['HapticFeedbackType.lightImpact', 'HapticFeedbackType.heavyImpact']);
      await cleanup(tester);
    });

    testWidgets('a custom haptic always wins over a haptic type', (WidgetTester tester) async {
      await boot(tester);
      final List<String> haptics = trackHaptics(tester);
      final List<String> custom = <String>[];
      final FluentBarType typeWithCustom = FluentBarType.info.copyWith(customHaptic: () => custom.add('type'), haptic: FluentBarHapticType.heavy);

      show('Type custom', type: typeWithCustom, haptic: FluentBarHapticType.light);
      show(
        'Local custom',
        bottom: true,
        type: typeWithCustom,
        callbacks: FluentBarCallbacks<void>(haptic: () => custom.add('local')),
      );
      await tester.pump();

      expect(custom, <String>['type', 'local']);
      expect(haptics, isEmpty);
      await cleanup(tester);
    });

    testWidgets('a throwing custom haptic is reported and the bar is still shown', (WidgetTester tester) async {
      await boot(tester);
      show('Fragile', callbacks: FluentBarCallbacks<void>(haptic: () => throw Exception('boom')));
      await tester.pump();

      expect(errorTypes(), <FluentBarErrorType>[FluentBarErrorType.hapticExternal]);
      expect(find.text('Fragile'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('progress completion: custom haptic wins over the haptic type', (WidgetTester tester) async {
      await boot(tester);
      final List<String> haptics = trackHaptics(tester);
      int custom = 0;

      final FluentBarEntry<void>? plain = FluentBar.show<void>(
        message: 'Enum',
        isPersistent: true,
        options: const FluentBarOptions<void>(
          behavior: FluentBarBehavior(progressCompletedHaptic: FluentBarHapticType.medium),
          progressState: FluentBarProgressValue(0.5),
        ),
      );
      haptics.clear();
      plain!.controller.updateProgress(const FluentBarProgressValue(1.0));
      expect(haptics, <String>['HapticFeedbackType.mediumImpact']);

      final FluentBarEntry<void>? withCustom = FluentBar.show<void>(
        message: 'Custom',
        isPersistent: true,
        options: FluentBarOptions<void>(
          behavior: const FluentBarBehavior(position: FluentBarPosition.bottom, progressCompletedHaptic: FluentBarHapticType.medium),
          callbacks: FluentBarCallbacks<void>(progressCompletedHaptic: () => custom++),
          progressState: const FluentBarProgressValue(0.5),
        ),
      );
      haptics.clear();
      withCustom!.controller.updateProgress(const FluentBarProgressValue(1.0));

      expect(custom, 1);
      expect(haptics, isEmpty, reason: 'no vibration when a custom haptic exists');
      await cleanup(tester);
    });
  });

  group('error handlers', () {
    testWidgets('handlers can be added once and removed; a throwing handler does not break the others', (WidgetTester tester) async {
      await boot(tester);
      int calls = 0;
      void counting(FluentBarException error, StackTrace stackTrace) => calls++;
      void throwing(FluentBarException error, StackTrace stackTrace) => throw Exception('handler failed');
      FluentBar.addErrorHandler(throwing);
      FluentBar.addErrorHandler(counting);
      FluentBar.addErrorHandler(counting);
      addTearDown(() => FluentBar.removeErrorHandler(throwing));

      FluentBar.initialize(config: const FluentBarConfig());
      expect(calls, 1);
      expect(errors, hasLength(1));

      FluentBar.removeErrorHandler(counting);
      FluentBar.initialize(config: const FluentBarConfig());
      expect(calls, 1);
      expect(errors, hasLength(2));
    });
  });
}
