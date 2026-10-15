import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PlainTheme extends FluentBarTheme {
  const _PlainTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) =>
      BoxDecoration(color: theme.backgroundColor(context, type, themeMode: themeMode));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Colors.teal, fontSize: 15);

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(fontSize: 13);
}

class _ColorlessTheme extends _PlainTheme {
  const _ColorlessTheme();

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(fontSize: 15);
}

void main() {
  const FluentBarType type = FluentBarType.info;
  const FluentBarThemeMode light = FluentBarThemeMode.light;
  const FluentBarThemeMode dark = FluentBarThemeMode.dark;

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  FluentBarEntry<void> entryOf({FluentBarAppearance<void>? appearance}) {
    final FluentBarEntry<void> entry = FluentBarEntry<void>(
      item: FluentBarItem<void>(type: type, message: 'Test', appearance: appearance),
    );
    addTearDown(entry.internalController.dispose);
    return entry;
  }

  group('defaults of FluentBarTheme for a custom theme', () {
    testWidgets('layout, text and timeout-bar defaults', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme theme = _PlainTheme();

      expect(theme.constraints(context, type), const BoxConstraints(maxWidth: 480));
      expect(theme.actionsConstraints(context, type), const BoxConstraints(maxWidth: 160));
      expect(theme.padding(context, type), const EdgeInsets.symmetric(horizontal: 16, vertical: 12));
      expect(theme.margin(context, type), const EdgeInsets.all(16));
      expect(theme.actionInternalPadding(context, type), const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
      expect(theme.borderRadius(context, type), BorderRadius.circular(12));
      expect(theme.iconSize(context, type), 24.0);
      expect(theme.spacing(context, type), 12);
      expect(theme.titleSpacing(context, type), 2.0);
      expect(theme.maxTitleLines(context, type), 1);
      expect(theme.maxMessageLines(context, type), 3);
      expect(theme.actionMaxLines(context, type), 1);
      expect(theme.titleOverflow(context, type), TextOverflow.ellipsis);
      expect(theme.messageOverflow(context, type), TextOverflow.ellipsis);
      expect(theme.actionOverflow(context, type), TextOverflow.ellipsis);
      expect(theme.titleTextAlign(context, type), isNull);
      expect(theme.messageTextAlign(context, type), isNull);
      expect(theme.actionTextAlign(context, type), isNull);
      expect(theme.actionDecoration(context, type), isNull);
      expect(theme.actionLoadingWidget(context, type), isNull);
      expect(theme.timeoutBarMinHeight(context, type), 2.5);
      expect(theme.timeoutBarBorderRadius(context, type), isNull);
      expect(theme.timeoutBarColor(context, type), isNull);
      expect(theme.timeoutBarBackgroundColor(context, type), Colors.transparent);
    });

    testWidgets('colors derived from the title style', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme theme = _PlainTheme();

      expect(theme.actionStyle(context, type), theme.titleStyle(context, type));
      expect(theme.iconColor(context, type), Colors.teal);
      expect(theme.actionLoaderColor(context, type), Colors.teal);
    });

    testWidgets('fallback colors when the title style has no color', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme theme = _ColorlessTheme();

      expect(theme.iconColor(context, type), isNull);
      expect(theme.actionLoaderColor(context, type, themeMode: light), Colors.black);
      expect(theme.actionLoaderColor(context, type, themeMode: dark), Colors.white);

      final FluentBarEntry<void> entry = entryOf();
      for (final FluentBarThemeMode mode in <FluentBarThemeMode>[light, dark]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(builder: (BuildContext c) => theme.buildTimeoutBar(c, entry, theme, type, themeMode: mode)!),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        final LinearProgressIndicator bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        final Color expected = mode == dark ? Colors.white : Colors.black;
        expect((bar.valueColor! as AlwaysStoppedAnimation<Color>).value, expected.withValues(alpha: 0.5));
      }
    });

    testWidgets('default icons depend on the kind of the type; containers are passed through', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme theme = _PlainTheme();
      const Text child = Text('child');

      expect((theme.defaultIcon(context, FluentBarType.info) as Icon).icon, Icons.info_outline);
      expect((theme.defaultIcon(context, FluentBarType.success) as Icon).icon, Icons.check_circle_outline);
      expect((theme.defaultIcon(context, FluentBarType.warning) as Icon).icon, Icons.warning_amber_rounded);
      expect((theme.defaultIcon(context, FluentBarType.error) as Icon).icon, Icons.error_outline);
      expect((theme.defaultIcon(context, FluentBarType.info) as Icon).size, 24.0);
      expect((theme.defaultIcon(context, FluentBarType.info, overrideSize: 30) as Icon).size, 30.0);

      expect(theme.wrapInteractiveContainer(context, child, type), same(child));
      expect(theme.wrapContainer(context, child, entryOf(), type), same(child));
    });

    testWidgets('a theme decoration without a radius falls back to the border radius of the theme', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme theme = _PlainTheme();

      expect(theme.boxDecoration(context, type, theme).borderRadius, isNull);
      expect(entryOf().resolveBorderRadius(context, theme, light, const FluentBarConfig()), BorderRadius.circular(12));
    });
  });

  group('copyWith: every override', () {
    Never fail3(BuildContext c, FluentBarType t, FluentBarThemeMode? m) => throw Exception('override failed');

    FluentBarTheme broken(FluentBarTheme base) => base.copyWith(
      isDarkMode: fail3,
      constraints: fail3,
      actionsConstraints: fail3,
      backgroundColor: fail3,
      iconColor: fail3,
      timeoutBarColor: fail3,
      timeoutBarBackgroundColor: fail3,
      actionLoaderColor: fail3,
      actionInternalPadding: fail3,
      padding: fail3,
      margin: fail3,
      boxDecoration: fail3,
      actionDecoration: fail3,
      titleStyle: fail3,
      messageStyle: fail3,
      actionStyle: fail3,
      titleTextAlign: fail3,
      messageTextAlign: fail3,
      actionTextAlign: fail3,
      titleOverflow: fail3,
      messageOverflow: fail3,
      actionOverflow: fail3,
      maxTitleLines: fail3,
      maxMessageLines: fail3,
      actionMaxLines: fail3,
      iconSize: fail3,
      spacing: fail3,
      titleSpacing: fail3,
      timeoutBarMinHeight: fail3,
      timeoutBarBorderRadius: fail3,
      borderRadius: fail3,
      defaultIcon: (BuildContext c, FluentBarType t, FluentBarThemeMode? m, double? size) => throw Exception('override failed'),
      wrapInteractiveContainer: (BuildContext c, Widget child, FluentBarType t, FluentBarThemeMode? m) => throw Exception('override failed'),
      wrapContainer: (BuildContext c, Widget child, FluentBarEntry<dynamic> e, FluentBarType t, FluentBarThemeMode? themeMode) => throw Exception('override failed'),
      buildTimeoutBar: (BuildContext c, FluentBarEntry<dynamic> e, FluentBarType t, FluentBarThemeMode? m) => throw Exception('override failed'),
      actionLoadingWidget: fail3,
    );

    void expectSameAsBase(BuildContext context, FluentBarTheme actual, FluentBarTheme base, FluentBarEntry<void> entry, FluentBarThemeMode mode) {
      const Text child = Text('child');

      expect(actual.isDarkMode(context, type, themeMode: mode), base.isDarkMode(context, type, themeMode: mode));
      expect(actual.constraints(context, type, themeMode: mode), base.constraints(context, type, themeMode: mode));
      expect(actual.actionsConstraints(context, type, themeMode: mode), base.actionsConstraints(context, type, themeMode: mode));
      expect(actual.backgroundColor(context, type, themeMode: mode), base.backgroundColor(context, type, themeMode: mode));
      expect(actual.iconColor(context, type, themeMode: mode), base.iconColor(context, type, themeMode: mode));
      expect(actual.timeoutBarColor(context, type, themeMode: mode), base.timeoutBarColor(context, type, themeMode: mode));
      expect(actual.timeoutBarBackgroundColor(context, type, themeMode: mode), base.timeoutBarBackgroundColor(context, type, themeMode: mode));
      expect(actual.actionLoaderColor(context, type, themeMode: mode), base.actionLoaderColor(context, type, themeMode: mode));
      expect(actual.actionInternalPadding(context, type, themeMode: mode), base.actionInternalPadding(context, type, themeMode: mode));
      expect(actual.padding(context, type, themeMode: mode), base.padding(context, type, themeMode: mode));
      expect(actual.margin(context, type, themeMode: mode), base.margin(context, type, themeMode: mode));
      expect(actual.boxDecoration(context, type, actual, themeMode: mode), base.boxDecoration(context, type, base, themeMode: mode));
      expect(actual.actionDecoration(context, type, themeMode: mode), base.actionDecoration(context, type, themeMode: mode));
      expect(actual.titleStyle(context, type, themeMode: mode), base.titleStyle(context, type, themeMode: mode));
      expect(actual.messageStyle(context, type, themeMode: mode), base.messageStyle(context, type, themeMode: mode));
      expect(actual.actionStyle(context, type, themeMode: mode), base.actionStyle(context, type, themeMode: mode));
      expect(actual.titleTextAlign(context, type, themeMode: mode), base.titleTextAlign(context, type, themeMode: mode));
      expect(actual.messageTextAlign(context, type, themeMode: mode), base.messageTextAlign(context, type, themeMode: mode));
      expect(actual.actionTextAlign(context, type, themeMode: mode), base.actionTextAlign(context, type, themeMode: mode));
      expect(actual.titleOverflow(context, type, themeMode: mode), base.titleOverflow(context, type, themeMode: mode));
      expect(actual.messageOverflow(context, type, themeMode: mode), base.messageOverflow(context, type, themeMode: mode));
      expect(actual.actionOverflow(context, type, themeMode: mode), base.actionOverflow(context, type, themeMode: mode));
      expect(actual.maxTitleLines(context, type, themeMode: mode), base.maxTitleLines(context, type, themeMode: mode));
      expect(actual.maxMessageLines(context, type, themeMode: mode), base.maxMessageLines(context, type, themeMode: mode));
      expect(actual.actionMaxLines(context, type, themeMode: mode), base.actionMaxLines(context, type, themeMode: mode));
      expect(actual.iconSize(context, type, themeMode: mode), base.iconSize(context, type, themeMode: mode));
      expect(actual.spacing(context, type, themeMode: mode), base.spacing(context, type, themeMode: mode));
      expect(actual.titleSpacing(context, type, themeMode: mode), base.titleSpacing(context, type, themeMode: mode));
      expect(actual.timeoutBarMinHeight(context, type, themeMode: mode), base.timeoutBarMinHeight(context, type, themeMode: mode));
      expect(actual.timeoutBarBorderRadius(context, type, themeMode: mode), base.timeoutBarBorderRadius(context, type, themeMode: mode));
      expect(actual.borderRadius(context, type, themeMode: mode), base.borderRadius(context, type, themeMode: mode));
      expect(actual.actionLoadingWidget(context, type, themeMode: mode), base.actionLoadingWidget(context, type, themeMode: mode));

      final Icon actualIcon = actual.defaultIcon(context, type, themeMode: mode, overrideSize: 33) as Icon;
      final Icon baseIcon = base.defaultIcon(context, type, themeMode: mode, overrideSize: 33) as Icon;
      expect(actualIcon.icon, baseIcon.icon);
      expect(actualIcon.size, 33);

      expect(actual.wrapInteractiveContainer(context, child, type, themeMode: mode).runtimeType, base.wrapInteractiveContainer(context, child, type, themeMode: mode).runtimeType);
      expect(actual.wrapContainer(context, child, entry, type, themeMode: mode).runtimeType, base.wrapContainer(context, child, entry, type, themeMode: mode).runtimeType);
      expect(actual.buildTimeoutBar(context, entry, actual, type, themeMode: mode).runtimeType, base.buildTimeoutBar(context, entry, base, type, themeMode: mode).runtimeType);
    }

    const Map<String, FluentBarTheme> themes = <String, FluentBarTheme>{
      'material': FluentBarTheme.material,
      'cupertino': FluentBarTheme.cupertino,
      'liquidGlass': FluentBarTheme.liquidGlass,
      'windows': FluentBarTheme.windows,
      'minimal': FluentBarTheme.minimal,
      'modern': FluentBarTheme.modern,
      'custom': _PlainTheme(),
    };

    for (final MapEntry<String, FluentBarTheme> theme in themes.entries) {
      testWidgets('${theme.key}: a copy without overrides behaves exactly like the base theme', (WidgetTester tester) async {
        final BuildContext context = await pumpContext(tester);
        final FluentBarEntry<void> entry = entryOf();

        for (final FluentBarThemeMode mode in <FluentBarThemeMode>[light, dark]) {
          expectSameAsBase(context, theme.value.copyWith(), theme.value, entry, mode);
        }
      });

      testWidgets('${theme.key}: when every override throws, every method falls back to the base theme and reports', (WidgetTester tester) async {
        final List<FluentBarException> errors = <FluentBarException>[];
        void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
        FluentBar.addErrorHandler(onError);
        addTearDown(() => FluentBar.removeErrorHandler(onError));

        final BuildContext context = await pumpContext(tester);
        final FluentBarEntry<void> entry = entryOf();

        for (final FluentBarThemeMode mode in <FluentBarThemeMode>[light, dark]) {
          expectSameAsBase(context, broken(theme.value), theme.value, entry, mode);
        }

        expect(tester.takeException(), isNull);
        expect(errors, isNotEmpty);
        expect(errors.map((FluentBarException e) => e.type).toSet(), <FluentBarErrorType>{FluentBarErrorType.fluentBarTheme});
      });
    }
  });
}
