import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _OwnCloseColorTheme extends FluentBarTheme {
  const _OwnCloseColorTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => const BoxDecoration(color: Color(0xFF222222));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  Color? closeIconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const Color(0xFF00FF00);
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  const Color red = Color(0xFFFF0000);
  const Color blue = Color(0xFF0000FF);

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero), Widget home = const Scaffold(body: SizedBox())}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: home,
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> wait(WidgetTester tester, int seconds) async {
    await tester.pump(Duration(seconds: seconds));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  FluentBarItem<void> job() => FluentBar.info<void>('Downloading').withId('job').withDuration(const Duration(seconds: 1)).withLinearProgress(value: 0.2);

  group('a failed bar that waits for an answer', () {
    testWidgets('keeps waiting when it fails in the queue and is shown later', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('Occupant').withId('occupant').persistent().show();
      final FluentBarEntry<void> entry = job().show()!;
      await settle(tester);
      expect(entry.controller.stateNotifier.value.isQueued, isTrue);

      entry.failProgress(message: 'Failed', retryLabel: 'Retry', onRetry: () {});
      FluentBar.close('occupant');
      await settle(tester);
      expect(find.text('Retry'), findsOneWidget);

      await wait(tester, 5);
      expect(FluentBar.find('job'), same(entry));

      await cleanup(tester);
    });

    testWidgets('is released by a new progress, a new button or duration and a new show, not by a new text, look or behavior', (WidgetTester tester) async {
      Future<bool> staysAfter(void Function(FluentBarEntry<void> entry) change) async {
        await boot(tester);
        final FluentBarEntry<void> entry = job().show()!;
        await settle(tester);
        entry.failProgress(message: 'Failed', retryLabel: 'Retry', onRetry: () {});
        await settle(tester);

        change(entry);
        await wait(tester, 8);
        final bool stays = FluentBar.find('job') != null;
        await cleanup(tester);
        return stays;
      }

      expect(await staysAfter((FluentBarEntry<void> e) => e.update(message: 'Still failed')), isTrue);
      expect(await staysAfter((FluentBarEntry<void> e) => e.patchAppearance((FluentBarAppearance<void> a) => a.copyWith(backgroundColor: Colors.teal))), isTrue);
      expect(await staysAfter((FluentBarEntry<void> e) => e.patchBehavior((FluentBarBehavior b) => b.copyWith(pauseOnTouch: false))), isTrue);
      expect(await staysAfter((FluentBarEntry<void> e) => e.controller.setLoading(isLoading: false)), isTrue);

      expect(await staysAfter((FluentBarEntry<void> e) => e.removeAction()), isFalse);
      expect(await staysAfter((FluentBarEntry<void> e) => e.controller.updateDuration(const Duration(seconds: 1))), isFalse);
      expect(await staysAfter((FluentBarEntry<void> e) => FluentBar.info<void>('Shown again').withId('job').withDuration(const Duration(seconds: 1)).show()), isFalse);
      expect(await staysAfter((FluentBarEntry<void> e) => e.completeProgress(message: 'Done after all')), isFalse);
    });

    testWidgets('loses the Retry button when the progress goes on without a tap', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = job().show()!;
      await settle(tester);
      entry.failProgress(message: 'Failed', retryLabel: 'Retry', onRetry: () {});
      await settle(tester);

      entry.updateValue(0.5);
      await settle(tester);

      expect(find.text('Retry'), findsNothing);
      expect(entry.item.actions, isNull);
      expect(entry.item.progressState, const FluentBarProgressState.value(0.5));

      await cleanup(tester);
    });

    testWidgets('reports one failure once, and a cancel after it changes nothing', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      void record(FluentBarAnalyticsPayload payload) => events.add(payload.event);
      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      final FluentBarEntry<void> entry = job().show()!;
      await settle(tester);
      entry.failProgress(message: 'Failed', retryLabel: 'Retry', onRetry: () {});
      entry.failProgress(message: 'Failed again');
      entry.cancelProgress(fallbackMessage: 'Cancelled');
      await settle(tester);

      expect(events.where((FluentBarAnalyticsEvent e) => e == FluentBarAnalyticsEvent.progressFailed), hasLength(1));
      expect(events, isNot(contains(FluentBarAnalyticsEvent.progressCanceled)));
      expect(entry.item.message, 'Failed');
      expect(find.text('Retry'), findsOneWidget);
      expect(entry.internalController.progressOutcome, FluentBarProgressOutcome.failed);

      entry.cancelProgress(dismiss: true);
      await settle(tester);
      expect(FluentBar.find('job'), isNull);

      await cleanup(tester);
    });

    testWidgets('has nothing planned in its metrics, and a tap on Retry reports no pause', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      FluentBarMetrics? metrics;
      void record(FluentBarAnalyticsPayload payload) {
        events.add(payload.event);
        metrics = payload.metrics ?? metrics;
      }

      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      final FluentBarEntry<void> held = job().show()!;
      await settle(tester);
      held.failProgress(message: 'Failed', isPersistent: true);
      await wait(tester, 5);
      held.close();
      await settle(tester);
      expect(metrics!.plannedDuration, isNull);

      events.clear();
      late FluentBarEntry<void> entry;
      entry = job().show()!;
      await settle(tester);
      entry.failProgress(message: 'Failed', retryLabel: 'Retry', onRetry: () => job().show());
      await settle(tester);
      await tester.tap(find.text('Retry'));
      await settle(tester);

      expect(events, contains(FluentBarAnalyticsEvent.actionTapped));
      expect(events, isNot(contains(FluentBarAnalyticsEvent.paused)));
      expect(entry.item.progressState, isNotNull);

      await cleanup(tester);
    });

    testWidgets('a double tap on Retry does not reach the Cancel button that takes its place', (WidgetTester tester) async {
      await boot(tester);
      int cancels = 0;
      FluentBarItem<void> attempt() => job().withCancelButton('Cancel', onCancel: () => cancels++, canceledMessage: 'Cancelled');

      final FluentBarEntry<void> entry = attempt().show()!;
      await settle(tester);
      entry.failProgress(message: 'Failed', retryLabel: 'Retry', onRetry: () => attempt().show());
      await settle(tester);

      final Offset where = tester.getCenter(find.text('Retry'));
      await tester.tapAt(where);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.text('Cancel')));
      await settle(tester);

      expect(cancels, 0);
      expect(entry.item.progressState, isNotNull);

      await cleanup(tester);
    });
  });

  group('guard against a double tap', () {
    testWidgets('a button whose widget is built again on every update is still the same button', (WidgetTester tester) async {
      await boot(tester);
      int opened = 0;
      FluentBarItem<void> draft() => FluentBar.info<void>('Draft')
          .withId('draft')
          .persistent()
          .copyWith(
            actions: FluentBarActions<void>(child: const Text('Open'), closeOnAction: false, onPressed: (_, _) => opened++),
          );

      draft().show();
      await settle(tester);
      await tester.tap(find.text('Open'));
      await tester.pump();
      draft().show();
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(opened, 1);

      await cleanup(tester);
    });
  });

  group('close button color', () {
    testWidgets('a color chosen earlier survives a later copyWith of the message style', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarTheme theme = FluentBarTheme.material
          .copyWith(closeIconColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => red)
          .copyWith(messageStyle: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const TextStyle(color: blue));

      FluentBar.info<void>('Colors').persistent().withTheme(theme).withCloseButton().show();
      await settle(tester);
      expect(IconTheme.of(tester.element(find.byIcon(Icons.close_rounded))).color, red);

      await cleanup(tester);
    });

    testWidgets('a color of a theme class survives too, and the default follows the new message style', (WidgetTester tester) async {
      await boot(tester);
      TextStyle blueStyle(BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const TextStyle(color: blue);

      FluentBar.info<void>('Own').persistent().withId('a').withTheme(const _OwnCloseColorTheme().copyWith(messageStyle: blueStyle)).withCloseButton().show();
      await settle(tester);
      expect(IconTheme.of(tester.element(find.byIcon(Icons.close_rounded))).color, const Color(0xFF00FF00));

      FluentBar.dismissAndClear();
      await settle(tester);
      FluentBar.info<void>('Default').persistent().withId('b').withTheme(FluentBarTheme.material.copyWith(messageStyle: blueStyle)).withCloseButton().show();
      await settle(tester);
      expect(IconTheme.of(tester.element(find.byIcon(Icons.close_rounded))).color, blue.withValues(alpha: 0.7));

      await cleanup(tester);
    });
  });

  group('leaving action', () {
    testWidgets('stays inside the room it had and never covers the close button', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig());
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().withAction('Open the item', closeOnAction: false).withCloseButton().show()!;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Finder clip = find.ancestor(of: find.text('Open the item'), matching: find.byType(ClipRect)).first;
      expect(clip, findsOneWidget);

      entry.removeAction();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final Rect room = tester.getRect(find.ancestor(of: find.text('Open the item'), matching: find.byType(ClipRect)).first);
      expect(room.right, lessThanOrEqualTo(tester.getRect(find.byType(FluentBarCloseButton)).left + 0.5));
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('the slot answers a dry layout, as a parent may ask for one', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: FluentBarSwitcherSlot(isLeaving: false, textDirection: TextDirection.ltr, child: SizedBox(width: 40, height: 20)),
          ),
        ),
      );
      final RenderBox box = tester.renderObject<RenderBox>(find.byType(FluentBarSwitcherSlot));
      expect(box.getDryLayout(const BoxConstraints()), const Size(40, 20));

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: FluentBarSwitcherSlot(isLeaving: true, textDirection: TextDirection.ltr, child: SizedBox(width: 40, height: 20)),
          ),
        ),
      );
      expect(tester.renderObject<RenderBox>(find.byType(FluentBarSwitcherSlot)).getDryLayout(const BoxConstraints()), Size.zero);
    });
  });

  group('closing while a bar moves to another region', () {
    testWidgets('a new show with the same id is a new bar, and the first reason of the close stays', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig());
      FluentBarMetrics? metrics;
      FluentBar.info<void>('Bottom').persistent().atBottom().show();
      final FluentBarEntry<void> moving = FluentBar.info<void>('Top').withId('moving').persistent().atTop().onDismiss((_, FluentBarMetrics m) => metrics = m).show()!;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      moving.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
      await tester.pump(const Duration(milliseconds: 50));
      moving.controller.close(reason: FluentBarDismissReason.closeButton);
      moving.controller.close(reason: FluentBarDismissReason.tap);

      final FluentBarEntry<void>? again = FluentBar.info<void>('Top again').withId('moving').persistent().atTop().show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      expect(again, isNot(same(moving)));
      expect(FluentBar.find('moving'), same(again));
      expect(metrics!.dismissReason, FluentBarDismissReason.closeButton);

      await cleanup(tester);
    });
  });

  group('FluentBarOwner', () {
    testWidgets('an owner that goes together with the overlay leaves no timer and no bar behind', (WidgetTester tester) async {
      await boot(
        tester,
        config: const FluentBarConfig(),
        home: const FluentBarOwner(
          tag: 'screen',
          child: Scaffold(body: SizedBox()),
        ),
      );
      FluentBar.info<void>('Tagged').persistent().withTag('screen').show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(FluentBar.findByTag('screen'), isEmpty);
      expect(FluentBar.activeItems, isEmpty);
    });

    testWidgets('a bar shown in the frame of the dispose is not touched', (WidgetTester tester) async {
      final ValueNotifier<bool> showOwner = ValueNotifier<bool>(true);
      addTearDown(showOwner.dispose);
      await boot(
        tester,
        home: ValueListenableBuilder<bool>(
          valueListenable: showOwner,
          builder: (BuildContext context, bool show, _) => show
              ? const FluentBarOwner(
                  tag: 'screen',
                  child: Scaffold(body: SizedBox()),
                )
              : const Scaffold(body: SizedBox()),
        ),
      );

      showOwner.value = false;
      tester.binding.addPostFrameCallback((_) => FluentBar.info<void>('Late').persistent().withTag('screen').show());
      await settle(tester);
      await settle(tester);

      expect(FluentBar.findByTag('screen'), hasLength(1));

      await cleanup(tester);
    });
  });
}
