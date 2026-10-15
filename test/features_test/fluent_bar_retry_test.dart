import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(
          config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, defaultDuration: Duration(seconds: 2)),
        ),
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
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> wait(WidgetTester tester, int seconds) async {
    await tester.pump(Duration(seconds: seconds));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarEntry<void> download({VoidCallback? onCancel}) => FluentBar.info<void>(
    'Downloading the map',
  ).withId('map').withDuration(const Duration(seconds: 1)).withLinearProgress(value: 0.1, showText: true).withCancelButton('Cancel', onCancel: onCancel, canceledMessage: 'Download cancelled').show()!;

  group('failProgress with a Retry button', () {
    testWidgets('the Cancel button gives way to Retry, the bar takes the type and waits for an answer', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      void record(FluentBarAnalyticsPayload payload) => events.add(payload.event);
      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(message: 'Download failed', type: FluentBarType.warning, retryLabel: 'Retry', onRetry: () {});
      await settle(tester);

      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Download failed'), findsOneWidget);
      expect(entry.item.type.kind, FluentBarType.warning);
      expect(entry.item.progressState, isNull);
      expect(events.where((FluentBarAnalyticsEvent e) => e == FluentBarAnalyticsEvent.progressFailed), hasLength(1));

      await wait(tester, 10);
      expect(FluentBar.activeItems, hasLength(1), reason: 'a bar with a Retry button waits for the user');
      expect(entry.item.isPersistent, isNot(true), reason: 'the hold is a state of the bar, the item is not changed');

      await cleanup(tester);
    });

    testWidgets('the type is an error unless another one is given', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(retryLabel: 'Retry', onRetry: () {});
      await settle(tester);

      expect(entry.item.type.kind, FluentBarType.error);
      expect(entry.item.message, 'Downloading the map');

      await cleanup(tester);
    });

    testWidgets('a tap removes the button and starts over: the same bar shows the progress and Cancel again', (WidgetTester tester) async {
      await boot(tester);
      int retries = 0;
      late FluentBarEntry<void> entry;
      FluentBarEntry<void>? second;
      entry = download();
      await settle(tester);

      entry.failProgress(
        message: 'Download failed',
        type: FluentBarType.warning,
        retryLabel: 'Retry',
        onRetry: () {
          retries++;
          second = download();
        },
      );
      await settle(tester);

      await tester.tap(find.text('Retry'));
      await settle(tester);

      expect(retries, 1);
      expect(second, same(entry));
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Downloading the map'), findsOneWidget);
      expect(entry.item.type.kind, FluentBarType.info);
      expect(entry.item.progressState, const FluentBarProgressState.value(0.1));
      expect(entry.controller.isActionExecutingNotifier.value, isFalse);

      entry.updateValue(1, completedMessage: 'Map downloaded', completedType: FluentBarType.success);
      await settle(tester);
      expect(find.text('Cancel'), findsNothing);

      await wait(tester, 3);
      expect(FluentBar.activeItems, isEmpty, reason: 'after the retry the bar is an ordinary one again');

      await cleanup(tester);
    });

    testWidgets('the retried task can be cancelled while the callback of Retry is still running', (WidgetTester tester) async {
      await boot(tester);
      final Completer<void> wholeTask = Completer<void>();
      int cancels = 0;
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(
        retryLabel: 'Retry',
        onRetry: () {
          download(onCancel: () => cancels++);
          return wholeTask.future;
        },
      );
      await settle(tester);
      await tester.tap(find.text('Retry'));
      await settle(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 450)));

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(cancels, 1);
      expect(find.text('Download cancelled'), findsOneWidget);

      wholeTask.complete();
      await cleanup(tester);
    });

    testWidgets('a retry may also continue on the same entry: the bar lets go when the progress ends', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(
        message: 'Download failed',
        retryLabel: 'Retry',
        onRetry: () => entry.update(message: 'Trying again'),
      );
      await settle(tester);
      await tester.tap(find.text('Retry'));
      await settle(tester);

      entry.updateValue(0.5);
      await settle(tester);
      expect(entry.item.progressState, const FluentBarProgressState.value(0.5));

      entry.completeProgress(message: 'Map downloaded');
      await wait(tester, 3);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a callback that throws is reported and the bar leaves by its timer', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      final FluentBarEntry<void> entry = download();
      await settle(tester);
      entry.failProgress(retryLabel: 'Retry', onRetry: () => throw StateError('offline'));
      await settle(tester);

      await tester.tap(find.text('Retry'));
      await settle(tester);
      await settle(tester);

      expect(errors.single.type, FluentBarErrorType.actionPressed);
      expect(tester.takeException(), isNull);
      expect(find.text('Retry'), findsNothing);

      await wait(tester, 3);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });
  });

  group('isPersistent', () {
    testWidgets('false lets a bar with a Retry button leave by its timer', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(message: 'Download failed', retryLabel: 'Retry', onRetry: () {}, isPersistent: false);
      await settle(tester);
      expect(find.text('Retry'), findsOneWidget);

      await wait(tester, 3);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('true keeps a failed bar without a button until it is closed or updated', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(message: 'Download failed', isPersistent: true);
      await wait(tester, 10);
      expect(FluentBar.activeItems, hasLength(1));

      entry.controller.updateDuration(const Duration(seconds: 1), resetTimer: true);
      await wait(tester, 2);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('without the new arguments a failed bar leaves by its timer, as before', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(message: 'Download failed');
      await settle(tester);
      expect(entry.item.actions, isNull);

      await wait(tester, 3);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('removing the Retry button from code releases the bar', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = download();
      await settle(tester);

      entry.failProgress(message: 'Download failed', retryLabel: 'Retry', onRetry: () {});
      await wait(tester, 5);
      expect(FluentBar.activeItems, hasLength(1));

      entry.removeAction();
      await wait(tester, 3);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });
  });

  group('names for analytics', () {
    testWidgets('Cancel and Retry name themselves, an action takes the name it is given', (WidgetTester tester) async {
      await boot(tester);
      final Map<String, Object?> tapped = <String, Object?>{};
      void record(FluentBarAnalyticsPayload payload) {
        if (payload.event == FluentBarAnalyticsEvent.actionTapped) tapped[payload.item.actions?.label ?? '?'] = payload.toFlatMap()['action_name'];
      }

      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      final FluentBarEntry<void> entry = download();
      await settle(tester);
      expect(entry.item.actions!.analyticsName, 'cancel');

      entry.failProgress(message: 'Download failed', retryLabel: 'Retry', onRetry: () {});
      await settle(tester);
      expect(entry.item.actions!.analyticsName, 'retry');
      await tester.tap(find.text('Retry'));
      await settle(tester);

      FluentBar.info<void>('Order cancelled').persistent().withAction('Undo', closeOnAction: false, analyticsName: 'undo_order').atBottom().show();
      FluentBar.info<void>('Plain').persistent().withId('plain').withAction('Open', closeOnAction: false).show();
      await settle(tester);
      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(tapped['Retry'], 'retry');
      expect(tapped['Undo'], 'undo_order');
      expect(FluentBar.find('plain')!.item.actions!.analyticsName, isNull);
      expect(FluentBarAnalyticsPayload(event: FluentBarAnalyticsEvent.shown, item: FluentBar.find('plain')!.item).toFlatMap().containsKey('action_name'), isFalse);

      await cleanup(tester);
    });

    test('the name takes part in equality and survives copyWith', () {
      const FluentBarActions<void> undo = FluentBarActions<void>(label: 'Undo', analyticsName: 'undo');

      expect(undo, isNot(const FluentBarActions<void>(label: 'Undo')));
      expect(undo.copyWith(label: 'Annuler').analyticsName, 'undo');
      expect(undo.hashCode, const FluentBarActions<void>(label: 'Undo', analyticsName: 'undo').hashCode);
    });
  });

  group('retryLabel and onRetry go together', () {
    for (final bool hasLabel in <bool>[true, false]) {
      testWidgets(hasLabel ? 'a label without a callback fails the bar without a Retry button and warns' : 'a callback without a label fails the bar without a Retry button and warns', (
        WidgetTester tester,
      ) async {
        await boot(tester);
        final List<FluentBarException> errors = <FluentBarException>[];
        void record(FluentBarException e, StackTrace _) => errors.add(e);
        FluentBar.addErrorHandler(record);
        addTearDown(() => FluentBar.removeErrorHandler(record));
        final FluentBarEntry<void> entry = download();
        await settle(tester);

        expect(() => hasLabel ? entry.failProgress(message: 'Failed', retryLabel: 'Retry') : entry.failProgress(message: 'Failed', onRetry: () {}), returnsNormally);
        await settle(tester);

        expect(errors.single.type, FluentBarErrorType.invalidCall);
        expect(errors.single.severity.isWarning, isTrue);
        expect(find.text('Failed'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        expect(entry.item.actions, isNull);
        expect(entry.internalController.isAwaitingAnswer, isFalse, reason: 'without a button nothing waits for an answer');
        expect(tester.takeException(), isNull);

        await cleanup(tester);
      });
    }
  });

  group('guard against a double tap', () {
    testWidgets('a new button answers at once, right after the previous one was tapped', (WidgetTester tester) async {
      await boot(tester);
      int opened = 0;
      int saved = 0;
      final FluentBarEntry<void> entry = FluentBar.info<void>('Draft').persistent().withAction('Open', closeOnAction: false, onPressed: (_, _) => opened++).show()!;
      await settle(tester);

      await tester.tap(find.text('Open'));
      await tester.pump();
      entry.controller.updateActions(FluentBarActions<void>(label: 'Save', closeOnAction: false, onPressed: (_, _) => saved++));
      await settle(tester);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(opened, 1);
      expect(saved, 1);

      await cleanup(tester);
    });

    testWidgets('the same button still ignores a second tap that follows at once', (WidgetTester tester) async {
      await boot(tester);
      int opened = 0;
      final FluentBarEntry<void> entry = FluentBar.info<void>('Draft').persistent().withAction('Open', closeOnAction: false, onPressed: (_, _) => opened++).show()!;
      await settle(tester);

      await tester.tap(find.text('Open'));
      await tester.pump();
      entry.update(message: 'Draft, edited');
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(opened, 1);

      await cleanup(tester);
    });
  });

  testWidgets('a failure that arrives after a cancellation by the button adds no Retry', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = download();
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    entry.failProgress(message: 'Request aborted', retryLabel: 'Retry', onRetry: () {});
    await settle(tester);

    expect(find.text('Retry'), findsNothing);
    expect(find.text('Download cancelled'), findsOneWidget);

    await cleanup(tester);
  });
}
