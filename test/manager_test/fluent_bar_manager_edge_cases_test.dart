import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RejectEverythingStrategy extends FluentBarQueueStrategy {
  const _RejectEverythingStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) => QueueOperationResult(queue: queue);

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) => (null, queue);
}

class _DropRestOnDequeueStrategy extends FluentBarQueueStrategy {
  const _DropRestOnDequeueStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) =>
      QueueOperationResult(queue: <FluentBarEntry<dynamic>>[...queue, incoming]);

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) => (queue.first, <FluentBarEntry<dynamic>>[]);
}

class _BrokenOverlayState extends OverlayState {
  @override
  bool get mounted => true;

  @override
  void insert(OverlayEntry entry, {OverlayEntry? below, OverlayEntry? above}) => throw StateError('insert failed');
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  final List<FluentBarException> errors = <FluentBarException>[];
  final List<FluentBarAnalyticsPayload> analytics = <FluentBarAnalyticsPayload>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
  void onAnalytics(FluentBarAnalyticsPayload payload) => analytics.add(payload);

  setUp(() {
    errors.clear();
    analytics.clear();
    FluentBar.addErrorHandler(onError);
    FluentBar.addAnalyticsListener(onAnalytics);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBar.removeAnalyticsListener(onAnalytics);
  });

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig()}) async {
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

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  FluentBarEntry<void>? show(String message, {String? id, bool isForce = false}) => FluentBar.show<void>(
    message: message,
    id: id,
    isPersistent: true,
    options: FluentBarOptions<void>(behavior: FluentBarBehavior(isForce: isForce)),
  );

  List<FluentBarAnalyticsEvent> eventsOf(String message) => analytics.where((FluentBarAnalyticsPayload p) => p.item.message == message).map((FluentBarAnalyticsPayload p) => p.event).toList();

  group('custom strategies', () {
    testWidgets('an element the strategy refuses to enqueue is dropped and reported', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: _RejectEverythingStrategy()));
      int lengthNotifications = 0;
      void listener() => lengthNotifications++;
      FluentBar.mainQueueLengthNotifier.addListener(listener);
      addTearDown(() => FluentBar.mainQueueLengthNotifier.removeListener(listener));

      final FluentBarEntry<void>? entry = show('Rejected');

      expect(entry, isNull);
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.mainQueueLength, 0);
      expect(lengthNotifications, 0);
      expect(eventsOf('Rejected'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.queueOverflow]);
    });

    testWidgets('a strategy created at runtime (not a constant) works the same', (WidgetTester tester) async {
      // ignore: prefer_const_constructors
      final FluentBarQueueStrategy strategy = _DropRestOnDequeueStrategy();
      await boot(tester, config: FluentBarConfig(defaultQueueStrategy: strategy));

      show('Active');
      show('Next');
      await FluentBar.closeActive(skipAnimation: true);

      expect(FluentBar.mainActiveItem?.item.message, 'Next');
      await cleanup(tester);
    });

    testWidgets('elements dropped by the strategy while dequeuing are disposed and reported', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultQueueStrategy: _DropRestOnDequeueStrategy()));
      show('Active');
      show('Next');
      final FluentBarEntry<void>? dropped1 = show('Dropped 1');
      final FluentBarEntry<void>? dropped2 = show('Dropped 2');
      expect(FluentBar.mainQueueLength, 3);

      await FluentBar.closeActive(skipAnimation: true);

      expect(FluentBar.mainActiveItem?.item.message, 'Next');
      expect(FluentBar.mainQueueLength, 0);
      expect(dropped1!.internalController.isDisposed, isTrue);
      expect(dropped2!.internalController.isDisposed, isTrue);
      expect(eventsOf('Dropped 1'), contains(FluentBarAnalyticsEvent.queueOverflow));
      expect(eventsOf('Dropped 2'), contains(FluentBarAnalyticsEvent.queueOverflow));
      await cleanup(tester);
    });
  });

  group('destroyed elements in the queue', () {
    testWidgets('a queued element whose controller was disposed is skipped', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      final FluentBarEntry<void>? dead = show('Dead');
      show('Alive');

      dead!.internalController.dispose();
      await FluentBar.closeActive(skipAnimation: true);

      expect(FluentBar.mainActiveItem?.item.message, 'Alive');
      expect(FluentBar.mainQueueLength, 0);
      await cleanup(tester);
    });

    testWidgets('a forced element whose controller was disposed is skipped too', (WidgetTester tester) async {
      await boot(tester);
      show('Forced active', isForce: true);
      final FluentBarEntry<void>? dead = show('Forced dead', isForce: true);
      show('Alive');

      dead!.internalController.dispose();
      await FluentBar.closeActive(skipAnimation: true);

      expect(FluentBar.mainActiveItem?.item.message, 'Alive');
      expect(FluentBar.mainQueueLength, 0);
      await cleanup(tester);
    });

    testWidgets('disposed elements are purged from the queue on the next show', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      final FluentBarEntry<void>? dead = show('Dead');
      expect(FluentBar.mainQueueLength, 1);

      dead!.internalController.dispose();
      show('New');

      expect(FluentBar.mainQueue.map((FluentBarEntry<dynamic> e) => e.item.message), <String>['New']);
      expect(FluentBar.mainQueueLengthNotifier.value, 1);
      await cleanup(tester);
    });
  });

  group('duplicates', () {
    testWidgets('a forced duplicate of a queued bar promotes that bar', (WidgetTester tester) async {
      await boot(tester);
      show('Active');
      show('Other');
      final FluentBarEntry<void>? queued = show('Queued', id: 'q');

      final FluentBarEntry<void>? merged = show('Queued, now forced', id: 'q', isForce: true);

      expect(merged, same(queued));
      expect(FluentBar.mainActiveItem, same(queued));
      expect(queued!.item.message, 'Queued, now forced');
      expect(queued.isForce, isTrue);
      expect(FluentBar.mainQueue.map((FluentBarEntry<dynamic> e) => e.item.message), <String>['Other']);
      await cleanup(tester);
    });
  });

  group('overlay', () {
    testWidgets('a failing overlay insert is reported, and the bar is dropped without breaking the manager', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Broken', isPersistent: true, overlayState: _BrokenOverlayState());

      expect(errors.single.type, FluentBarErrorType.overlay);
      expect(entry!.internalController.isDisposed, isTrue);
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.mainQueueLength, 0);
      expect(eventsOf('Broken'), <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.dismissed]);
      expect(analytics.last.metrics!.wasVisible, isFalse, reason: 'the bar was never shown');

      show('Fine');
      await tester.pump();
      expect(find.text('Fine'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('a bar requested while the widget tree is being built is shown after the frame', (WidgetTester tester) async {
      await boot(tester);
      bool requested = false;

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                if (!requested) {
                  requested = true;
                  show('From build');
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(FluentBar.mainActiveItem?.item.message, 'From build');
      expect(find.text('From build'), findsOneWidget);
      await cleanup(tester);
    });
  });

  group('config changes and visible bars', () {
    Color backgroundOf(WidgetTester tester, String message) {
      final Container container = tester.widget<Container>(find.ancestor(of: find.text(message), matching: find.byType(Container)).first);
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('a visible bar picks up a new global theme mode: the change starts at once and fades in', (WidgetTester tester) async {
      await boot(
        tester,
        config: const FluentBarConfig(defaultTheme: FluentBarTheme.material, defaultThemeMode: FluentBarThemeMode.light),
      );
      show('Visible');
      await tester.pump();
      expect(backgroundOf(tester, 'Visible'), const Color(0xFF1565C0));

      FluentBar.patchConfig((FluentBarConfig current) => current.copyWith(defaultThemeMode: FluentBarThemeMode.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(backgroundOf(tester, 'Visible'), isNot(const Color(0xFF1565C0)));
      expect(backgroundOf(tester, 'Visible'), isNot(const Color(0xFF0D47A1)));

      await tester.pump(const Duration(milliseconds: 200));
      expect(backgroundOf(tester, 'Visible'), const Color(0xFF0D47A1));
      await cleanup(tester);
    });

    testWidgets('a bar with its own theme mode ignores the global one', (WidgetTester tester) async {
      await boot(
        tester,
        config: const FluentBarConfig(defaultTheme: FluentBarTheme.material, defaultThemeMode: FluentBarThemeMode.light),
      );
      FluentBar.show<void>(
        message: 'Own mode',
        isPersistent: true,
        options: const FluentBarOptions<void>(appearance: FluentBarAppearance<void>(themeMode: FluentBarThemeMode.light)),
      );
      await tester.pump();

      FluentBar.patchConfig((FluentBarConfig current) => current.copyWith(defaultThemeMode: FluentBarThemeMode.dark));
      await tester.pump();

      expect(backgroundOf(tester, 'Own mode'), const Color(0xFF1565C0));
      await cleanup(tester);
    });

    testWidgets('a visible bar picks up a new global theme, also when the config is changed during a build', (WidgetTester tester) async {
      await boot(
        tester,
        config: const FluentBarConfig(defaultTheme: FluentBarTheme.material, defaultThemeMode: FluentBarThemeMode.light),
      );
      show('Visible');
      await tester.pump();
      bool changed = false;

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                if (!changed) {
                  changed = true;
                  FluentBar.updateConfig(const FluentBarConfig(defaultTheme: FluentBarTheme.minimal, defaultThemeMode: FluentBarThemeMode.light));
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(backgroundOf(tester, 'Visible'), const Color(0xFFFAFAFA));
      await cleanup(tester);
    });
  });

  group('config before the app is running', () {
    testWidgets('updateConfig with nothing on screen and nothing queued just stores the config', (WidgetTester tester) async {
      manager.resetForTesting();
      int notifications = 0;
      void listener() => notifications++;
      FluentBar.configNotifier.addListener(listener);
      addTearDown(() => FluentBar.configNotifier.removeListener(listener));

      FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 6));
      FluentBar.patchConfig((FluentBarConfig current) => current.copyWith(maxQueueLength: 7));

      expect(FluentBar.currentConfig.maxQueueLength, 7);
      expect(notifications, 2);
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nothing to rebuild, so no frame is requested');
      expect(errors, isEmpty);
    });

    testWidgets('a config set before the scope is mounted is used by the first bar', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      FluentBar.updateConfig(const FluentBarConfig(defaultTheme: FluentBarTheme.minimal, defaultThemeMode: FluentBarThemeMode.light));

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      show('First');
      await tester.pump();

      final Container container = tester.widget<Container>(find.ancestor(of: find.text('First'), matching: find.byType(Container)).first);
      expect((container.decoration! as BoxDecoration).color, const Color(0xFFFAFAFA));
      await cleanup(tester);
    });
  });

  group('queue length listenable', () {
    test('the combined counter reports the sum and notifies only when the sum changes', () {
      final ValueNotifier<int> main = ValueNotifier<int>(1);
      final ValueNotifier<int> secondary = ValueNotifier<int>(2);
      final CombinedValueListenable combined = CombinedValueListenable(main, secondary);
      final List<int> seen = <int>[];
      void listener() => seen.add(combined.value);
      combined.addListener(listener);

      expect(combined.value, 3);

      main.value = 5;
      secondary.value = 0;
      main.value = 5;
      expect(seen, <int>[7, 5]);

      combined.removeListener(listener);
      main.value = 9;
      expect(seen, <int>[7, 5]);
      expect(combined.value, 9);

      combined.dispose();
      main.value = 100;
      main.dispose();
      secondary.dispose();
    });

    test('a throwing listener does not stop the others', () {
      final ValueNotifier<int> main = ValueNotifier<int>(0);
      final ValueNotifier<int> secondary = ValueNotifier<int>(0);
      final CombinedValueListenable combined = CombinedValueListenable(main, secondary);
      int calls = 0;
      combined.addListener(() => throw Exception('listener failed'));
      combined.addListener(() => calls++);

      final FlutterExceptionHandler? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {};
      addTearDown(() => FlutterError.onError = previous);

      main.value = 1;

      expect(calls, 1);
      FlutterError.onError = previous;
      combined.dispose();
      main.dispose();
      secondary.dispose();
    });
  });
}
