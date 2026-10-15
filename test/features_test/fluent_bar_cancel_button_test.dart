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
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
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

  testWidgets('a tap waits for the task to stop, then cancels the progress and removes the button', (WidgetTester tester) async {
    await boot(tester);
    final Completer<void> stopping = Completer<void>();
    int cancels = 0;
    FluentBarMetrics? metrics;

    final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading the map')
        .withLinearProgress(value: 0.3)
        .withDuration(const Duration(seconds: 2))
        .withCancelButton(
          'Cancel',
          onCancel: () {
            cancels++;
            return stopping.future;
          },
          canceledMessage: 'Download cancelled',
          canceledType: FluentBarType.warning,
        )
        .onDismiss((_, FluentBarMetrics m) => metrics = m)
        .show()!;
    await settle(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(cancels, 1);
    expect(entry.controller.isActionExecutingNotifier.value, isTrue, reason: 'the button shows a loader while the task stops');
    expect(find.text('Downloading the map'), findsOneWidget);
    expect(FluentBar.activeItems, hasLength(1), reason: 'the bar is not closed by the tap');

    stopping.complete();
    await settle(tester);

    expect(find.text('Download cancelled'), findsOneWidget);
    expect(entry.item.type.kind, FluentBarType.warning);
    expect(entry.item.actions, isNull);
    expect(find.text('Cancel'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(FluentBar.activeItems, isEmpty, reason: 'a cancelled bar leaves by its usual timer');
    expect(metrics!.progressOutcome, FluentBarProgressOutcome.canceled);
    expect(metrics!.wasActionTapped, isTrue);

    await cleanup(tester);
  });

  testWidgets('a task that finishes while it is being stopped keeps its result', (WidgetTester tester) async {
    await boot(tester);
    final Completer<void> stopping = Completer<void>();
    FluentBarMetrics? metrics;

    final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading the map')
        .withLinearProgress(value: 0.9)
        .withDuration(const Duration(seconds: 1))
        .withCancelButton('Cancel', onCancel: () => stopping.future, canceledMessage: 'Download cancelled')
        .onDismiss((_, FluentBarMetrics m) => metrics = m)
        .show()!;
    await settle(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    entry.completeProgress(message: 'The map is ready');
    await tester.pump();

    stopping.complete();
    await settle(tester);

    expect(find.text('The map is ready'), findsOneWidget);
    expect(find.text('Download cancelled'), findsNothing);
    expect(entry.item.actions, isNull);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(metrics!.progressOutcome, FluentBarProgressOutcome.completed);

    await cleanup(tester);
  });

  testWidgets('without a callback the button just cancels', (WidgetTester tester) async {
    await boot(tester);
    final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
    void record(FluentBarAnalyticsPayload payload) => events.add(payload.event);
    manager.addAnalyticsListener(record);
    addTearDown(() => manager.removeAnalyticsListener(record));

    final FluentBarEntry<void> entry = FluentBar.loading<void>('Syncing').withCancelButton('Stop').show()!;
    await settle(tester);

    await tester.tap(find.text('Stop'));
    await settle(tester);

    expect(events, contains(FluentBarAnalyticsEvent.progressCanceled));
    expect(entry.item.actions, isNull);

    await cleanup(tester);
  });

  testWidgets('a task that fails to stop leaves the bar as it was and reports the error', (WidgetTester tester) async {
    await boot(tester);
    final List<FluentBarException> errors = <FluentBarException>[];
    void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
    FluentBar.addErrorHandler(onError);
    addTearDown(() => FluentBar.removeErrorHandler(onError));

    final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').withLinearProgress(value: 0.5).withCancelButton('Cancel', onCancel: () => throw StateError('cannot stop')).show()!;
    await settle(tester);

    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(errors.single.type, FluentBarErrorType.actionPressed);
    expect(tester.takeException(), isNull);
    expect(find.text('Cancel'), findsOneWidget);
    expect(entry.item.progressState, const FluentBarProgressState.value(0.5));
    expect(entry.controller.isActionExecutingNotifier.value, isFalse);

    await cleanup(tester);
  });

  testWidgets('a widget can replace the text, and the button takes the place of an earlier action', (WidgetTester tester) async {
    await boot(tester);
    int opened = 0;
    final FluentBarEntry<void> entry = FluentBar.info<void>(
      'Uploading',
    ).withLinearProgress(value: 0.5).withAction('Open', onPressed: (_, _) => opened++).withCancelButton('Cancel', child: const Icon(Icons.stop_circle_outlined)).show()!;
    await settle(tester);

    expect(find.text('Open'), findsNothing);
    expect(find.text('Cancel'), findsNothing);

    await tester.tap(find.byIcon(Icons.stop_circle_outlined));
    await settle(tester);

    expect(opened, 0);
    expect(entry.item.actions, isNull);

    await cleanup(tester);
  });

  group('the button goes away when the progress ends without a tap', () {
    final Map<String, void Function(FluentBarEntry<void> entry)> endings = <String, void Function(FluentBarEntry<void> entry)>{
      'the last value arrives': (FluentBarEntry<void> entry) => entry.updateValue(1, completedMessage: 'Done', completedType: FluentBarType.success),
      'completeProgress': (FluentBarEntry<void> entry) => entry.completeProgress(message: 'Done', type: FluentBarType.success),
      'failProgress': (FluentBarEntry<void> entry) => entry.failProgress(message: 'Failed'),
      'cancelProgress from code': (FluentBarEntry<void> entry) => entry.cancelProgress(fallbackMessage: 'Stopped'),
      'a re-show with the same id completes it': (FluentBarEntry<void> entry) => FluentBar.info<void>('Done').withId('job').withLinearProgress(value: 1).show(),
    };

    for (final MapEntry<String, void Function(FluentBarEntry<void> entry)> ending in endings.entries) {
      testWidgets(ending.key, (WidgetTester tester) async {
        await boot(tester);
        final FluentBarEntry<void> entry = FluentBar.info<void>('Working').withId('job').withLinearProgress(value: 0.4).withCancelButton('Cancel').show()!;
        await settle(tester);
        expect(find.text('Cancel'), findsOneWidget);

        ending.value(entry);
        await settle(tester);

        expect(entry.item.actions, isNull);
        expect(find.text('Cancel'), findsNothing);

        await cleanup(tester);
      });
    }

    testWidgets('an ordinary action stays, and a later withAction is ordinary again', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Working').withLinearProgress(value: 0.4).withCancelButton('Cancel').withAction('Open', closeOnAction: false).show()!;
      await settle(tester);

      entry.completeProgress(message: 'Done');
      await settle(tester);

      expect(find.text('Open'), findsOneWidget);
      expect(const FluentBarActions<void>(label: 'x').removeWhenProgressEnds, isFalse);
      expect(const FluentBarActions<void>(label: 'x', removeWhenProgressEnds: true), isNot(const FluentBarActions<void>(label: 'x')));

      await cleanup(tester);
    });
  });

  group('races with the task', () {
    testWidgets('after the tap the bar stops following the progress, by the entry and by a re-show', (WidgetTester tester) async {
      await boot(tester);
      final Completer<void> stopping = Completer<void>();
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withId('job').withLinearProgress(value: 0.3).withCancelButton('Cancel', onCancel: () => stopping.future).show()!;
      await settle(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      entry.updateValue(0.5);
      entry.controller.updateProgress(const FluentBarProgressState.value(0.6));
      FluentBar.info<void>('Downloading').withId('job').withLinearProgress(value: 0.7).show();
      await settle(tester);
      expect(entry.item.progressState, const FluentBarProgressState.value(0.3));

      stopping.complete();
      await settle(tester);
      expect(entry.item.progressState, isNull);

      await cleanup(tester);
    });

    testWidgets('updates that arrive after the cancellation do not bring the progress back, and the bar leaves', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>(
        'Downloading',
      ).withId('job').withDuration(const Duration(seconds: 1)).withLinearProgress(value: 0.3).withCancelButton('Cancel', canceledMessage: 'Cancelled').show()!;
      await settle(tester);

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      entry.updateValue(0.8);
      entry.updateValue(1);
      entry.updateBytes(5, 10);
      entry.completeProgress(message: 'Late result');
      await settle(tester);

      expect(entry.item.progressState, isNull);
      expect(find.text('Cancelled'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.activeItems, isEmpty, reason: 'a late update must not make the bar persistent again');

      await cleanup(tester);
    });

    testWidgets('showing the bar again with the same id starts over after a cancellation', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withId('job').persistent().withLinearProgress(value: 0.3).withCancelButton('Cancel', canceledMessage: 'Cancelled').show()!;
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      final FluentBarEntry<void>? again = FluentBar.info<void>('Downloading again').withId('job').persistent().withLinearProgress(value: 0.1).withCancelButton('Cancel').show();
      await settle(tester);
      expect(again, same(entry));

      entry.updateValue(0.5);
      await settle(tester);
      expect(entry.item.progressState, const FluentBarProgressState.value(0.5));
      expect(find.text('Cancel'), findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('a task that fails while it is being stopped keeps its failure', (WidgetTester tester) async {
      await boot(tester);
      final Completer<void> stopping = Completer<void>();
      FluentBarMetrics? metrics;
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading')
          .withDuration(const Duration(seconds: 1))
          .withLinearProgress(value: 0.3)
          .withCancelButton('Cancel', onCancel: () => stopping.future, canceledMessage: 'Cancelled')
          .onDismiss((_, FluentBarMetrics m) => metrics = m)
          .show()!;
      await settle(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      entry.failProgress(message: 'No connection');
      await tester.pump();
      stopping.complete();
      await settle(tester);

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Cancelled'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(metrics!.progressOutcome, FluentBarProgressOutcome.failed);

      await cleanup(tester);
    });

    testWidgets('when the task could not be stopped the bar follows the progress again', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').withLinearProgress(value: 0.5).withCancelButton('Cancel', onCancel: () => throw StateError('cannot stop')).show()!;
      await settle(tester);

      await tester.tap(find.text('Cancel'));
      await settle(tester);

      entry.updateValue(0.75);
      await settle(tester);
      expect(entry.item.progressState, const FluentBarProgressState.value(0.75));
      expect(find.text('Cancel'), findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('cancelProgress from code does not lock the bar: the app may restart the progress', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Uploading').persistent().withLinearProgress(value: 0.5).show()!;
      await settle(tester);

      entry.cancelProgress(fallbackMessage: 'Paused');
      entry.updateValue(0.2);
      await settle(tester);

      expect(entry.item.progressState, const FluentBarProgressState.value(0.2));

      await cleanup(tester);
    });
  });

  testWidgets('it lives next to the close button, which only hides the bar', (WidgetTester tester) async {
    await boot(tester);
    int cancels = 0;
    FluentBarMetrics? metrics;
    FluentBar.info<void>('Uploading').withLinearProgress(value: 0.5).withCancelButton('Cancel', onCancel: () => cancels++).withCloseButton().onDismiss((_, FluentBarMetrics m) => metrics = m).show();
    await settle(tester);

    await tester.tap(find.byType(FluentBarCloseButton));
    await settle(tester);

    expect(cancels, 0);
    expect(metrics!.progressOutcome, isNull);
    expect(metrics!.dismissReason, FluentBarDismissReason.closeButton);

    await cleanup(tester);
  });
}
