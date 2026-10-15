import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Widget app(Widget home) => MaterialApp(
    builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
    home: Scaffold(body: home),
  );

  Future<void> boot(WidgetTester tester, {Widget home = const SizedBox()}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(home));
    await tester.pump();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  List<String> messages(Iterable<FluentBarEntry<dynamic>> entries) => entries.map((FluentBarEntry<dynamic> e) => e.item.message).toList();

  group('tags on a bar', () {
    test('chain calls add tags, the set cannot be changed from outside', () {
      final FluentBarItem<void> item = FluentBar.info<void>('Tagged').withTag('checkout').withTags(<String>['upload', 'checkout']).withTag('promo');

      expect(item.tags, <String>{'checkout', 'upload', 'promo'});
      expect(() => item.tags.add('x'), throwsUnsupportedError);
      expect(FluentBar.info<void>('Plain').tags, isEmpty);
    });

    test('tags take part in equality, and an empty set clears them', () {
      final FluentBarItem<void> item = FluentBar.info<void>('Same').withTags(<String>{'a', 'b'});

      expect(item, item.copyWith(tags: <String>{'b', 'a'}));
      expect(item.hashCode, item.copyWith(tags: <String>{'b', 'a'}).hashCode);
      expect(item, isNot(item.copyWith(tags: <String>{'a'})));
      expect(item.copyWith(message: 'Other').tags, <String>{'a', 'b'});
      expect(item.copyWith(tags: <String>{}).tags, isEmpty);
    });

    testWidgets('options carry tags into the full call', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(
        message: 'Full call',
        options: const FluentBarOptions<void>(tags: <String>{'promo'}),
      )!;

      expect(entry.item.tags, <String>{'promo'});
      expect(FluentBar.findByTag('promo'), <FluentBarEntry<dynamic>>[entry]);

      await cleanup(tester);
    });
  });

  group('closeTag', () {
    testWidgets('closes the shown bar and removes the queued ones, the rest stay', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('Checkout on screen').persistent().withTag('checkout').show();
      FluentBar.info<void>('Checkout queued').persistent().withTags(<String>{'checkout', 'promo'}).show();
      FluentBar.info<void>('Global queued').persistent().show();
      FluentBar.info<void>('Bottom untagged').persistent().atBottom().show();
      await settle(tester);

      expect(messages(FluentBar.findByTag('checkout')), <String>['Checkout on screen', 'Checkout queued']);
      expect(FluentBar.findByTag('nothing'), isEmpty);

      expect(FluentBar.closeTag('checkout'), 2);
      await settle(tester);

      expect(FluentBar.findByTag('checkout'), isEmpty);
      expect(find.text('Checkout queued'), findsNothing, reason: 'a removed bar never appears');
      expect(messages(FluentBar.activeItems), unorderedEquals(<String>['Global queued', 'Bottom untagged']));
      expect(FluentBar.closeTag('checkout'), 0);

      await cleanup(tester);
    });

    testWidgets('reports a close from code, with the tags in metrics and in the flat map', (WidgetTester tester) async {
      await boot(tester);
      final Map<String, FluentBarAnalyticsPayload> closed = <String, FluentBarAnalyticsPayload>{};
      void record(FluentBarAnalyticsPayload payload) {
        if (payload.event.hasMetrics) closed[payload.item.message] = payload;
      }

      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      FluentBar.info<void>('Shown').persistent().withTags(<String>['checkout', 'upload']).show();
      FluentBar.info<void>('Waiting').persistent().withTag('checkout').show();
      FluentBar.info<void>('No tags').persistent().atBottom().show();
      await settle(tester);

      FluentBar.closeTag('checkout');
      unawaited(FluentBar.closeActive());
      await settle(tester);

      final FluentBarMetrics shown = closed['Shown']!.metrics!;
      expect(shown.dismissReason, FluentBarDismissReason.manual);
      expect(shown.dismissReason.isByCode, isTrue);
      expect(shown.tags, <String>{'checkout', 'upload'});
      expect(shown.toMap()['tags'], <String>['checkout', 'upload']);
      expect(shown.toFlatMap()['tags'], 'checkout,upload');
      expect(closed['Shown']!.toFlatMap()['tags'], 'checkout,upload');

      expect(closed['Waiting']!.metrics!.wasVisible, isFalse);
      expect(closed['No tags']!.toFlatMap().containsKey('tags'), isFalse);
      expect(closed['No tags']!.metrics!.toMap().containsKey('tags'), isFalse);

      await cleanup(tester);
    });

    testWidgets('a tag gives no priority: a forced bar still takes the place', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('Checkout hint').persistent().withTag('checkout').show();
      await settle(tester);

      FluentBar.forceItem<void>(FluentBar.error<void>('Session expired').persistent());
      await settle(tester);

      expect(FluentBar.mainActiveItem!.item.message, 'Session expired');

      await cleanup(tester);
    });
  });

  group('FluentBarOwner', () {
    testWidgets('closes its bars, shown and queued, when it leaves the tree', (WidgetTester tester) async {
      await boot(
        tester,
        home: const FluentBarOwner(tag: 'checkout', child: Text('Checkout screen')),
      );
      FluentBar.info<void>('Card declined').persistent().withTag('checkout').show();
      FluentBar.info<void>('Promo applied').persistent().withTag('checkout').show();
      FluentBar.info<void>('No connection').persistent().atBottom().show();
      await settle(tester);
      expect(FluentBar.findByTag('checkout'), hasLength(2));

      await tester.pumpWidget(app(const Text('Another screen')));
      expect(tester.takeException(), isNull);
      await settle(tester);

      expect(FluentBar.findByTag('checkout'), isEmpty);
      expect(find.text('Promo applied'), findsNothing);
      expect(messages(FluentBar.activeItems), <String>['No connection']);

      await cleanup(tester);
    });

    testWidgets('a bar shown later with the tag of a gone screen is not touched', (WidgetTester tester) async {
      await boot(
        tester,
        home: const FluentBarOwner(tag: 'checkout', child: SizedBox()),
      );
      await tester.pumpWidget(app(const SizedBox()));
      await settle(tester);

      FluentBar.info<void>('Late').persistent().withTag('checkout').show();
      await settle(tester);

      expect(FluentBar.findByTag('checkout'), hasLength(1));

      await cleanup(tester);
    });

    testWidgets('with two owners of one tag the bars live until the last one is gone', (WidgetTester tester) async {
      Widget screens(int count) => Column(
        children: <Widget>[for (int i = 0; i < count; i++) FluentBarOwner(key: ValueKey<int>(i), tag: 'details', child: Text('Details $i'))],
      );

      await boot(tester, home: screens(2));
      FluentBar.info<void>('For details').persistent().withTag('details').show();
      await settle(tester);

      await tester.pumpWidget(app(screens(1)));
      await settle(tester);
      expect(FluentBar.findByTag('details'), hasLength(1));

      await tester.pumpWidget(app(screens(0)));
      await settle(tester);
      expect(FluentBar.findByTag('details'), isEmpty);

      await cleanup(tester);
    });

    testWidgets('changing the tag lets go of the old one', (WidgetTester tester) async {
      await boot(
        tester,
        home: const FluentBarOwner(tag: 'step_1', child: SizedBox()),
      );
      FluentBar.info<void>('First step').persistent().withTag('step_1').show();
      FluentBar.info<void>('Second step').persistent().withTag('step_2').atBottom().show();
      await settle(tester);

      await tester.pumpWidget(app(const FluentBarOwner(tag: 'step_2', child: SizedBox())));
      await settle(tester);
      expect(messages(FluentBar.activeItems), <String>['Second step']);

      await tester.pumpWidget(app(const SizedBox()));
      await settle(tester);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a route with an owner takes its bars away when it is popped', (WidgetTester tester) async {
      await boot(tester);
      final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const FluentBarOwner(
            tag: 'route',
            child: Scaffold(body: Text('Pushed')),
          ),
        ),
      );
      await settle(tester);

      FluentBar.info<void>('From the route').persistent().withTag('route').show();
      await settle(tester);

      navigator.pop();
      await settle(tester);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });
  });
}
