import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

class _QuietType extends FluentBarType {
  const _QuietType();

  @override
  String get name => 'quiet_type';

  @override
  FluentBarSemantics? get semantics => FluentBarSemantics.quiet;
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

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
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  bool isLive(WidgetTester tester, String text) {
    // ignore: deprecated_member_use
    return tester.getSemantics(find.text(text)).hasFlag(SemanticsFlag.isLiveRegion);
  }

  group('modes', () {
    testWidgets('by default a bar is a live region that carries its texts', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.info<void>('Profile saved').withTitle('Done').persistent().show();
      await settle(tester);

      expect(isLive(tester, 'Profile saved'), isTrue);
      expect(tester.getSemantics(find.text('Profile saved')).label, allOf(contains('Done'), contains('Profile saved')));

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('a quiet bar can be read but is not announced', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.info<void>('Copied').persistent().withSemantics(FluentBarSemantics.quiet).show();
      await settle(tester);

      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      expect(isLive(tester, 'Copied'), isFalse);

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('a hidden bar is drawn but does not exist for the screen reader', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.info<void>('Decoration').persistent().withAction('Open').withCloseButton().withSemantics(FluentBarSemantics.hidden).show();
      await settle(tester);

      expect(find.text('Decoration'), findsOneWidget);
      expect(find.bySemanticsLabel('Decoration'), findsNothing);
      expect(find.bySemanticsLabel('Open'), findsNothing);
      expect(find.bySemanticsLabel('Close'), findsNothing);

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('the bar decides, then its type, then the config', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(
        tester,
        config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, defaultSemantics: FluentBarSemantics.hidden),
      );

      FluentBar.info<void>('From the config').persistent().withId('bar').show();
      await settle(tester);
      expect(find.bySemanticsLabel('From the config'), findsNothing);

      FluentBar.custom<void>(const _QuietType(), 'From the type').persistent().withId('bar').show();
      await settle(tester);
      expect(find.bySemanticsLabel('From the type'), findsOneWidget);
      expect(isLive(tester, 'From the type'), isFalse);

      FluentBar.custom<void>(const _QuietType(), 'From the bar').persistent().withSemantics(FluentBarSemantics.announce).withId('bar').show();
      await settle(tester);
      expect(isLive(tester, 'From the bar'), isTrue);

      FluentBar.custom<void>(FluentBarType.info.copyWith(semantics: FluentBarSemantics.quiet), 'A copied type').persistent().withId('bar').show();
      await settle(tester);
      expect(find.bySemanticsLabel('A copied type'), findsOneWidget);
      expect(isLive(tester, 'A copied type'), isFalse);

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('changing the mode of a visible bar keeps the state of its content', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Stable').persistent().show()!;
      await settle(tester);
      final Element before = tester.element(find.text('Stable'));

      for (final FluentBarSemantics mode in <FluentBarSemantics>[FluentBarSemantics.hidden, FluentBarSemantics.quiet, FluentBarSemantics.announce]) {
        entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(semantics: mode));
        await settle(tester);
        expect(tester.element(find.text('Stable')), same(before), reason: mode.name);
      }
      expect(isLive(tester, 'Stable'), isTrue);

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('the dismiss action of the reader stays in every readable mode', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.info<void>('Swipe me').persistent().withSemantics(FluentBarSemantics.quiet).show();
      await settle(tester);

      expect(tester.getSemantics(find.text('Swipe me')).getSemanticsData().hasAction(SemanticsAction.dismiss), isTrue);

      handle.dispose();
      await cleanup(tester);
    });
  });

  group('progress', () {
    testWidgets('a changing percent is not a part of the announced text', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').withLinearProgress(value: 0.2, showText: true).show()!;
      await settle(tester);

      entry.updateValue(0.42);
      await settle(tester);
      await settle(tester);

      final SemanticsNode bar = tester.getSemantics(find.text('Uploading'));
      expect(isLive(tester, 'Uploading'), isTrue);
      expect(bar.label, isNot(contains('42')));
      expect(bar.value, isEmpty);

      final SemanticsNode progress = tester.getSemantics(find.text('42%'));
      expect(progress.id, isNot(bar.id), reason: 'the progress has its own node, so it can still be read');

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('the outcome is announced through the new message', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').withLinearProgress(value: 0.2, showText: true).show()!;
      await settle(tester);

      entry.completeProgress(message: 'Upload finished');
      await settle(tester);

      expect(isLive(tester, 'Upload finished'), isTrue);
      expect(tester.getSemantics(find.text('Upload finished')).label, contains('Upload finished'));

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('announceUpdates puts the percent back into the announced text', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(
        tester,
        config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, progressTheme: FluentBarProgressTheme(announceUpdates: true)),
      );
      FluentBar.info<void>('Uploading').withLinearProgress(value: 0.42, showText: true).show();
      await settle(tester);
      await settle(tester);

      expect(tester.getSemantics(find.text('42%')).id, tester.getSemantics(find.text('Uploading')).id);

      handle.dispose();
      await cleanup(tester);
    });
  });

  test('the setting takes part in equality and survives withGestures', () {
    const FluentBarBehavior quiet = FluentBarBehavior(semantics: FluentBarSemantics.quiet);

    expect(quiet, isNot(const FluentBarBehavior()));
    expect(quiet.hashCode, const FluentBarBehavior(semantics: FluentBarSemantics.quiet).hashCode);
    expect(quiet.withGestures(isSwipeEnabled: false, dismissOnTap: false).semantics, FluentBarSemantics.quiet);
    expect(const FluentBarConfig().defaultSemantics, FluentBarSemantics.announce);
    expect(const FluentBarConfig().copyWith(defaultSemantics: FluentBarSemantics.quiet), isNot(const FluentBarConfig()));
    expect(const FluentBarProgressTheme().announceUpdates, isFalse);
    expect(const FluentBarProgressTheme(announceUpdates: true), isNot(const FluentBarProgressTheme()));
  });
}
