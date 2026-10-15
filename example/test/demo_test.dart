import 'package:fluent_bar/fluent_bar.dart';
import 'package:fluent_bar_example/app/demo_index.dart';
import 'package:fluent_bar_example/widgets/demo_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(String initialRoute) => MaterialApp(builder: FluentBarScope.builder(), initialRoute: initialRoute, onGenerateRoute: DemoIndex.route, onGenerateInitialRoutes: DemoIndex.initialRoutes);

void main() {
  setUp(() {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(900, 3000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    FluentBar.dismissAndClear();
    await tester.pump(const Duration(seconds: 1));
  }

  group('index', () {
    test('codes are unique and belong to a screen', () {
      final Set<String> codes = <String>{};
      for (final DemoSectionInfo section in DemoIndex.sections) {
        expect(codes.add(section.code), isTrue, reason: 'duplicate code ${section.code}');
        expect(DemoIndex.screens.any((DemoScreenInfo screen) => screen.id == section.screenId), isTrue, reason: section.code);
      }
    });

    test('search looks through titles, codes and API names', () {
      expect(DemoIndex.search('duplicates').first.code, 'queue/duplicates');
      expect(DemoIndex.search('queue/jump').single.code, 'queue/jump');
      expect(DemoIndex.search('clearQueue').map((DemoSectionInfo s) => s.code), containsAll(<String>['start/closing', 'queue/clean-up']));
      expect(DemoIndex.search('handleAction').map((DemoSectionInfo s) => s.code), contains('builders/action-builder'));
      expect(DemoIndex.search('no such thing'), isEmpty);
      expect(DemoIndex.search('   '), isEmpty);
    });

    test('a route name gives the screen and the section', () {
      expect(DemoIndex.screenOf('/queue/duplicates')?.id, 'queue');
      expect(DemoIndex.sectionOf('/queue/duplicates'), 'queue/duplicates');
      expect(DemoIndex.sectionOf('/queue'), isNull);
      expect(DemoIndex.sectionOf('/queue/unknown'), isNull);
      expect(DemoIndex.screenOf('/unknown'), isNull);
    });
  });

  for (final DemoScreenInfo screen in DemoIndex.screens) {
    testWidgets('screen ${screen.id} builds and shows exactly the sections of the index', (WidgetTester tester) async {
      await tester.pumpWidget(_app('/${screen.id}'));
      await tester.pump(const Duration(seconds: 1));

      final Set<String> shown = tester.widgetList<DemoSection>(find.byType(DemoSection)).map((DemoSection s) => s.id).toSet();
      final Set<String> indexed = DemoIndex.sections.where((DemoSectionInfo s) => s.screenId == screen.id).map((DemoSectionInfo s) => s.code).toSet();

      expect(shown, indexed);
      await leave(tester);
    });
  }

  for (final String route in <String>['/', '/behavior', '/builders', '/overrides', '/progress', '/queue']) {
    testWidgets('$route fits a narrow phone without overflowing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(route));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      await leave(tester);
    });
  }

  testWidgets('a section link opens the screen on top of home', (WidgetTester tester) async {
    await tester.pumpWidget(_app('/queue/duplicates'));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Duplicates'), findsOneWidget);

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isTrue);
    await leave(tester);
  });

  testWidgets('search on the home screen leads to the section', (WidgetTester tester) async {
    await tester.pumpWidget(_app('/'));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'who wins');
    await tester.pump();
    expect(find.text('overrides/who-wins', findRichText: true), findsNothing);
    expect(find.textContaining('overrides/who-wins'), findsOneWidget);

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Who wins?'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.widgetWithText(AppBar, 'Overriding settings'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse, reason: 'the keyboard goes away when the search leads somewhere');

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.testTextInput.isVisible, isFalse, reason: 'and does not come back with the home screen');
    expect(FocusManager.instance.primaryFocus?.context?.widget, isNot(isA<EditableText>()));
    await leave(tester);
  });

  for (final String route in <String>['/overrides', '/builders', '/progress', '/behavior', '/themes', '/config', '/playground', '/queue', '/monitor']) {
    testWidgets('leaving $route after using it does not touch the locked tree of the screen below', (WidgetTester tester) async {
      await tester.pumpWidget(_app('/'));
      await tester.pump(const Duration(seconds: 1));

      final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      FluentBar.patchConfig(
        (FluentBarConfig config) => config.copyWith(defaultDuration: const Duration(seconds: 9), defaultTransitionBuilder: (BuildContext context, Animation<double> animation, Widget child) => child),
      );
      FluentBar.showInfo<void>('Top', isPersistent: true);
      FluentBar.info<void>('Bottom').persistent().atBottom().show();
      await tester.pump(const Duration(milliseconds: 500));

      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      FluentBar.updateConfig(const FluentBarConfig());
      await leave(tester);
    });
  }

  testWidgets('a tap outside the search field closes the keyboard', (WidgetTester tester) async {
    await tester.pumpWidget(_app('/'));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Explore'.toUpperCase()));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    await leave(tester);
  });

  testWidgets('the keyboard switch of the insets demo opens and hides the keyboard, leaving the screen hides it too', (WidgetTester tester) async {
    await tester.pumpWidget(_app('/behavior/insets'));
    await tester.pump(const Duration(seconds: 3));

    final Finder keyboardSwitch = find.descendant(of: find.widgetWithText(DemoSwitch, 'Show the keyboard'), matching: find.byType(Switch));
    await tester.ensureVisible(keyboardSwitch);
    await tester.pump();

    await tester.tap(keyboardSwitch);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.widget<Switch>(keyboardSwitch).value, isTrue);

    await tester.tap(keyboardSwitch);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.widget<Switch>(keyboardSwitch).value, isFalse);

    await tester.tap(keyboardSwitch);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.testTextInput.isVisible, isFalse);
    await leave(tester);
  });

  testWidgets('fail and retry: the download breaks, Retry starts it over on the same bar and it finishes', (WidgetTester tester) async {
    await tester.pumpWidget(_app('/progress/retry'));
    await tester.pump(const Duration(seconds: 3));

    final Finder start = find.text('Download that fails at 60%');
    await tester.ensureVisible(start);
    await tester.pump();
    await tester.tap(start);
    await tester.pump(const Duration(seconds: 1));
    final FluentBarEntry<dynamic> entry = FluentBar.find('retry_demo')!;
    expect(entry.item.actions?.label, 'Cancel');

    for (int i = 0; i < 50 && find.text('Retry').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Retry'), findsOneWidget);
    expect(entry.item.actions?.label, 'Retry');
    expect(entry.item.type.kind, FluentBarType.warning);

    await tester.pump(const Duration(seconds: 10));
    expect(FluentBar.find('retry_demo'), same(entry), reason: 'the failed bar waits for an answer');

    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(seconds: 1));
    expect(FluentBar.find('retry_demo'), same(entry));
    expect(entry.item.actions?.label, 'Cancel');

    for (int i = 0; i < 80 && entry.item.message != 'Map downloaded'; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(entry.item.message, 'Map downloaded');
    expect(entry.item.actions, isNull);

    await leave(tester);
  });

  testWidgets('who wins: the closest level that sets a value decides', (WidgetTester tester) async {
    await tester.pumpWidget(_app('/overrides/who-wins'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('decided by the config', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Show the bar'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(FluentBar.find('who_wins'), isNotNull);

    await tester.tap(find.text('8 s').at(1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('decided by its type', findRichText: true), findsOneWidget);
    expect(FluentBar.find('who_wins')!.item.type.duration, const Duration(seconds: 8));

    await tester.tap(find.text('2 s').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('decided by the bar', findRichText: true), findsOneWidget);
    expect(FluentBar.find('who_wins')!.item.duration, const Duration(seconds: 2));

    await tester.tap(find.text('not set').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('decided by its type', findRichText: true), findsOneWidget);

    final FluentBarConfig before = FluentBar.currentConfig;
    await tester.tap(find.text('Position'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('bottom').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(FluentBar.currentConfig.defaultPosition, FluentBarPosition.bottom);

    await leave(tester);
    expect(FluentBar.currentConfig.defaultPosition, before.defaultPosition, reason: 'the screen puts the config back');
  });
}
