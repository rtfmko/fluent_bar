import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarAction & Actions Integration Tests', () {
    testWidgets('should render action using child and execute onPressed with item payload', (WidgetTester tester) async {
      final FluentBarItem<String> item = FluentBarItem<String>(
        type: FluentBarType.info,
        id: 'action_test_1',
        message: 'Message with action',
        payload: 'test_payload_data',
        actions: FluentBarActions<String>(
          closeOnAction: true,
          onPressed: (FluentBarController<String> controller, String? payload) => expect(payload, 'test_payload_data'),
          child: const Text('Action Button'),
        ),
      );
      final FluentBarEntry<String> entry = FluentBarEntry<String>(item: item);
      entry.internalController.changeState(FluentBarLifecycleState.visible);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarAction<String>(
              controller: entry.controller,
              onPressed: item.actions?.onPressed,
              closeOnAction: item.actions!.closeOnAction,
              loaderColor: Colors.white,
              child: item.actions!.child!,
            ),
          ),
        ),
      );

      expect(find.text('Action Button'), findsOneWidget);

      await tester.tap(find.text('Action Button'));
      await tester.pump();

      expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.dismissed);
    });

    testWidgets('should support custom builder inside FluentBarActions if provided', (WidgetTester tester) async {
      final FluentBarItem<int> item = FluentBarItem<int>(
        type: FluentBarType.info,
        id: 'action_test_builder',
        message: 'Builder action',
        payload: 42,
        actions: FluentBarActions<int>(
          builder: (BuildContext context, FluentBarController<int> controller, FluentBarType type, FluentBarThemeMode themeMode) => ElevatedButton(
            onPressed: () => controller.close(reason: FluentBarDismissReason.actionButton),
            child: const Text('Custom Builder Button'),
          ),
        ),
      );
      final FluentBarEntry<int> entry = FluentBarEntry<int>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: (BuildContext context) => item.actions!.builder!(context, entry.controller, FluentBarType.info, FluentBarThemeMode.light))),
        ),
      );

      expect(find.text('Custom Builder Button'), findsOneWidget);

      await tester.tap(find.text('Custom Builder Button'));
      await tester.pumpAndSettle();

      expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.dismissed);
    });

    testWidgets('should handle exception thrown by onPressed gracefully without crashing', (WidgetTester tester) async {
      final FluentBarItem<String> item = FluentBarItem<String>(
        type: FluentBarType.info,
        id: 'action_test_error',
        message: 'Message with error action',
        payload: 'error_payload',
        actions: FluentBarActions<String>(
          closeOnAction: true,
          onPressed: (FluentBarController<String> controller, String? payload) => throw Exception('Action callback crash'),
          child: const Text('Error Action Button'),
        ),
      );
      final FluentBarEntry<String> entry = FluentBarEntry<String>(item: item);
      entry.internalController.changeState(FluentBarLifecycleState.visible);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarAction<String>(
              controller: entry.controller,
              onPressed: item.actions?.onPressed,
              closeOnAction: item.actions!.closeOnAction,
              loaderColor: Colors.white,
              child: item.actions!.child!,
            ),
          ),
        ),
      );

      expect(find.text('Error Action Button'), findsOneWidget);

      await tester.tap(find.text('Error Action Button'));
      await tester.pump();

      expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.dismissed);
    });
  });
}
