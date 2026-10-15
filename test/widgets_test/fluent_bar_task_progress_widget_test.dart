import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarTaskProgressWidget & FluentBarProgressState Tests', () {
    const Color testDefaultColor = Colors.blue;
    const Widget testSuccessIcon = Icon(Icons.check, key: Key('icon_check'), color: Colors.green);

    testWidgets('should handle indeterminate factory state correctly', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.indeterminate();
      const FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear, showText: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      expect(state.progress, isNull);
      expect(state.isCompleted, isFalse);
      expect(find.byKey(const ValueKey<String>('progress_loader')), findsOneWidget);

      final LinearProgressIndicator indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(indicator.value, isNull);
    });

    testWidgets('should handle value factory state correctly with circular style and text', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.value(0.65);
      const FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.circular, showText: true, size: 28.0, thickness: 3.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      expect(state.progress, equals(0.65));
      expect(state.isCompleted, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('should handle fraction factory state correctly with linear style and trackDecoration', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.fraction(3, 4);
      final FluentBarProgressTheme theme = FluentBarProgressTheme(
        style: FluentBarProgressStyle.linear,
        showText: true,
        thickness: 5.0,
        trackDecoration: BoxDecoration(color: Colors.grey.shade100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      expect(state.progress, equals(0.75));
      expect(state.isCompleted, isFalse);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(DecoratedBox), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should use custom labelBuilder when provided in theme', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.value(0.5);
      final FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear, showText: true, labelBuilder: (FluentBarProgressState s) => 'Custom Text Label');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      expect(find.text('Custom Text Label'), findsOneWidget);
    });

    testWidgets('should hide text if labelBuilder returns empty string', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.value(0.5);
      final FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear, showText: true, labelBuilder: (FluentBarProgressState s) => '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('should animate the indicator towards the value; a big jump takes longer than a small step', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.value(0.8);
      const FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear, showText: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      LinearProgressIndicator indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(indicator.value, equals(0.0));

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(indicator.value, greaterThan(0.0));
      expect(indicator.value, lessThan(0.8));

      await tester.pump(const Duration(milliseconds: 400));
      indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(indicator.value, equals(0.8));
    });
  });

  group('FluentBarTaskProgressWidget Success Icon Size Tests', () {
    const Color testDefaultColor = Colors.blue;
    const Widget testSuccessIcon = Icon(Icons.check, key: Key('icon_check'));

    testWidgets('should use custom theme.size for success icon when provided', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.value(1.0);
      const FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear, size: 36.0, showText: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final SizedBox sizedBox = tester.widget<SizedBox>(find.descendant(of: find.byKey(const ValueKey<String>('success_icon')), matching: find.byType(SizedBox)).first);

      expect(sizedBox.height, equals(36.0));
    });

    testWidgets('should fallback to default 24.0 height for success icon when theme.size is null', (WidgetTester tester) async {
      const FluentBarProgressState state = FluentBarProgressState.value(1.0);
      const FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.linear, size: null, showText: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: testDefaultColor, successIcon: testSuccessIcon),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final SizedBox sizedBox = tester.widget<SizedBox>(find.descendant(of: find.byKey(const ValueKey<String>('success_icon')), matching: find.byType(SizedBox)).first);

      expect(sizedBox.height, equals(24.0));
    });
  });
}
