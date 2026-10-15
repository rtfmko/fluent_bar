import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBar Themes Comprehensive Coverage Tests', () {
    final List<FluentBarTheme> themes = <FluentBarTheme>[
      FluentBarTheme.cupertino,
      FluentBarTheme.windows,
      FluentBarTheme.modern,
      FluentBarTheme.liquidGlass,
      FluentBarTheme.material,
      FluentBarTheme.minimal,
    ];

    const List<FluentBarType> types = <FluentBarType>[FluentBarType.info, FluentBarType.success, FluentBarType.warning, FluentBarType.error];

    const List<FluentBarThemeMode> modes = <FluentBarThemeMode>[FluentBarThemeMode.light, FluentBarThemeMode.dark];

    for (final FluentBarTheme theme in themes) {
      group('Theme: ${theme.runtimeType}', () {
        for (final FluentBarThemeMode mode in modes) {
          testWidgets('should correctly resolve all methods and styles in $mode mode', (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: FluentBarScope(
                    config: FluentBarConfig(defaultTheme: theme),
                    child: Builder(
                      builder: (BuildContext context) {
                        for (final FluentBarType type in types) {
                          expect(theme.borderRadius(context, type, themeMode: mode), isNotNull);
                          expect(theme.padding(context, type, themeMode: mode), isNotNull);
                          expect(theme.margin(context, type, themeMode: mode), isNotNull);
                          expect(theme.constraints(context, type, themeMode: mode), isNotNull);
                          expect(theme.timeoutBarMinHeight(context, type, themeMode: mode) > 0, isTrue);

                          final BoxDecoration boxDeco = theme.boxDecoration(context, type, theme, themeMode: mode);
                          expect(boxDeco, isNotNull);

                          final Color bgColor = theme.backgroundColor(context, type, themeMode: mode);
                          expect(bgColor, isNotNull);

                          final Color? iconColor = theme.iconColor(context, type, themeMode: mode);
                          expect(iconColor, isNotNull);

                          final Color? progColor = theme.timeoutBarColor(context, type, themeMode: mode);
                          expect(progColor, isNull);

                          final Color progBgColor = theme.timeoutBarBackgroundColor(context, type, themeMode: mode);
                          expect(progBgColor, isNotNull);

                          final Widget defaultIcon = theme.defaultIcon(context, type, themeMode: mode);
                          expect(defaultIcon, isNotNull);

                          final TextStyle titleStyle = theme.titleStyle(context, type, themeMode: mode);
                          expect(titleStyle, isNotNull);

                          final TextStyle msgStyle = theme.messageStyle(context, type, themeMode: mode);
                          expect(msgStyle, isNotNull);

                          final TextStyle actionStyle = theme.actionStyle(context, type, themeMode: mode);
                          expect(actionStyle, isNotNull);

                          final EdgeInsets? actionPadding = theme.actionInternalPadding(context, type, themeMode: mode);
                          expect(actionPadding, isNotNull);

                          final BoxDecoration? actionDeco = theme.actionDecoration(context, type, themeMode: mode);
                          expect(actionDeco, anything);
                        }

                        const FluentBarType defaultType = FluentBarType.info;

                        final Widget wrappedContainer = theme.wrapContainer(
                          context,
                          const Text('Container Content'),
                          FluentBarEntry<dynamic>(
                            item: FluentBarItem<dynamic>(type: defaultType, message: 'message'),
                          ),
                          defaultType,
                          themeMode: mode,
                        );
                        expect(wrappedContainer, isNotNull);

                        final Widget interactive = theme.wrapInteractiveContainer(context, const Text('Interactive', key: Key('interactive_key')), defaultType, themeMode: mode);
                        expect(interactive, isNotNull);

                        return Column(children: <Widget>[wrappedContainer, interactive]);
                      },
                    ),
                  ),
                ),
              ),
            );

            final Finder interactiveFinder = find.byKey(const Key('interactive_key'));
            expect(interactiveFinder, findsOneWidget);

            await tester.tap(interactiveFinder);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
          });
        }
      });
    }

    testWidgets('Timeout bar building across all themes', (WidgetTester tester) async {
      final FluentBarItem<void> item = FluentBarItem<void>(id: 'progress_test', message: 'Progress Bar Test', type: FluentBarType.info);
      final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(item);

      final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item, controller: controller);

      for (final FluentBarTheme theme in themes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FluentBarScope(
                config: FluentBarConfig(defaultTheme: theme),
                child: Builder(
                  builder: (BuildContext context) {
                    final Widget? progressBar = theme.buildTimeoutBar(context, entry, theme, FluentBarType.info);

                    expect(progressBar, isNotNull, reason: '${theme.runtimeType} should build a timeout bar');

                    return progressBar ?? const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      }

      controller.dispose();
    });

    testWidgets('getTimeoutBarColor respects custom timeoutBarColor in FluentBarType', (WidgetTester tester) async {
      const FluentBarTheme theme = FluentBarTheme.material;
      final FluentBarType typeWithCustomProgress = FluentBarType.info.copyWith(timeoutBarColor: Colors.purple);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              final Color? color = theme.timeoutBarColor(context, typeWithCustomProgress, themeMode: FluentBarThemeMode.light);
              expect(color, Colors.purple);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
