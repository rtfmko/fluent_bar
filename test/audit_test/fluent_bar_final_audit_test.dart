import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });

  tearDown(() => FluentBar.removeErrorHandler(onError));

  Future<void> boot(WidgetTester tester, {Size? size}) async {
    manager.resetForTesting();
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('payload type of a bar that is shown again', () {
    test('dynamic, void and Object? are one type; a narrower type is a different one', () {
      final FluentBarItem<dynamic> untyped = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'm');
      final FluentBarItem<int> typed = FluentBarItem<int>(type: FluentBarType.info, message: 'm');

      expect(untyped.hasPayloadType<dynamic>(), isTrue);
      expect(untyped.hasPayloadType<void>(), isTrue);
      expect(untyped.hasPayloadType<Object?>(), isTrue);
      expect(untyped.hasPayloadType<int>(), isFalse);
      expect(typed.hasPayloadType<int>(), isTrue);
      expect(typed.hasPayloadType<num>(), isFalse);
      expect(typed.hasPayloadType<dynamic>(), isFalse);
    });

    testWidgets('an untyped bar re-shown with typed callbacks is not corrupted: the new bar is separate and a warning is reported', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<dynamic>? first = FluentBar.showInfo<dynamic>('Loading', id: 'order', isPersistent: true);
      await settle(tester);

      final List<int?> tapped = <int?>[];
      final FluentBarEntry<int>? second = FluentBar.success<int>('Shipped', payload: 5)
          .withId('order')
          .persistent()
          .atBottom()
          .withAction('Track', closeOnAction: false, onPressed: (FluentBarController<int> controller, int? payload) => tapped.add(payload))
          .onTap(tapped.add)
          .show();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(second, isNotNull);
      expect(second, isNot(same(first)));
      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);

      await tester.tap(find.text('Track'));
      await settle(tester);
      expect(tapped, <int?>[5]);

      expect(errors.single.type, FluentBarErrorType.payloadTypeMismatch);
      expect(errors.single.severity, FluentBarErrorSeverity.warning);
      expect(errors.single.error.toString(), contains('"order"'));

      await cleanup(tester);
    });

    testWidgets('void and dynamic bars with one id are still the same bar; allow reports nothing', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<dynamic>? first = FluentBar.showInfo<dynamic>('Loading', id: 'job', isPersistent: true);
      await settle(tester);

      final FluentBarEntry<void>? second = FluentBar.success<void>('Done').withId('job').onTap((_) {}).show();
      await settle(tester);
      expect(second, same(first));
      expect(find.text('Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(errors, isEmpty);

      FluentBar.info<int>('Other').withId('job').withDuplicatePolicy(FluentBarDuplicatePolicy.allow).show();
      await settle(tester);
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });

  group('builders inside the progress theme', () {
    testWidgets('changing only the label builder or the progress builder of a shown bar rebuilds it', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Upload').withId('p').withLinearProgress(value: 0.3, showText: true).show()!;
      await settle(tester);
      expect(find.text('30%'), findsOneWidget);

      FluentBarProgressTheme theme() => entry.item.appearance.progressTheme!;

      entry.controller.updateAppearance(entry.item.appearance.copyWith(progressTheme: theme().copyWith(labelBuilder: (FluentBarProgressState state) => 'three of ten')));
      await settle(tester);
      expect(find.text('three of ten'), findsOneWidget);

      entry.controller.updateAppearance(
        entry.item.appearance.copyWith(progressTheme: theme().copyWith(progressBuilder: (BuildContext context, ValueListenable<FluentBarProgressState?> notifier) => const Text('own indicator'))),
      );
      await settle(tester);
      expect(find.text('own indicator'), findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('config listeners learn about a label builder set in the config', (WidgetTester tester) async {
      await boot(tester);
      int notifications = 0;
      void listener() => notifications++;
      FluentBar.configNotifier.addListener(listener);

      String label(FluentBarProgressState state) => 'cfg';
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(labelBuilder: label)));
      expect(notifications, 1);
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(labelBuilder: label)));
      expect(notifications, 1);

      FluentBar.configNotifier.removeListener(listener);
      await cleanup(tester);
    });
  });

  group('withAction', () {
    testWidgets('a second call replaces the button together with its handler', (WidgetTester tester) async {
      await boot(tester);
      int undone = 0;

      final FluentBarItem<void> base = FluentBar.info<void>('Deleted').persistent().withAction('Undo', closeOnAction: false, onPressed: (_, _) => undone++);
      base.withId('ok').withAction('OK', closeOnAction: false).show();
      await settle(tester);

      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(undone, 0);
      expect(base.actions!.label, 'Undo');

      await cleanup(tester);
    });

    test('the look of the button survives, its content does not', () {
      const Widget loader = SizedBox(key: ValueKey<String>('loader'));
      final FluentBarItem<void> item = FluentBar.info<void>('m')
          .copyWith(
            actions: FluentBarActions<void>(
              label: 'Old',
              child: const Text('old child'),
              onPressed: (_, _) {},
              maxActionLines: 2,
              actionOverflow: TextOverflow.fade,
              throttleDuration: const Duration(seconds: 1),
              actionLoaderColor: Colors.red,
              actionLoadingWidget: loader,
            ),
          )
          .withAction('New', closeOnAction: false);

      final FluentBarActions<void> actions = item.actions!;
      expect(actions.label, 'New');
      expect(actions.onPressed, isNull);
      expect(actions.child, isNull);
      expect(actions.closeOnAction, isFalse);
      expect(actions.maxActionLines, 2);
      expect(actions.actionOverflow, TextOverflow.fade);
      expect(actions.throttleDuration, const Duration(seconds: 1));
      expect(actions.actionLoaderColor, Colors.red);
      expect(actions.actionLoadingWidget, same(loader));
    });
  });

  group('on-screen keyboard', () {
    testWidgets('a bottom bar stays above the keyboard and returns when it closes', (WidgetTester tester) async {
      await boot(tester, size: const Size(400, 800));
      FluentBar.snack<void>('Invalid e-mail').withId('snack').persistent().show();
      await settle(tester);
      final double resting = tester.getBottomLeft(find.text('Invalid e-mail')).dy;
      expect(resting, greaterThan(700));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await settle(tester);
      expect(tester.getBottomLeft(find.text('Invalid e-mail')).dy, lessThanOrEqualTo(500));
      expect(tester.getBottomLeft(find.text('Invalid e-mail')).dy, closeTo(resting - 300, 0.01));

      tester.view.viewInsets = FakeViewPadding.zero;
      await settle(tester);
      expect(tester.getBottomLeft(find.text('Invalid e-mail')).dy, resting);

      await cleanup(tester);
    });

    testWidgets('the keyboard and the bottom panel do not add up: the larger one wins; no safe area changes nothing', (WidgetTester tester) async {
      await boot(tester, size: const Size(400, 800));
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(bottomInset: 80));
      FluentBar.snack<void>('Bar').withId('snack').persistent().withoutSafeArea().show();
      await settle(tester);
      final double abovePanel = tester.getBottomLeft(find.text('Bar')).dy;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await settle(tester);
      expect(tester.getBottomLeft(find.text('Bar')).dy, closeTo(abovePanel - 220, 0.01));

      tester.view.viewInsets = const FakeViewPadding(bottom: 40);
      await settle(tester);
      expect(tester.getBottomLeft(find.text('Bar')).dy, abovePanel);

      await cleanup(tester);
    });

    testWidgets('a centered bar is centered in the visible area; a top bar and a position builder are untouched', (WidgetTester tester) async {
      await boot(tester, size: const Size(400, 800));
      FluentBar.info<void>('Centered').withId('c').persistent().atCenter().show();
      await settle(tester);
      expect(tester.getCenter(find.text('Centered')).dy, closeTo(400, 20));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await settle(tester);
      expect(tester.getCenter(find.text('Centered')).dy, closeTo(250, 20));
      FluentBar.dismissAndClear();
      await settle(tester);

      tester.view.viewInsets = FakeViewPadding.zero;
      await settle(tester);
      FluentBar.info<void>('Top').withId('t').persistent().show();
      FluentBar.show<void>(
        message: 'Placed',
        id: 'placed',
        isPersistent: true,
        options: FluentBarOptions<void>(
          behavior: FluentBarBehavior(
            position: FluentBarPosition.bottom,
            positionBuilder: (BuildContext context, Widget child) => Align(alignment: Alignment.bottomLeft, child: child),
          ),
        ),
      );
      await settle(tester);
      final double top = tester.getTopLeft(find.text('Top')).dy;
      final double placed = tester.getBottomLeft(find.text('Placed')).dy;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await settle(tester);
      expect(tester.getTopLeft(find.text('Top')).dy, top);
      expect(tester.getBottomLeft(find.text('Placed')).dy, placed);

      await cleanup(tester);
    });
  });

  group('nowhere to show bars', () {
    testWidgets('an app without a scope, an observer or a navigator key gets one warning, and bars appear once a scope is there', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pump();
      errors.clear();

      FluentBar.showInfo<void>('First', id: 'first');
      FluentBar.showInfo<void>('Second', id: 'second');
      await settle(tester);
      FluentBar.showInfo<void>('Third', id: 'third');
      await settle(tester);

      expect(find.text('First'), findsNothing);
      expect(FluentBar.allQueueLength, 3);
      expect(errors.single.type, FluentBarErrorType.overlay);
      expect(errors.single.severity, FluentBarErrorSeverity.warning);
      expect(errors.single.error.toString(), contains('FluentBarScope'));

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await settle(tester);
      expect(find.text('First'), findsOneWidget);
      expect(errors, hasLength(1));

      await cleanup(tester);
    });

    testWidgets('a correctly set up app reports nothing, even for a bar requested before the first frame', (WidgetTester tester) async {
      manager.resetForTesting();
      FluentBar.showInfo<void>('Early', id: 'early');
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await settle(tester);

      expect(find.text('Early'), findsOneWidget);
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });

  group('the overlay is destroyed under a shown bar', () {
    Widget app(String key) => MaterialApp(
      key: ValueKey<String>(key),
      builder: FluentBarScope.builder(),
      home: const Scaffold(body: SizedBox()),
    );

    testWidgets('a persistent bar comes back in the new overlay instead of blocking its region forever', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(app('a'));
      await tester.pump();
      errors.clear();

      final List<String> log = <String>[];
      final FluentBarEntry<void> banner = FluentBar.banner<void>(
        'Offline',
        id: 'offline',
      ).onShow((_) => log.add('shown')).onDismiss((_, FluentBarMetrics m) => log.add('dismissed:${m.dismissReason.name}')).show()!;
      FluentBar.info<void>('Bottom').withId('bottom').persistent().atBottom().show();
      await settle(tester);
      expect(find.text('Offline'), findsOneWidget);

      await tester.pumpWidget(app('b'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
      expect(FluentBar.mainActiveItem, same(banner));
      expect(banner.controller.stateNotifier.value, FluentBarLifecycleState.visible);
      expect(log, <String>['shown', 'shown']);

      FluentBar.showInfo<void>('Next', id: 'next');
      await settle(tester);
      expect(find.text('Next'), findsNothing);
      banner.close();
      await settle(tester);
      expect(find.text('Next'), findsOneWidget);
      expect(log.last, 'dismissed:manual');
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('without a new overlay the bar waits in the queue and appears when one is there', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(app('a'));
      await tester.pump();

      final FluentBarEntry<void> timed = FluentBar.info<void>('Timed').withId('timed').withDuration(const Duration(seconds: 4)).show()!;
      await settle(tester);

      await tester.pumpWidget(
        const MaterialApp(
          key: ValueKey<String>('plain'),
          home: Scaffold(body: SizedBox()),
        ),
      );
      await settle(tester);
      expect(find.text('Timed'), findsNothing);
      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.mainQueue.single, same(timed));
      expect(timed.controller.stateNotifier.value, FluentBarLifecycleState.queued);

      await tester.pump(const Duration(seconds: 10));
      expect(timed.internalController.isDisposed, isFalse);

      await tester.pumpWidget(app('b'));
      await settle(tester);
      expect(find.text('Timed'), findsOneWidget);
      expect(FluentBar.mainActiveItem, same(timed));

      await tester.pump(const Duration(seconds: 4));
      await settle(tester);
      expect(find.text('Timed'), findsNothing);
      expect(FluentBar.activeItems, isEmpty);
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('a bar that is closed normally is not brought back', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Bye').withId('bye').persistent().show()!;
      await settle(tester);

      entry.close();
      await settle(tester);
      FluentBar.dismissAndClear();
      await settle(tester);

      expect(find.text('Bye'), findsNothing);
      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.allQueueLength, 0);
      expect(entry.internalController.isDisposed, isTrue);

      await cleanup(tester);
    });
  });

  group('loading', () {
    test('withGestures changes the two gesture flags (also to "not set") and keeps every other field', () {
      Widget place(BuildContext context, Widget child) => child;
      final FluentBarBehavior full = FluentBarBehavior(
        isForce: true,
        isSwipeEnabled: true,
        useSafeArea: false,
        dismissOnTap: true,
        pauseOnTouch: false,
        priority: FluentBarPriority.high,
        position: FluentBarPosition.left,
        dismissDirection: DismissDirection.horizontal,
        duplicatePolicy: FluentBarDuplicatePolicy.ignore,
        timeoutUpdateInterval: FluentBarUpdateRate.low,
        haptic: FluentBarHapticType.heavy,
        progressCompletedHaptic: FluentBarHapticType.light,
        relocationStrategy: FluentBarRelocationStrategy.ignore,
        positionBuilder: place,
        topInset: 11,
        bottomInset: 22,
      );

      final FluentBarBehavior changed = full.withGestures(isSwipeEnabled: null, dismissOnTap: false);
      expect(changed.isSwipeEnabled, isNull);
      expect(changed.dismissOnTap, isFalse);
      final FluentBarBehavior restored = changed.withGestures(isSwipeEnabled: true, dismissOnTap: true);
      expect(restored, full);
      expect(restored.positionBuilder, same(place));
    });
  });
}
