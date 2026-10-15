import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarTheme.copyWith & _ProxyFluentBarTheme Tests', () {
    const List<FluentBarTheme> allBaseThemes = <FluentBarTheme>[
      FluentBarTheme.cupertino,
      FluentBarTheme.liquidGlass,
      FluentBarTheme.material,
      FluentBarTheme.windows,
      FluentBarTheme.minimal,
      FluentBarTheme.modern,
    ];

    const List<FluentBarType> barTypes = <FluentBarType>[FluentBarType.info, FluentBarType.success, FluentBarType.warning, FluentBarType.error];

    testWidgets('should use overridden values when copyWith is applied for all themes', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      const BoxDecoration customBoxDeco = BoxDecoration(color: Colors.red);
      const TextStyle customTitleStyle = TextStyle(fontSize: 20);
      const TextStyle customMessageStyle = TextStyle(fontSize: 16);
      const TextStyle customActionStyle = TextStyle(fontSize: 14);
      const BoxDecoration customActionDeco = BoxDecoration(color: Colors.blue);
      const EdgeInsets customActionPadding = EdgeInsets.all(4);
      const BoxConstraints customConstraints = BoxConstraints(minWidth: 100);
      const BorderRadius customBorderRadius = BorderRadius.all(Radius.circular(12));
      const Text customInteractive = Text('Interactive');
      const Text customWrap = Text('Wrap');
      const Text customProgress = Text('Progress');
      final Widget customIcon = Container();

      for (final FluentBarTheme baseTheme in allBaseThemes) {
        final FluentBarTheme proxyTheme = baseTheme.copyWith(
          isDarkMode: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => true,
          constraints: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customConstraints,
          backgroundColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => Colors.yellow,
          iconColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => Colors.green,
          timeoutBarColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => Colors.orange,
          timeoutBarBackgroundColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => Colors.grey,
          actionInternalPadding: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customActionPadding,
          padding: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => const EdgeInsets.all(8),
          margin: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => const EdgeInsets.all(4),
          boxDecoration: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customBoxDeco,
          actionDecoration: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customActionDeco,
          titleStyle: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customTitleStyle,
          messageStyle: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customMessageStyle,
          actionStyle: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customActionStyle,
          titleOverflow: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => TextOverflow.clip,
          messageOverflow: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => TextOverflow.fade,
          actionOverflow: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => TextOverflow.visible,
          maxTitleLines: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 2,
          maxMessageLines: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 5,
          actionMaxLines: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 2,
          iconSize: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 32.0,
          spacing: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 15.0,
          titleSpacing: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 4.0,
          timeoutBarMinHeight: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 4.0,
          timeoutBarBorderRadius: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => BorderRadius.circular(4),
          borderRadius: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => customBorderRadius,
          defaultIcon: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode, double? overrideSize) => customIcon,
          wrapInteractiveContainer: (BuildContext context, Widget child, FluentBarType type, FluentBarThemeMode? themeMode) => customInteractive,
          wrapContainer: (BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode) => customWrap,
          buildTimeoutBar: (BuildContext context, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode) => customProgress,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                const FluentBarType type = FluentBarType.info;

                expect(proxyTheme.isDarkMode(context, type), true);
                expect(proxyTheme.constraints(context, type), customConstraints);
                expect(proxyTheme.backgroundColor(context, type), Colors.yellow);
                expect(proxyTheme.iconColor(context, type), Colors.green);
                expect(proxyTheme.timeoutBarColor(context, type), Colors.orange);
                expect(proxyTheme.timeoutBarBackgroundColor(context, type), Colors.grey);
                expect(proxyTheme.actionInternalPadding(context, type), customActionPadding);
                expect(proxyTheme.padding(context, type), const EdgeInsets.all(8));
                expect(proxyTheme.margin(context, type), const EdgeInsets.all(4));
                expect(proxyTheme.boxDecoration(context, type, proxyTheme), customBoxDeco);
                expect(proxyTheme.actionDecoration(context, type), customActionDeco);
                expect(proxyTheme.titleStyle(context, type), customTitleStyle);
                expect(proxyTheme.messageStyle(context, type), customMessageStyle);
                expect(proxyTheme.actionStyle(context, type), customActionStyle);
                expect(proxyTheme.titleOverflow(context, type), TextOverflow.clip);
                expect(proxyTheme.messageOverflow(context, type), TextOverflow.fade);
                expect(proxyTheme.actionOverflow(context, type), TextOverflow.visible);
                expect(proxyTheme.maxTitleLines(context, type), 2);
                expect(proxyTheme.maxMessageLines(context, type), 5);
                expect(proxyTheme.actionMaxLines(context, type), 2);
                expect(proxyTheme.iconSize(context, type), 32.0);
                expect(proxyTheme.spacing(context, type), 15.0);
                expect(proxyTheme.titleSpacing(context, type), 4.0);
                expect(proxyTheme.timeoutBarMinHeight(context, type), 4.0);
                expect(proxyTheme.timeoutBarBorderRadius(context, type), BorderRadius.circular(4));
                expect(proxyTheme.borderRadius(context, type), customBorderRadius);
                expect(proxyTheme.defaultIcon(context, type), customIcon);

                expect(proxyTheme.wrapInteractiveContainer(context, const SizedBox(), type), customInteractive);
                expect(proxyTheme.wrapContainer(context, const SizedBox(), entry, type), customWrap);
                expect(proxyTheme.buildTimeoutBar(context, entry, proxyTheme, type), customProgress);

                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }
    });

    testWidgets('should fallback to baseTheme values when overrides are null for all themes', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);
      final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.5);

      for (final FluentBarTheme baseTheme in allBaseThemes) {
        final FluentBarTheme proxyTheme = baseTheme.copyWith();

        for (final FluentBarThemeMode themeMode in <FluentBarThemeMode>[FluentBarThemeMode.light, FluentBarThemeMode.dark]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (BuildContext context) {
                  const FluentBarType type = FluentBarType.info;

                  expect(proxyTheme.isDarkMode(context, type, themeMode: themeMode), baseTheme.isDarkMode(context, type, themeMode: themeMode));
                  expect(proxyTheme.boxDecoration(context, type, proxyTheme, themeMode: themeMode), baseTheme.boxDecoration(context, type, baseTheme, themeMode: themeMode));
                  expect(proxyTheme.titleStyle(context, type, themeMode: themeMode), baseTheme.titleStyle(context, type, themeMode: themeMode));
                  expect(proxyTheme.messageStyle(context, type, themeMode: themeMode), baseTheme.messageStyle(context, type, themeMode: themeMode));
                  expect(proxyTheme.actionStyle(context, type, themeMode: themeMode), baseTheme.actionStyle(context, type, themeMode: themeMode));
                  expect(proxyTheme.actionDecoration(context, type, themeMode: themeMode), baseTheme.actionDecoration(context, type, themeMode: themeMode));
                  expect(proxyTheme.actionInternalPadding(context, type, themeMode: themeMode), baseTheme.actionInternalPadding(context, type, themeMode: themeMode));
                  expect(proxyTheme.iconColor(context, type, themeMode: themeMode), baseTheme.iconColor(context, type, themeMode: themeMode));
                  expect(proxyTheme.padding(context, type, themeMode: themeMode), baseTheme.padding(context, type, themeMode: themeMode));
                  expect(proxyTheme.constraints(context, type, themeMode: themeMode), baseTheme.constraints(context, type, themeMode: themeMode));
                  expect(proxyTheme.borderRadius(context, type, themeMode: themeMode), baseTheme.borderRadius(context, type, themeMode: themeMode));
                  expect(proxyTheme.spacing(context, type, themeMode: themeMode), baseTheme.spacing(context, type, themeMode: themeMode));

                  for (final FluentBarType typeName in barTypes) {
                    expect(proxyTheme.defaultIcon(context, typeName, themeMode: themeMode), isNotNull);
                    expect(proxyTheme.timeoutBarBackgroundColor(context, typeName, themeMode: themeMode), baseTheme.timeoutBarBackgroundColor(context, typeName, themeMode: themeMode));
                    expect(proxyTheme.timeoutBarColor(context, typeName, themeMode: themeMode), baseTheme.timeoutBarColor(context, typeName, themeMode: themeMode));
                  }

                  final Container dummyChild = Container();
                  final FluentBarEntry<dynamic> dummyEntry = FluentBarEntry<dynamic>(
                    item: FluentBarItem<dynamic>(type: FluentBarType.info, message: 'message'),
                  );

                  expect(
                    proxyTheme.wrapInteractiveContainer(context, dummyChild, type, themeMode: themeMode).runtimeType,
                    baseTheme.wrapInteractiveContainer(context, dummyChild, type, themeMode: themeMode).runtimeType,
                  );
                  expect(
                    proxyTheme.wrapContainer(context, dummyChild, dummyEntry, type, themeMode: themeMode).runtimeType,
                    baseTheme.wrapContainer(context, dummyChild, dummyEntry, type, themeMode: themeMode).runtimeType,
                  );

                  final Widget? progressWidget = proxyTheme.buildTimeoutBar(context, entry, proxyTheme, type, themeMode: themeMode);
                  expect(progressWidget, isNotNull);

                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          progressNotifier.value = 0.9;
          await tester.pump();
        }
      }
    });

    testWidgets('should safely fallback to baseTheme when proxy closures throw exceptions', (WidgetTester tester) async {
      const FluentBarTheme baseTheme = FluentBarTheme.material;
      final FluentBarTheme proxyTheme = baseTheme.copyWith(
        isDarkMode: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => throw Exception('isDarkMode failure'),
        backgroundColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => throw Exception('getBackgroundColor failure'),
        titleStyle: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => throw Exception('getTitleStyle failure'),
        boxDecoration: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => throw Exception('getBoxDecoration failure'),
        defaultIcon: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode, double? overrideSize) => throw Exception('getDefaultIcon failure'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              const FluentBarType type = FluentBarType.info;

              expect(proxyTheme.isDarkMode(context, type, themeMode: FluentBarThemeMode.light), baseTheme.isDarkMode(context, type, themeMode: FluentBarThemeMode.light));

              expect(proxyTheme.backgroundColor(context, type, themeMode: FluentBarThemeMode.light), baseTheme.backgroundColor(context, type, themeMode: FluentBarThemeMode.light));

              expect(proxyTheme.titleStyle(context, type, themeMode: FluentBarThemeMode.light), baseTheme.titleStyle(context, type, themeMode: FluentBarThemeMode.light));

              expect(proxyTheme.boxDecoration(context, type, proxyTheme, themeMode: FluentBarThemeMode.light), baseTheme.boxDecoration(context, type, baseTheme, themeMode: FluentBarThemeMode.light));

              expect(proxyTheme.defaultIcon(context, type, themeMode: FluentBarThemeMode.light).runtimeType, baseTheme.defaultIcon(context, type, themeMode: FluentBarThemeMode.light).runtimeType);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('should execute buildProgressBar with reverse progress direction for material and modern themes', (WidgetTester tester) async {
      final FluentBarItem<dynamic> reverseItem = FluentBarItem<dynamic>(
        type: FluentBarType.info.copyWith(timeoutBarDirection: FluentBarTimeoutBarDirection.reverse),
        message: 'Reverse Progress Test',
      );

      final FluentBarEntry<dynamic> reverseEntry = FluentBarEntry<dynamic>(item: reverseItem);

      for (final FluentBarTheme theme in <FluentBarTheme>[FluentBarTheme.material, FluentBarTheme.modern]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                final Widget? progressWidget = theme.buildTimeoutBar(context, reverseEntry, theme, FluentBarType.info, themeMode: FluentBarThemeMode.light);
                expect(progressWidget, isNotNull);

                return Directionality(textDirection: TextDirection.ltr, child: progressWidget ?? const SizedBox());
              },
            ),
          ),
        );

        await tester.pump();
      }
    });

    testWidgets('should execute default buildProgressBar for modernDashboardBarTheme in light and dark modes', (WidgetTester tester) async {
      const FluentBarTheme theme = FluentBarTheme.modern;
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);
      final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.5);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (BuildContext context) {
              final Widget? widget = theme.buildTimeoutBar(context, entry, theme, FluentBarType.info, themeMode: FluentBarThemeMode.light);
              return Directionality(textDirection: TextDirection.ltr, child: widget ?? const SizedBox());
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (BuildContext context) {
              final Widget? widget = theme.buildTimeoutBar(context, entry, theme, FluentBarType.info, themeMode: FluentBarThemeMode.dark);
              return Directionality(textDirection: TextDirection.ltr, child: widget ?? const SizedBox());
            },
          ),
        ),
      );

      progressNotifier.value = 0.8;
      await tester.pump();
    });
  });

  group('FluentBarTheme Unit & Edge Cases Tests', () {
    testWidgets('isDarkMode respects explicit themeMode (light and dark)', (WidgetTester tester) async {
      const FluentBarTheme theme = FluentBarTheme.material;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (BuildContext context) {
              expect(theme.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.light), isFalse);
              expect(theme.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.dark), isTrue);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('getBackgroundColor covers all FluentBarTypes and dark/light branches', (WidgetTester tester) async {
      const FluentBarTheme theme = FluentBarTheme.material;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              final FluentBarType customType = FluentBarType.info.copyWith(backgroundColor: Colors.pink);
              expect(theme.backgroundColor(context, customType, themeMode: FluentBarThemeMode.light), Colors.pink);

              expect(theme.backgroundColor(context, FluentBarType.success, themeMode: FluentBarThemeMode.light), const Color(0xFF2E7D32));
              expect(theme.backgroundColor(context, FluentBarType.error, themeMode: FluentBarThemeMode.light), const Color(0xFFC62828));
              expect(theme.backgroundColor(context, FluentBarType.warning, themeMode: FluentBarThemeMode.light), const Color(0xFFEF6C00));
              expect(theme.backgroundColor(context, FluentBarType.info, themeMode: FluentBarThemeMode.light), const Color(0xFF1565C0));

              expect(theme.backgroundColor(context, FluentBarType.success, themeMode: FluentBarThemeMode.dark), const Color(0xFF1B5E20));
              expect(theme.backgroundColor(context, FluentBarType.error, themeMode: FluentBarThemeMode.dark), const Color(0xFFB71C1C));
              expect(theme.backgroundColor(context, FluentBarType.warning, themeMode: FluentBarThemeMode.dark), const Color(0xFFE65100));
              expect(theme.backgroundColor(context, FluentBarType.info, themeMode: FluentBarThemeMode.dark), const Color(0xFF0D47A1));

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('FluentBarTheme isDarkMode Deep Branch & Error Tests', () {
    testWidgets('isDarkMode uses CupertinoTheme brightness when Material Theme is absent', (WidgetTester tester) async {
      const FluentBarTheme theme = FluentBarTheme.material;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (BuildContext context) {
                  expect(theme.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isTrue, reason: 'Cupertino Dark Test');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('isDarkMode falls back to View platformBrightness when Theme and CupertinoTheme are absent', (WidgetTester tester) async {
      const FluentBarTheme theme = FluentBarTheme.material;

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext context) {
              expect(theme.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isTrue);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext context) {
              expect(theme.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isFalse);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      addTearDown(() => tester.platformDispatcher.platformBrightnessTestValue = Brightness.light);
    });

    test('isDarkMode catches exception, invokes FluentBarErrorHandler and returns false', () {
      const FluentBarTheme theme = FluentBarTheme.material;
      final BuildContext context = _ThrowingBuildContext();

      final bool isDark = theme.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system);

      expect(isDark, isFalse);
    });
  });
}

class _ThrowingBuildContext extends Fake implements BuildContext {
  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    throw Exception('Simulated theme lookup exception');
  }
}
