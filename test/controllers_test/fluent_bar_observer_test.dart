import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarObserver observer = FluentBarObserver.instance;
  final FluentBarManager manager = FluentBarManager.instance;

  Widget app({GlobalKey<NavigatorState>? navigatorKey, bool withObserver = true}) => MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: <NavigatorObserver>[if (withObserver) observer],
    home: const Scaffold(body: Text('Home')),
  );

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  group('overlay', () {
    testWidgets('is the overlay of the navigator the observer is attached to', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(navigatorKey: navigatorKey));

      expect(observer.overlay, isNotNull);
      expect(observer.overlay, same(navigatorKey.currentState!.overlay));
    });

    testWidgets('stays the same through push, replace, remove and pop', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(navigatorKey: navigatorKey));
      final NavigatorState navigator = navigatorKey.currentState!;
      final OverlayState? overlay = observer.overlay;

      MaterialPageRoute<void> page(String text) => MaterialPageRoute<void>(builder: (_) => Scaffold(body: Text(text)));

      final MaterialPageRoute<void> second = page('Second');
      unawaited(navigator.push(second));
      await tester.pumpAndSettle();
      expect(observer.overlay, same(overlay));

      unawaited(navigator.pushReplacement(page('Replaced')));
      await tester.pumpAndSettle();
      expect(find.text('Replaced'), findsOneWidget);
      expect(observer.overlay, same(overlay));

      final MaterialPageRoute<void> toRemove = page('To remove');
      unawaited(navigator.push(toRemove));
      unawaited(navigator.push(page('Top')));
      await tester.pumpAndSettle();
      navigator.removeRoute(toRemove);
      await tester.pumpAndSettle();
      expect(observer.overlay, same(overlay));

      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('Replaced'), findsOneWidget);
      expect(observer.overlay, same(overlay));
    });

    testWidgets('is null once the navigator is gone, and follows a new navigator', (WidgetTester tester) async {
      await tester.pumpWidget(app());
      final OverlayState? first = observer.overlay;
      expect(first, isNotNull);

      await tester.pumpWidget(const SizedBox());
      expect(observer.overlay, isNull, reason: 'a destroyed overlay must not be handed out');

      await tester.pumpWidget(app(navigatorKey: GlobalKey<NavigatorState>()));
      expect(observer.overlay, isNotNull);
      expect(observer.overlay, isNot(same(first)));
    });

    testWidgets('is null when the observer is not attached to any navigator', (WidgetTester tester) async {
      await tester.pumpWidget(app(withObserver: false));

      expect(observer.overlay, isNull);
    });
  });

  group('showing bars through the observer', () {
    testWidgets('a bar is shown in the navigator overlay when there is no scope', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(app());

      FluentBar.show<void>(message: 'Via observer', isPersistent: true);
      await tester.pump();

      expect(find.text('Via observer'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('a bar requested before the app is built is shown after the first route is pushed', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());

      FluentBar.show<void>(message: 'Early', isPersistent: true);
      expect(FluentBar.mainQueueLength, 1);

      await tester.pumpWidget(app());
      await tester.pump();

      expect(FluentBar.mainQueueLength, 0);
      expect(find.text('Early'), findsOneWidget);
      await cleanup(tester);
    });

    testWidgets('the scope overlay has priority over the navigator overlay', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: <NavigatorObserver>[observer],
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: Text('Home')),
        ),
      );
      await tester.pump();

      FluentBar.show<void>(message: 'In scope', isPersistent: true);
      await tester.pump();

      expect(find.text('In scope'), findsOneWidget);
      expect(find.descendant(of: find.byType(Navigator), matching: find.text('In scope')), findsNothing);
      await cleanup(tester);
    });
  });
}
