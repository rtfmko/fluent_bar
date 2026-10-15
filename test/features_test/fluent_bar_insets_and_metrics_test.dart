import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoweredType extends FluentBarType {
  const _LoweredType();

  @override
  String get name => 'lowered';

  @override
  double? get topInset => 120;

  @override
  double? get bottomInset => 90;
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  setUp(() => FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch());
  tearDown(() => FluentBarControllerImpl.stopwatchFactory = Stopwatch.new);

  Future<void> boot(WidgetTester tester, {FluentBarConfig? config, bool wrapPanels = false, bool showPanels = true}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: Scaffold(
          appBar: !showPanels ? null : (wrapPanels ? FluentBarTopInset(child: AppBar(title: const Text('App'))) : AppBar(title: const Text('App')) as PreferredSizeWidget),
          body: const SizedBox(),
          bottomNavigationBar: !showPanels ? null : (wrapPanels ? const FluentBarBottomInset(child: SizedBox(height: 70, child: Placeholder())) : const SizedBox(height: 70, child: Placeholder())),
        ),
      ),
    );
    await tester.pump();
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

  Rect barRect(WidgetTester tester, String message) => tester.getRect(find.ancestor(of: find.text(message), matching: find.byType(DefaultFluentBarWidget<void>)));

  FluentBarItem<void> bar(String message) => FluentBar.info<void>(message).withId(message).persistent();

  group('top inset', () {
    testWidgets('without any inset the bar starts at the very top', (WidgetTester tester) async {
      await boot(tester);
      bar('Top').show();
      await settle(tester);

      expect(barRect(tester, 'Top').top, 0);
      await cleanup(tester);
    });

    testWidgets('FluentBarTopInset lowers top bars below the app bar and frees them when it is gone', (WidgetTester tester) async {
      await boot(tester, wrapPanels: true);
      bar('Top').show();
      await settle(tester);

      expect(manager.topInsetNotifier.value, kToolbarHeight);
      expect(barRect(tester, 'Top').top, kToolbarHeight);

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await settle(tester);
      expect(manager.topInsetNotifier.value, 0);
      expect(barRect(tester, 'Top').top, 0);

      await cleanup(tester);
    });

    testWidgets('priority: the bar, then its type, then the config, then the measured app bar', (WidgetTester tester) async {
      await boot(tester, wrapPanels: true);

      final FluentBarEntry<void> entry = bar('Top').show()!;
      await settle(tester);
      expect(FluentBar.measuredTopInset.value, kToolbarHeight);
      expect(barRect(tester, 'Top').top, kToolbarHeight);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(topInset: 30));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 30);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(topInset: 100));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 100);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(topInset: 0));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 0);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(clearTopInset: true));
      await settle(tester);
      expect(barRect(tester, 'Top').top, kToolbarHeight);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(topInset: 100));
      await settle(tester);

      entry.controller.updateContent(type: const _LoweredType());
      await settle(tester);
      expect(barRect(tester, 'Top').top, 120);

      entry.controller.updateBehavior(behavior: entry.currentItem.behavior.copyWith(topInset: 0));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 0);

      await cleanup(tester);
    });

    testWidgets('withInsets sets the inset of one bar; the bottom follows the same rules', (WidgetTester tester) async {
      await boot(tester, wrapPanels: true);
      final double screenBottom = tester.getSize(find.byType(MaterialApp)).height;

      bar('Top').withInsets(top: 200).show();
      bar('Measured').atBottom().show();
      await settle(tester);

      expect(barRect(tester, 'Top').top, 200);
      expect(barRect(tester, 'Measured').bottom, screenBottom - 70);

      FluentBar.close('Measured');
      await settle(tester);
      bar('Typed').copyWith(type: const _LoweredType()).atBottom().show();
      await settle(tester);
      expect(barRect(tester, 'Typed').bottom, screenBottom - 90);

      FluentBar.close('Typed');
      await settle(tester);
      bar('Local').copyWith(type: const _LoweredType()).atBottom().withInsets(bottom: 10).show();
      await settle(tester);
      expect(barRect(tester, 'Local').bottom, screenBottom - 10);

      await cleanup(tester);
    });

    testWidgets('the safe area and the inset are independent: the larger one is used', (WidgetTester tester) async {
      await boot(tester, showPanels: false);
      tester.view.padding = const FakeViewPadding(top: 120);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final FluentBarEntry<void> entry = bar('Top').show()!;
      await settle(tester);
      expect(barRect(tester, 'Top').top, 40, reason: 'no inset: only the system padding');

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(topInset: 100));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 100, reason: 'the inset is larger than the system padding');

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(topInset: 10));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 40, reason: 'the system padding is larger than the inset');

      entry.controller.updateBehavior(behavior: entry.currentItem.behavior.copyWith(useSafeArea: false));
      await settle(tester);
      expect(barRect(tester, 'Top').top, 10);

      await cleanup(tester);
    });

    testWidgets('negative and NaN insets are treated as zero', (WidgetTester tester) async {
      await boot(tester, showPanels: false, config: const FluentBarConfig(topInset: -50));
      bar('Top').show();
      bar('Bottom').atBottom().withInsets(bottom: double.nan).show();
      await settle(tester);

      expect(barRect(tester, 'Top').top, 0);
      expect(barRect(tester, 'Bottom').bottom, tester.getSize(find.byType(MaterialApp)).height);
      await cleanup(tester);
    });

    testWidgets('side positions and bars with a position builder ignore the insets', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(topInset: 100, bottomInset: 100));
      bar('Center').atCenter().show();
      await settle(tester);

      final Rect rect = barRect(tester, 'Center');
      final Size screen = tester.getSize(find.byType(MaterialApp));
      expect(rect.center.dy, closeTo(screen.height / 2, 1));

      await cleanup(tester);
    });

    testWidgets('type insets survive copyWith and a broken getter falls back to "not set"', (WidgetTester tester) async {
      final FluentBarType copy = FluentBarType.info.copyWith(topInset: 40, bottomInset: 50);
      expect(copy.topInset, 40);
      expect(copy.bottomInset, 50);
      expect(FluentBarType.info.topInset, isNull);
      expect(FluentBarType.guard(const _LoweredType()).topInset, 120);
      expect(FluentBarType.guard(const _LoweredType()).bottomInset, 90);

      expect(const FluentBarConfig(topInset: 10), isNot(const FluentBarConfig()));
      expect(const FluentBarBehavior(topInset: 1, bottomInset: 2), const FluentBarBehavior(topInset: 1, bottomInset: 2));
      expect(const FluentBarBehavior(topInset: 1).hashCode, isNot(const FluentBarBehavior().hashCode));
    });
  });

  group('preset tag', () {
    test('library presets tag themselves, plain bars do not, a custom tag can be set', () {
      expect(FluentBar.snack<void>('m').preset, 'snack');
      expect(FluentBar.toast<void>('m').preset, 'toast');
      expect(FluentBar.banner<void>('m').preset, 'banner');
      expect(FluentBar.loading<void>('m').preset, 'loading');
      expect(FluentBar.info<void>('m').preset, isNull);

      final FluentBarItem<void> promo = FluentBar.info<void>('m').withPreset('promo');
      expect(promo.preset, 'promo');
      expect(promo.withTitle('t').preset, 'promo', reason: 'the tag survives further changes');
      expect(promo, isNot(promo.withPreset('other')));
      expect(promo.toString(), contains('preset: promo'));
    });
  });

  group('metrics', () {
    testWidgets('report queue time, pause time, place, preset and what the user did', (WidgetTester tester) async {
      await boot(tester, showPanels: false);
      FluentBarMetrics? metrics;

      bar('Blocker').show();
      FluentBar.snack<void>(
        'Snack',
        action: 'Undo',
        onAction: (_, _) {},
        duration: const Duration(seconds: 30),
      ).withId('snack').atTop().withAction('Undo', closeOnAction: false, onPressed: (_, _) {}).dismissOnTap(false).onTap((_) {}).onDismiss((_, FluentBarMetrics m) => metrics = m).show();
      await settle(tester);

      await tester.pump(const Duration(seconds: 2));
      FluentBar.close('Blocker');
      await settle(tester);
      await settle(tester);
      final FluentBarEntry<dynamic> entry = FluentBar.find('snack')!;
      expect(FluentBar.mainActiveItem, same(entry));

      await tester.tap(find.text('Snack'));
      await tester.tap(find.text('Undo'));
      await tester.pump(const Duration(milliseconds: 500));
      entry.pause();
      await tester.pump(const Duration(seconds: 2));
      entry.resume();

      entry.controller.close(reason: FluentBarDismissReason.swipe);
      await settle(tester);

      expect(metrics, isNotNull);
      expect(metrics!.dismissReason, FluentBarDismissReason.swipe);
      expect(metrics!.queuedDuration, greaterThanOrEqualTo(const Duration(seconds: 3)));
      expect(metrics!.pausedDuration, const Duration(seconds: 2));
      expect(metrics!.position, FluentBarPosition.top);
      expect(metrics!.wasForced, isFalse);
      expect(metrics!.preset, 'snack');
      expect(metrics!.interactions, <FluentBarInteraction, int>{FluentBarInteraction.tap: 1, FluentBarInteraction.action: 1, FluentBarInteraction.swipe: 1});
      expect(metrics!.wasActionTapped, isTrue, reason: 'the action was pressed although it did not close the bar');

      await cleanup(tester);
    });

    testWidgets('a bar shown at once and left alone has empty statistics; holding counts as "hold"', (WidgetTester tester) async {
      await boot(tester, showPanels: false);
      final List<FluentBarMetrics> all = <FluentBarMetrics>[];

      FluentBar.info<void>('Ignored').withId('ignored').withDuration(const Duration(seconds: 2)).forced().onDismiss((_, FluentBarMetrics m) => all.add(m)).show();
      await settle(tester);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);

      expect(all.single.queuedDuration, Duration.zero);
      expect(all.single.pausedDuration, Duration.zero);
      expect(all.single.wasUntouched, isTrue);
      expect(all.single.wasForced, isTrue);
      expect(all.single.timedOut, isTrue);

      FluentBar.info<void>('Held').withId('held').withDuration(const Duration(seconds: 10)).dismissOnTap(false).onDismiss((_, FluentBarMetrics m) => all.add(m)).show();
      await settle(tester);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Held')));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      FluentBar.close('held');
      await settle(tester);

      expect(all.last.interactions, <FluentBarInteraction, int>{FluentBarInteraction.hold: 1});
      expect(all.last.pausedDuration, const Duration(seconds: 1));

      await cleanup(tester);
    });
  });
}
