import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DarkType extends FluentBarType {
  const _DarkType();

  @override
  String get name => 'dark_type';

  @override
  FluentBarThemeMode? get themeMode => FluentBarThemeMode.dark;
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester, {FluentBarConfig? config}) async {
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

  group('copyWith of an item follows one clearing rule', () {
    final FluentBarItem<String> item = FluentBar.info<String>('Message').withTitle('Title').withProgress(const FluentBarProgressValue(0.5)).withAction('Undo');

    test('null keeps the actions and the progress', () {
      final FluentBarItem<String> copy = item.copyWith(message: 'Other');

      expect(copy.actions, item.actions);
      expect(copy.progressState, item.progressState);
    });

    test('a value replaces them', () {
      final FluentBarItem<String> copy = item.copyWith(
        actions: const FluentBarActions<String>(label: 'Retry'),
        progressState: const FluentBarProgressValue(0.9),
      );

      expect(copy.actions?.label, 'Retry');
      expect(copy.progressState, const FluentBarProgressValue(0.9));
    });

    test('the clear flags remove them and win over a value', () {
      final FluentBarItem<String> copy = item.copyWith(actions: const FluentBarActions<String>(label: 'Retry'), clearActions: true, clearProgressState: true);

      expect(copy.actions, isNull);
      expect(copy.progressState, isNull);
    });
  });

  group('controller', () {
    testWidgets('updateContent removes the title with clearTitle and keeps it otherwise', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.show<void>(message: 'Message', title: 'Title', isPersistent: true)!;
      await tester.pump();

      entry.controller.updateContent(message: 'Other');
      expect(entry.item.title, 'Title');

      entry.update(clearTitle: true);
      expect(entry.item.title, isNull);
      expect(entry.item.message, 'Other');

      await cleanup(tester);
    });

    testWidgets('patchBehavior changes one setting and keeps the rest', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().swipeable(false).withPriority(FluentBarPriority.high).show()!;
      await tester.pump();

      entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(dismissOnTap: false));

      expect(entry.item.behavior.dismissOnTap, isFalse);
      expect(entry.item.behavior.isSwipeEnabled, isFalse);
      expect(entry.item.behavior.priority, FluentBarPriority.high);

      await cleanup(tester);
    });

    testWidgets('updateBehavior replaces the whole behavior', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().swipeable(false).show()!;
      await tester.pump();

      entry.controller.updateBehavior(behavior: const FluentBarBehavior(dismissOnTap: false));

      expect(entry.item.behavior.dismissOnTap, isFalse);
      expect(entry.item.behavior.isSwipeEnabled, isNull);

      await cleanup(tester);
    });

    testWidgets('patchAppearance changes one setting and keeps the rest', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().withoutIcon().show()!;
      await tester.pump();

      entry.patchAppearance((FluentBarAppearance<void> appearance) => appearance.copyWith(backgroundColor: Colors.teal));

      expect(entry.item.appearance.backgroundColor, Colors.teal);
      expect(entry.item.appearance.showIcon, isFalse);

      await cleanup(tester);
    });

    testWidgets('patchAppearance works through an untyped reference from find()', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<int>('Message').withId('typed').persistent().withPayload(7).show();
      await tester.pump();

      final FluentBarEntry<dynamic> found = FluentBar.find('typed')!;
      found.controller.patchAppearance((FluentBarAppearance<dynamic> appearance) => appearance.copyWith(backgroundColor: Colors.teal));
      found.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(dismissOnTap: false));

      expect(found.item.appearance.backgroundColor, Colors.teal);
      expect(found.item.appearance, isA<FluentBarAppearance<int>>());
      expect(found.item.behavior.dismissOnTap, isFalse);

      await cleanup(tester);
    });

    testWidgets('patchAppearance rejects an appearance of another payload type', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<int> entry = FluentBar.info<int>('Message').persistent().show()!;
      await tester.pump();

      final List<FluentBarException> errors = <FluentBarException>[];
      void record(FluentBarException e, StackTrace _) => errors.add(e);
      FluentBar.addErrorHandler(record);
      final FluentBarController<dynamic> untyped = entry.controller;
      expect(() => untyped.patchAppearance((FluentBarAppearance<dynamic> _) => const FluentBarAppearance<String>()), returnsNormally);
      await tester.pump();

      expect(errors.single.type, FluentBarErrorType.patchCallback);
      expect(errors.single.severity, FluentBarErrorSeverity.warning);
      expect(errors.single.error, isArgumentError);
      expect(entry.controller.stateNotifier.value.isOnScreen, isTrue);
      expect(find.text('Message'), findsOneWidget);
      FluentBar.removeErrorHandler(record);

      await cleanup(tester);
    });

    testWidgets('removeAction and makePersistent are the readable forms of the null calls', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').withAction('Undo').withDuration(const Duration(seconds: 2)).show()!;
      await tester.pump();

      entry.removeAction();
      entry.makePersistent();

      expect(entry.item.actions, isNull);
      expect(entry.item.isPersistent, isTrue);

      await tester.pump(const Duration(seconds: 5));
      expect(FluentBar.activeItems, contains(entry));

      await cleanup(tester);
    });
  });

  test('withoutTimeoutBar hides the countdown line explicitly', () {
    expect(FluentBar.info<void>('Message').withoutTimeoutBar().appearance.showTimeoutBar, isFalse);
    expect(FluentBar.info<void>('Message').withTimeoutBar().withoutTimeoutBar().appearance.showTimeoutBar, isFalse);
  });

  group('theme mode resolves bar, then type, then config', () {
    FluentBarThemeMode modeOf(FluentBarEntry<dynamic> entry) => entry.resolveThemeMode(manager.config);

    testWidgets('the config is the last resort', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultThemeMode: FluentBarThemeMode.light));
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().show()!;

      expect(modeOf(entry), FluentBarThemeMode.light);

      await cleanup(tester);
    });

    testWidgets('a type beats the config', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultThemeMode: FluentBarThemeMode.light));
      final FluentBarEntry<void> custom = FluentBar.custom<void>(const _DarkType(), 'Message').persistent().show()!;
      final FluentBarEntry<void> copied = FluentBar.custom<void>(FluentBarType.info.copyWith(themeMode: FluentBarThemeMode.dark), 'Other').persistent().atBottom().show()!;

      expect(modeOf(custom), FluentBarThemeMode.dark);
      expect(modeOf(copied), FluentBarThemeMode.dark);

      await cleanup(tester);
    });

    testWidgets('the bar beats its type', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultThemeMode: FluentBarThemeMode.system));
      final FluentBarEntry<void> entry = FluentBar.custom<void>(const _DarkType(), 'Message').persistent().light().show()!;

      expect(modeOf(entry), FluentBarThemeMode.light);

      await cleanup(tester);
    });
  });
}
