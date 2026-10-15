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

  Future<void> boot(WidgetTester tester, {FluentBarConfig? config}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
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

  Future<void> shown(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('setup', () {
    testWidgets('initialize, updateConfig and patchConfig reach the manager', (WidgetTester tester) async {
      manager.resetForTesting();

      FluentBar.initialize(config: const FluentBarConfig(maxQueueLength: 3));
      expect(FluentBar.currentConfig.maxQueueLength, 3);

      FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 4));
      expect(FluentBar.currentConfig.maxQueueLength, 4);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(maxQueueLength: c.maxQueueLength + 1));
      expect(FluentBar.currentConfig.maxQueueLength, 5);
      expect(FluentBar.configNotifier.value, FluentBar.currentConfig);
      await tester.pump();
    });
  });

  group('one-line calls', () {
    testWidgets('showInfo / showSuccess / showWarning / showError set the type and take the text first', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(enableMultiRegion: false));

      final List<FluentBarEntry<void>?> entries = <FluentBarEntry<void>?>[
        FluentBar.showInfo<void>('Info', isPersistent: true),
        FluentBar.showSuccess<void>('Success', isPersistent: true),
        FluentBar.showWarning<void>('Warning', isPersistent: true),
        FluentBar.showError<void>('Error', isPersistent: true),
      ];

      expect(entries.map((FluentBarEntry<void>? e) => e!.item.type), <FluentBarType>[FluentBarType.info, FluentBarType.success, FluentBarType.warning, FluentBarType.error]);
      expect(entries.map((FluentBarEntry<void>? e) => e!.item.message), <String>['Info', 'Success', 'Warning', 'Error']);
      await cleanup(tester);
    });

    testWidgets('every one-line call accepts the common parameters', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<int>? entry = FluentBar.showWarning<int>(
        'Low battery',
        title: 'Battery',
        id: 'battery',
        duration: const Duration(seconds: 9),
        payload: 15,
        options: const FluentBarOptions<int>(
          behavior: FluentBarBehavior(position: FluentBarPosition.bottom),
          meta: <String, dynamic>{'level': 15},
        ),
      );

      expect(entry!.item.title, 'Battery');
      expect(entry.item.id, 'battery');
      expect(entry.item.duration, const Duration(seconds: 9));
      expect(entry.item.payload, 15);
      expect(entry.item.meta, <String, dynamic>{'level': 15});
      expect(FluentBar.bottomActiveItem, same(entry));
      await cleanup(tester);
    });

    testWidgets('showCustom uses a user-defined type', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarType promo = FluentBarType.info.copyWith(duration: const Duration(seconds: 12), position: FluentBarPosition.bottom);

      final FluentBarEntry<void>? entry = FluentBar.showCustom<void>(promo, 'Sale', title: 'Promo');

      expect(entry!.item.type, same(promo));
      expect(entry.item.title, 'Promo');
      expect(FluentBar.bottomActiveItem, same(entry), reason: 'the position comes from the type');
      expect(entry.controller.totalDurationNotifier.value, const Duration(seconds: 12));
      await cleanup(tester);
    });
  });

  group('full calls', () {
    testWidgets('show() passes every option to the item', (WidgetTester tester) async {
      await boot(tester);
      void tap(String? payload) {}

      final FluentBarEntry<String>? entry = FluentBar.show<String>(
        message: 'Message',
        type: FluentBarType.success,
        title: 'Title',
        id: 'id',
        payload: 'payload',
        isPersistent: true,
        options: FluentBarOptions<String>(
          meta: const <String, dynamic>{'k': 1},
          behavior: const FluentBarBehavior(priority: FluentBarPriority.high),
          actions: const FluentBarActions<String>(label: 'OK'),
          appearance: const FluentBarAppearance<String>(showIcon: false),
          callbacks: FluentBarCallbacks<String>(onTap: tap),
          progressState: const FluentBarProgressValue(0.5),
        ),
      );

      final FluentBarItem<String> item = entry!.item;
      expect(item.type, FluentBarType.success);
      expect(item.title, 'Title');
      expect(item.id, 'id');
      expect(item.payload, 'payload');
      expect(item.isPersistent, isTrue);
      expect(item.meta, <String, dynamic>{'k': 1});
      expect(item.behavior.priority, FluentBarPriority.high);
      expect(item.actions?.label, 'OK');
      expect(item.appearance.showIcon, isFalse);
      expect(item.callbacks?.onTap, tap);
      expect(item.progressState, const FluentBarProgressValue(0.5));
      await cleanup(tester);
    });

    testWidgets('show() defaults to an info bar; showItem shows a ready item', (WidgetTester tester) async {
      await boot(tester);

      expect(FluentBar.show<void>(message: 'Plain', isPersistent: true)!.item.type, FluentBarType.info);

      final FluentBarItem<void> item = FluentBarItem<void>(
        type: FluentBarType.error,
        message: 'Ready item',
        isPersistent: true,
        behavior: const FluentBarBehavior(position: FluentBarPosition.bottom),
      );
      final FluentBarEntry<void>? entry = FluentBar.showItem<void>(item);
      await tester.pump();

      expect(entry!.item.message, 'Ready item');
      expect(find.text('Ready item'), findsOneWidget);
      await cleanup(tester);
    });
  });

  group('builders (nothing is shown until show())', () {
    testWidgets('info / success / warning / error / custom only build an item', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarItem<int> item = FluentBar.error<int>('Failed', title: 'Oops', id: 'e', duration: const Duration(seconds: 2), payload: 7);
      await tester.pump();

      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.allQueueLength, 0);
      expect(item.type, FluentBarType.error);
      expect(item.message, 'Failed');
      expect(item.title, 'Oops');
      expect(item.id, 'e');
      expect(item.duration, const Duration(seconds: 2));
      expect(item.payload, 7);

      expect(FluentBar.info<void>('i').type, FluentBarType.info);
      expect(FluentBar.success<void>('s').type, FluentBarType.success);
      expect(FluentBar.warning<void>('w').type, FluentBarType.warning);
      final FluentBarType own = FluentBarType.info.copyWith(showIcon: false);
      expect(FluentBar.custom<void>(own, 'c').type, same(own));
    });

    testWidgets('a builder chain ends with show() and the bar appears already configured', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.info<void>('Uploading').withTitle('Upload').withLinearProgress(value: 0.3, showText: true).atBottom().persistent().show();
      await tester.pump();

      expect(FluentBar.bottomActiveItem, same(entry));
      expect(find.text('Uploading'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(entry!.item.isPersistent, isTrue);
      await cleanup(tester);
    });

    testWidgets('a builder can be reused: every show() creates a separate bar', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarItem<void> template = FluentBar.success<void>('Saved').persistent();

      final FluentBarEntry<void>? top = template.show();
      final FluentBarEntry<void>? bottom = template.atBottom().show();

      expect(top, isNot(same(bottom)));
      expect(FluentBar.mainActiveItem, same(top));
      expect(FluentBar.bottomActiveItem, same(bottom));
      expect(template.behavior.position, isNull, reason: 'the template itself is not modified');
      await cleanup(tester);
    });

    testWidgets('force() at the end of a chain shows the bar out of turn', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.showInfo<void>('Active', isPersistent: true);

      final FluentBarEntry<void>? forced = FluentBar.error<void>('Urgent').persistent().force();

      expect(FluentBar.mainActiveItem, same(forced));
      await cleanup(tester);
    });
  });

  group('presets', () {
    testWidgets('snack: bottom, no icon, optional action that receives the payload', (WidgetTester tester) async {
      await boot(tester);
      String? undone;

      final FluentBarEntry<String>? entry = FluentBar.showSnack<String>(
        'Deleted',
        action: 'UNDO',
        payload: 'file.txt',
        duration: const Duration(seconds: 30),
        onAction: (FluentBarController<String> controller, String? payload) => undone = payload,
      );
      await shown(tester);

      expect(FluentBar.bottomActiveItem, same(entry));
      expect(entry!.item.appearance.showIcon, isFalse);
      expect(find.byType(Icon), findsNothing);
      expect(find.text('UNDO'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(undone, 'file.txt');
      expect(FluentBar.bottomActiveItem, isNull, reason: 'the action closes the snack');
    });

    testWidgets('snack without an action has no button; the type can be changed', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.showSnack<void>('No connection', type: FluentBarType.error, id: 'net');
      await tester.pump();

      expect(entry!.item.actions, isNull);
      expect(entry.item.type, FluentBarType.error);
      expect(entry.item.id, 'net');
      await cleanup(tester);
    });

    testWidgets('toast: short, compact, without an icon, and cannot be closed by hand', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.showToast<void>('Copied');
      await shown(tester);

      expect(FluentBar.bottomActiveItem, same(entry));
      expect(entry!.controller.totalDurationNotifier.value, const Duration(seconds: 2));
      expect(find.byType(Icon), findsNothing);
      expect(tester.getSize(find.byType(DefaultFluentBarWidget<void>)).width, lessThanOrEqualTo(320 + 32));

      await tester.tap(find.text('Copied'));
      await tester.drag(find.text('Copied'), const Offset(0, 300));
      await tester.pump();
      expect(FluentBar.bottomActiveItem, same(entry));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.bottomActiveItem, isNull);
    });

    testWidgets('toast can be placed elsewhere and given its own duration', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.showToast<void>('Centered', position: FluentBarPosition.center, duration: const Duration(seconds: 7), type: FluentBarType.success);

      expect(FluentBar.mainActiveItem, same(entry));
      expect(entry!.item.duration, const Duration(seconds: 7));
      expect(entry.item.type, FluentBarType.success);
      await cleanup(tester);
    });

    testWidgets('banner: stays at the top until its action or code closes it', (WidgetTester tester) async {
      await boot(tester);
      int retries = 0;

      final FluentBarEntry<void>? entry = FluentBar.showBanner<void>(
        'No connection',
        title: 'Offline',
        action: 'RETRY',
        type: FluentBarType.warning,
        onAction: (FluentBarController<void> controller, void payload) => retries++,
      );
      await shown(tester);

      expect(FluentBar.mainActiveItem, same(entry));
      expect(entry!.controller.totalDurationNotifier.value, isNull);
      await tester.pump(const Duration(hours: 1));
      await tester.tap(find.text('No connection'));
      await tester.drag(find.text('No connection'), const Offset(0, -300));
      await tester.pump();
      expect(FluentBar.mainActiveItem, same(entry), reason: 'neither time nor gestures close a banner');

      await tester.tap(find.text('RETRY'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(retries, 1);
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('loading: spins until completed, then closes by the usual timer', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.showLoading<void>('Saving…', title: 'Profile', id: 'save');
      await shown(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(minutes: 10));
      await tester.tap(find.text('Saving…'));
      await tester.pump();
      expect(FluentBar.mainActiveItem, same(entry), reason: 'a loading bar cannot be dismissed while it works');

      entry!.completeProgress(message: 'Saved', type: FluentBarType.success);
      await tester.pump();
      expect(entry.item.message, 'Saved');

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('loading can be linear and can end with a failure', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.showLoading<void>('Syncing', linear: true, type: FluentBarType.warning);
      await shown(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      entry!.failProgress(message: 'Sync failed');
      await tester.pump();
      expect(entry.item.type, FluentBarType.error);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await cleanup(tester);
    });

    testWidgets('a preset is a regular builder: it can be refined with a chain before showing', (WidgetTester tester) async {
      await boot(tester);

      final FluentBarEntry<void>? entry = FluentBar.snack<void>('Deleted').atTop().withBackground(Colors.indigo).withDuration(const Duration(seconds: 20)).show();
      await tester.pump();

      expect(FluentBar.mainActiveItem, same(entry));
      expect(entry!.item.appearance.backgroundColor, Colors.indigo);
      expect(entry.item.appearance.showIcon, isFalse, reason: 'what the preset set is kept');
      expect(entry.item.duration, const Duration(seconds: 20));
      await cleanup(tester);
    });

    testWidgets('preset builders do not show anything by themselves', (WidgetTester tester) async {
      await boot(tester);

      FluentBar.snack<void>('a');
      FluentBar.toast<void>('b');
      FluentBar.banner<void>('c');
      FluentBar.loading<void>('d');
      await tester.pump();

      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.allQueueLength, 0);
    });
  });

  group('managing bars', () {
    testWidgets('find and close work by id for both shown and queued bars', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? active = FluentBar.showInfo<void>('Active', id: 'active', isPersistent: true);
      final FluentBarEntry<void>? queued = FluentBar.showInfo<void>('Queued', id: 'queued', isPersistent: true);
      await shown(tester);

      expect(FluentBar.find('active'), same(active));
      expect(FluentBar.find('queued'), same(queued));
      expect(FluentBar.find('missing'), isNull);

      expect(FluentBar.close('queued'), isTrue);
      expect(FluentBar.mainQueueLength, 0);
      expect(FluentBar.find('queued'), isNull);

      expect(FluentBar.close('active', reason: FluentBarDismissReason.tap), isTrue);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);

      expect(FluentBar.close('active'), isFalse);
      expect(FluentBar.close('missing'), isFalse);
    });

    testWidgets('closeActive, closeAll and clearQueue', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.showInfo<void>('Top', isPersistent: true);
      FluentBar.showInfo<void>('Queued', isPersistent: true);
      FluentBar.snack<void>('Bottom').persistent().show();
      await tester.pump();

      await FluentBar.closeActive(skipAnimation: true);
      await tester.pump();
      expect(FluentBar.mainActiveItem?.item.message, 'Queued');
      expect(FluentBar.bottomActiveItem, isNull);

      FluentBar.showInfo<void>('Queued 2', isPersistent: true);
      await FluentBar.closeAll(reason: FluentBarDismissReason.timeout, skipAnimation: true);
      await tester.pump();
      expect(FluentBar.activeItems, isEmpty);
      expect(FluentBar.allQueueLength, 0);

      FluentBar.showInfo<void>('Again', isPersistent: true);
      FluentBar.dismissAndClear();
      await tester.pump();
      expect(FluentBar.activeItems, isEmpty);
    });

    testWidgets('forceItem, forceItemFromQueue and updateItemPriority', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.showInfo<void>('Active', isPersistent: true);
      FluentBar.showInfo<void>('A', id: 'a', isPersistent: true);
      FluentBar.showInfo<void>('B', id: 'b', isPersistent: true);

      FluentBar.updateItemPriority(id: 'b', newPriority: FluentBarPriority.critical);
      expect(FluentBar.mainQueue.map((FluentBarEntry<dynamic> e) => e.item.id), <String?>['b', 'a']);

      FluentBar.forceItemFromQueue(id: 'a');
      expect(FluentBar.mainActiveItem?.item.id, 'a');

      final FluentBarEntry<void> forced = FluentBar.forceItem<void>(FluentBar.error<void>('Forced').persistent());
      expect(FluentBar.mainQueue.first, same(forced), reason: 'the active bar is forced too, so the new one waits first in line');
      await cleanup(tester);
    });

    testWidgets('state getters and listenables reflect both queues', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? top = FluentBar.showInfo<void>('Top', isPersistent: true);
      final FluentBarEntry<void>? bottom = FluentBar.showSnack<void>('Bottom', duration: const Duration(minutes: 5));
      FluentBar.showInfo<void>('Top queued', isPersistent: true);
      FluentBar.showSnack<void>('Bottom queued 1');
      FluentBar.showSnack<void>('Bottom queued 2');

      expect(FluentBar.activeItems, <FluentBarEntry<dynamic>?>[top, bottom]);
      expect(FluentBar.mainActiveItem, same(top));
      expect(FluentBar.bottomActiveItem, same(bottom));
      expect(FluentBar.lastActiveItem, same(bottom));
      expect(FluentBar.mainQueue, hasLength(1));
      expect(FluentBar.bottomQueue, hasLength(2));
      expect(FluentBar.allQueue, hasLength(3));
      expect(FluentBar.mainQueueLength, 1);
      expect(FluentBar.bottomQueueLength, 2);
      expect(FluentBar.allQueueLength, 3);
      expect(FluentBar.mainQueueLengthNotifier.value, 1);
      expect(FluentBar.bottomQueueLengthNotifier.value, 2);
      expect(FluentBar.allQueueLengthNotifier.value, 3);
      await cleanup(tester);
    });

    testWidgets('analytics listeners and error handlers can be added and removed', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      void listener(FluentBarAnalyticsPayload payload) => events.add(payload.event);

      FluentBar.addAnalyticsListener(listener);
      FluentBar.showInfo<void>('One', isPersistent: true);
      FluentBar.removeAnalyticsListener(listener);
      FluentBar.showInfo<void>('Two', isPersistent: true);

      expect(events, <FluentBarAnalyticsEvent>[FluentBarAnalyticsEvent.requested, FluentBarAnalyticsEvent.shown]);

      FluentBar.initialize(config: const FluentBarConfig());
      expect(errors, hasLength(1), reason: 'the handler from setUp is registered');
      await cleanup(tester);
    });
  });
}
