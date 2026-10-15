import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  setUp(manager.resetForTesting);

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  group('structure', () {
    testWidgets('renders the child inside its own overlay and works without an app around it', (WidgetTester tester) async {
      await tester.pumpWidget(const FluentBarScope(child: Text('Scope Child Content', textDirection: TextDirection.ltr)));

      expect(find.text('Scope Child Content'), findsOneWidget);
      expect(find.byType(Overlay), findsOneWidget);
      expect(find.byType(Directionality), findsWidgets);
    });

    testWidgets('keeps the text direction of the surrounding app', (WidgetTester tester) async {
      late TextDirection direction;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: FluentBarScope(
            child: Builder(
              builder: (BuildContext context) {
                direction = Directionality.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(direction, TextDirection.rtl);
    });

    testWidgets('builder() wraps the app content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(config: const FluentBarConfig(defaultShowTimeoutBar: true)),
          home: const Scaffold(body: Text('Builder Home Screen')),
        ),
      );

      expect(find.text('Builder Home Screen'), findsOneWidget);
      expect(find.descendant(of: find.byType(FluentBarScope), matching: find.text('Builder Home Screen')), findsOneWidget);
      expect(manager.config.defaultShowTimeoutBar, isTrue);
    });

    testWidgets('builder() tolerates a missing child', (WidgetTester tester) async {
      await tester.pumpWidget(Builder(builder: (BuildContext context) => FluentBarScope.builder()(context, null)));

      expect(find.byType(FluentBarScope), findsOneWidget);
    });

    testWidgets('a rebuilt child is updated inside the overlay', (WidgetTester tester) async {
      await tester.pumpWidget(const FluentBarScope(child: Text('Before', textDirection: TextDirection.ltr)));
      await tester.pumpWidget(const FluentBarScope(child: Text('After', textDirection: TextDirection.ltr)));

      expect(find.text('Before'), findsNothing);
      expect(find.text('After'), findsOneWidget);
    });
  });

  group('config', () {
    testWidgets('initializes the manager with its config, or with defaults', (WidgetTester tester) async {
      expect(manager.isInitialized, isFalse);
      await tester.pumpWidget(const FluentBarScope(config: FluentBarConfig(maxQueueLength: 3), child: SizedBox()));

      expect(manager.isInitialized, isTrue);
      expect(manager.config.maxQueueLength, 3);

      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const FluentBarScope(child: SizedBox()));
      expect(manager.isInitialized, isTrue);
      expect(manager.config.maxQueueLength, const FluentBarConfig().maxQueueLength);
    });

    testWidgets('applies its config even when the manager was initialized earlier', (WidgetTester tester) async {
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      FluentBar.initialize(config: const FluentBarConfig(maxQueueLength: 9));
      await tester.pumpWidget(const FluentBarScope(config: FluentBarConfig(maxQueueLength: 3), child: SizedBox()));

      expect(manager.config.maxQueueLength, 3);
      expect(errors, isEmpty, reason: 'the scope must not try to initialize the manager twice');
    });

    testWidgets('without a config it leaves an existing configuration alone', (WidgetTester tester) async {
      FluentBar.initialize(config: const FluentBarConfig(maxQueueLength: 9));
      await tester.pumpWidget(const FluentBarScope(child: SizedBox()));

      expect(manager.config.maxQueueLength, 9);
    });

    testWidgets('a new config is applied on rebuild; the same instance is not re-applied', (WidgetTester tester) async {
      const FluentBarConfig initial = FluentBarConfig(defaultShowTimeoutBar: false);
      const FluentBarConfig updated = FluentBarConfig(defaultShowTimeoutBar: true);
      int notifications = 0;
      void listener() => notifications++;

      await tester.pumpWidget(const FluentBarScope(config: initial, child: SizedBox()));
      expect(manager.config.defaultShowTimeoutBar, isFalse);
      FluentBar.configNotifier.addListener(listener);
      addTearDown(() => FluentBar.configNotifier.removeListener(listener));

      await tester.pumpWidget(const FluentBarScope(config: updated, child: SizedBox()));
      expect(manager.config.defaultShowTimeoutBar, isTrue);
      expect(notifications, 1);

      FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 2));
      await tester.pumpWidget(
        const FluentBarScope(
          config: updated,
          child: Text('rebuilt', textDirection: TextDirection.ltr),
        ),
      );
      expect(manager.config.maxQueueLength, 2);
    });

    testWidgets('a config change may be listened to from the widget tree without build errors', (WidgetTester tester) async {
      Widget tree(FluentBarConfig config) => FluentBarScope(
        config: config,
        child: ValueListenableBuilder<FluentBarConfig>(
          valueListenable: FluentBar.configNotifier,
          builder: (BuildContext context, FluentBarConfig value, Widget? child) => Text('max ${value.maxQueueLength}', textDirection: TextDirection.ltr),
        ),
      );

      await tester.pumpWidget(tree(const FluentBarConfig(maxQueueLength: 3)));
      await tester.pumpWidget(tree(const FluentBarConfig(maxQueueLength: 4)));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('max 4'), findsOneWidget);
    });
  });

  group('overlay registration', () {
    Widget scoped({Key? key}) => MaterialApp(
      home: FluentBarScope(
        key: key,
        child: const Scaffold(body: Text('Home')),
      ),
    );

    testWidgets('bars are shown inside the scope overlay', (WidgetTester tester) async {
      await tester.pumpWidget(scoped());

      FluentBar.show<void>(message: 'In scope', isPersistent: true);
      await tester.pump();

      expect(find.descendant(of: find.byType(FluentBarScope), matching: find.text('In scope')), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('bars requested before the scope exists are shown once it is mounted', (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      FluentBar.show<void>(message: 'Early', isPersistent: true);
      expect(FluentBar.mainQueueLength, 1);

      await tester.pumpWidget(scoped());
      await tester.pump();

      expect(find.text('Early'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('after the scope is removed its overlay is no longer used', (WidgetTester tester) async {
      await tester.pumpWidget(scoped());
      await tester.pumpWidget(const SizedBox());

      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'No overlay', isPersistent: true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(entry, isNotNull);
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.mainQueueLength, 1, reason: 'the bar waits for a new overlay instead of going to a dead one');
      await cleanup(tester);
    });

    testWidgets('replacing one scope with another keeps bars working', (WidgetTester tester) async {
      await tester.pumpWidget(scoped(key: const ValueKey<int>(1)));
      await tester.pumpWidget(scoped(key: const ValueKey<int>(2)));

      FluentBar.show<void>(message: 'New scope', isPersistent: true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.descendant(of: find.byKey(const ValueKey<int>(2)), matching: find.text('New scope')), findsOneWidget);
      await cleanup(tester);
    });
  });
}
