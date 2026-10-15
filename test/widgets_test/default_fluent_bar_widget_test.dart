import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultFluentBarWidget Tests', () {
    const FluentBarConfig defaultConfig = FluentBarConfig();

    group('Platform Theme Resolution', () {
      testWidgets(' should resolve explicit cupertino theme style', (WidgetTester tester) async {
        const FluentBarConfig config = FluentBarConfig(themeStyle: FluentBarThemeStyle.cupertino);
        final FluentBarEntry<void> entry = FluentBarEntry<void>(
          item: FluentBarItem<void>(type: FluentBarType.info, message: 'Cupertino Style'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: config),
            ),
          ),
        );

        expect(find.text('Cupertino Style'), findsOneWidget);
      });

      testWidgets('should resolve explicit material theme style', (WidgetTester tester) async {
        const FluentBarConfig config = FluentBarConfig(themeStyle: FluentBarThemeStyle.material);
        final FluentBarEntry<void> entry = FluentBarEntry<void>(
          item: FluentBarItem<void>(type: FluentBarType.info, message: 'Material Style'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: config),
            ),
          ),
        );

        expect(find.text('Material Style'), findsOneWidget);
      });

      testWidgets('should resolve explicit windows theme style', (WidgetTester tester) async {
        const FluentBarConfig config = FluentBarConfig(themeStyle: FluentBarThemeStyle.windows);
        final FluentBarEntry<void> entry = FluentBarEntry<void>(
          item: FluentBarItem<void>(type: FluentBarType.info, message: 'Windows Style'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: config),
            ),
          ),
        );

        expect(find.text('Windows Style'), findsOneWidget);
      });

      testWidgets('should resolve platform fallback theme for iOS/macOS platform', (WidgetTester tester) async {
        final FluentBarEntry<void> entry = FluentBarEntry<void>(
          item: FluentBarItem<void>(type: FluentBarType.info, message: 'iOS Platform'),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('iOS Platform'), findsOneWidget);
      });

      testWidgets('should resolve platform fallback theme for Windows platform', (WidgetTester tester) async {
        final FluentBarEntry<void> entry = FluentBarEntry<void>(
          item: FluentBarItem<void>(type: FluentBarType.info, message: 'Windows Platform'),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.windows),
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('Windows Platform'), findsOneWidget);
      });

      testWidgets('should resolve default material theme for Android/Linux platforms', (WidgetTester tester) async {
        final FluentBarEntry<void> entry = FluentBarEntry<void>(
          item: FluentBarItem<void>(type: FluentBarType.info, message: 'Android Platform'),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.android),
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('Android Platform'), findsOneWidget);
      });
    });

    group('Progress State & Layout Positions', () {
      testWidgets('should render progress widget in left position', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Left progress',
          progressState: const FluentBarProgressState.indeterminate(),
          appearance: const FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(position: FluentBarProgressPosition.left)),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.byType(FluentBarTaskProgressWidget), findsOneWidget);
        expect(find.text('Left progress'), findsOneWidget);
      });

      testWidgets('should render progress widget in right position', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Right progress',
          progressState: const FluentBarProgressState.value(0.5),
          appearance: const FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(position: FluentBarProgressPosition.right)),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.byType(FluentBarTaskProgressWidget), findsOneWidget);
      });

      testWidgets('should render progress widget replacing icon when position is replaceIcon', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Replace icon progress',
          progressState: const FluentBarProgressState.fraction(3, 5),
          appearance: const FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(position: FluentBarProgressPosition.replaceIcon)),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.byType(FluentBarTaskProgressWidget), findsOneWidget);
      });

      testWidgets('should render progress widget in top and bottom positions', (WidgetTester tester) async {
        for (final FluentBarProgressPosition pos in <FluentBarProgressPosition>[FluentBarProgressPosition.top, FluentBarProgressPosition.bottom]) {
          final FluentBarItem<void> item = FluentBarItem<void>(
            type: FluentBarType.info,
            message: 'Top/Bottom progress',
            progressState: const FluentBarProgressState.value(0.8),
            appearance: FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(position: pos)),
          );
          final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
              ),
            ),
          );

          expect(find.byType(FluentBarTaskProgressWidget), findsOneWidget);
        }
      });

      testWidgets('should execute custom progress builder when provided', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Custom progress',
          progressState: const FluentBarProgressState.value(0.5),
          appearance: FluentBarAppearance<void>(
            progressTheme: FluentBarProgressTheme(
              progressBuilder: (BuildContext context, ValueListenable<FluentBarProgressState?> notifier) {
                return const Text('CustomProgressWidget');
              },
            ),
          ),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('CustomProgressWidget'), findsOneWidget);
      });

      testWidgets('should handle exception thrown by custom progress builder gracefully', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Error progress',
          progressState: const FluentBarProgressState.value(0.5),
          appearance: FluentBarAppearance<void>(
            progressTheme: FluentBarProgressTheme(
              progressBuilder: (BuildContext context, ValueListenable<FluentBarProgressState?> notifier) {
                throw Exception('Custom progress builder error');
              },
            ),
          ),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.byType(FluentBarTaskProgressWidget), findsOneWidget);
      });
    });

    group('Icons & Duration Progress Bar', () {
      testWidgets('should render custom item icon when specified', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Custom Icon Test',
          appearance: const FluentBarAppearance<void>(icon: Icon(Icons.star, key: Key('custom_icon_key'))),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.byKey(const Key('custom_icon_key')), findsOneWidget);
      });

      testWidgets('should render duration timeout progress bar when enabled', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(type: FluentBarType.info, message: 'Timeout Bar Test', appearance: const FluentBarAppearance<void>(showTimeoutBar: true));
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.byType(ClipRRect), findsWidgets);
        expect(find.text('Timeout Bar Test'), findsOneWidget);
      });
    });

    group('Title and Message Rendering', () {
      testWidgets('should render title when provided', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(type: FluentBarType.info, title: 'Notification Title', message: 'Notification Message');
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('Notification Title'), findsOneWidget);
        expect(find.text('Notification Message'), findsOneWidget);
      });

      testWidgets('should not render title when it is null', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(type: FluentBarType.info, message: 'Only Message Content');
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('Only Message Content'), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    group('Callbacks & Action Buttons', () {
      testWidgets('should render action using custom child widget', (WidgetTester tester) async {
        bool actionPressed = false;
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Action with custom child',
          actions: FluentBarActions<void>(
            child: const Text('CUSTOM_BTN'),
            onPressed: (FluentBarController<void> controller, void payload) {
              actionPressed = true;
            },
          ),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);
        entry.internalController.changeState(FluentBarLifecycleState.visible);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('CUSTOM_BTN'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.text('CUSTOM_BTN'));
        await tester.pump();

        expect(actionPressed, isTrue);
      });

      testWidgets('should render action using label when child is null', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Action with label',
          actions: const FluentBarActions<void>(label: 'LABEL_BTN'),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('LABEL_BTN'), findsOneWidget);
      });

      testWidgets('should handle exception thrown by custom action builder gracefully', (WidgetTester tester) async {
        final FluentBarItem<void> item = FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Action builder error test',
          actions: FluentBarActions<void>(
            builder: (BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode themeMode) => throw Exception('Custom action builder crash'),
          ),
        );
        final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DefaultFluentBarWidget<dynamic>(entry: entry, config: defaultConfig),
            ),
          ),
        );

        expect(find.text('Action builder error test'), findsOneWidget);
      });
    });
  });
}
