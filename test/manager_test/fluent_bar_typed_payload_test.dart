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

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
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

  testWidgets('typed lifecycle callbacks and onTap receive the typed item and payload', (WidgetTester tester) async {
    await boot(tester);
    final List<String> calls = <String>[];

    FluentBar.show<int>(
      message: 'Typed',
      payload: 42,
      isPersistent: true,
      options: FluentBarOptions<int>(
        behavior: const FluentBarBehavior(dismissOnTap: true),
        callbacks: FluentBarCallbacks<int>(
          onShow: (FluentBarItem<int> item) => calls.add('show ${item.payload}'),
          onTap: (int? payload) => calls.add('tap $payload'),
          onDismiss: (FluentBarItem<int> item, FluentBarMetrics metrics) => calls.add('dismiss ${item.payload} ${metrics.dismissReason.name}'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Typed'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(calls, <String>['show 42', 'tap 42', 'dismiss 42 tap']);
    expect(errors, isEmpty);
  });

  testWidgets('typed progress callbacks are called', (WidgetTester tester) async {
    await boot(tester);
    final List<String> calls = <String>[];

    final FluentBarEntry<String>? entry = FluentBar.show<String>(
      message: 'Upload',
      payload: 'file',
      isPersistent: true,
      options: FluentBarOptions<String>(
        progressState: const FluentBarProgressValue(0.1),
        callbacks: FluentBarCallbacks<String>(
          onProgressCompleted: (FluentBarItem<String> item) => calls.add('completed ${item.payload}'),
          onProgressCanceled: (FluentBarItem<String> item) => calls.add('canceled ${item.payload}'),
        ),
      ),
    );
    await tester.pump();

    entry!.controller.updateProgress(const FluentBarProgressValue(1.0));
    entry.controller.cancelProgress();

    expect(calls, <String>['completed file', 'canceled file']);
    expect(errors, isEmpty);
    await cleanup(tester);
  });

  testWidgets('a typed action receives the typed controller and payload', (WidgetTester tester) async {
    await boot(tester);
    String? received;

    FluentBar.show<String>(
      message: 'With action',
      payload: 'data',
      isPersistent: true,
      options: FluentBarOptions<String>(
        actions: FluentBarActions<String>(label: 'UNDO', closeOnAction: false, onPressed: (FluentBarController<String> controller, String? payload) => received = payload),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('UNDO'));
    await tester.pump();

    expect(received, 'data');
    expect(errors, isEmpty);
    await cleanup(tester);
  });

  testWidgets('typed content and action builders are used', (WidgetTester tester) async {
    await boot(tester);

    FluentBar.show<int>(
      message: 'Hidden by builder',
      payload: 7,
      isPersistent: true,
      options: FluentBarOptions<int>(appearance: FluentBarAppearance<int>(builder: (BuildContext context, FluentBarEntry<int> entry) => Text('Custom ${entry.currentItem.payload}'))),
    );
    FluentBar.show<int>(
      message: 'With builder action',
      payload: 9,
      isPersistent: true,
      options: FluentBarOptions<int>(
        behavior: const FluentBarBehavior(position: FluentBarPosition.bottom),
        actions: FluentBarActions<int>(
          builder: (BuildContext context, FluentBarController<int> controller, FluentBarType type, FluentBarThemeMode mode) => Text('Action ${controller.itemNotifier.value.payload}'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Custom 7'), findsOneWidget);
    expect(find.text('Action 9'), findsOneWidget);
    expect(errors, isEmpty);
    await cleanup(tester);
  });

  testWidgets('bars with the same id but different payload types are not merged', (WidgetTester tester) async {
    await boot(tester);

    final FluentBarEntry<int>? first = FluentBar.show<int>(message: 'Int', id: 'same', payload: 1, isPersistent: true);
    final FluentBarEntry<String>? second = FluentBar.show<String>(message: 'String', id: 'same', payload: 'x', isPersistent: true);
    final FluentBarEntry<String>? third = FluentBar.show<String>(message: 'String 2', id: 'same', payload: 'y', isPersistent: true);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(first!.currentItem.message, 'Int');
    expect(second, isNotNull);
    expect(third, same(second));
    expect(second!.currentItem.payload, 'y');
    expect(FluentBar.mainQueueLength, 1);
    expect(errors.map((FluentBarException e) => (e.type, e.severity)), <(FluentBarErrorType, FluentBarErrorSeverity)>[(FluentBarErrorType.payloadTypeMismatch, FluentBarErrorSeverity.warning)]);
    await cleanup(tester);
  });
}
