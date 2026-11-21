import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenModeTheme extends FluentBarTheme {
  _BrokenModeTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) =>
      BoxDecoration(color: backgroundColor(context, type, themeMode: themeMode));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Colors.white);

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Colors.white);

  @override
  bool isDarkMode(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => throw StateError('no mode');
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });
  tearDown(() => FluentBar.removeErrorHandler(onError));

  Future<FluentBarEntry<void>> show(WidgetTester tester, FluentBarTheme theme) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    final FluentBarItem<void> base = FluentBar.info<void>('Saved');
    final FluentBarEntry<void> entry = base.copyWith(appearance: base.appearance.copyWith(theme: theme)).show()!;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return entry;
  }

  testWidgets('a theme whose isDarkMode throws is reported once as darkMode and the bar uses the light variant', (WidgetTester tester) async {
    await show(tester, _BrokenModeTheme());

    expect(errors.map((FluentBarException e) => e.type), <FluentBarErrorType>[FluentBarErrorType.darkMode]);
    expect(find.text('Saved'), findsOneWidget);
    final BoxDecoration decoration = tester.widget<DecoratedBox>(find.descendant(of: find.byType(DefaultFluentBarWidget<void>), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFF1565C0));
    manager.resetForTesting();
    await tester.pump();
  });

  testWidgets('an isDarkMode given to copyWith that throws is reported once as darkMode', (WidgetTester tester) async {
    await show(tester, FluentBarTheme.material.copyWith(isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => throw StateError('no mode')));

    expect(errors.map((FluentBarException e) => e.type), <FluentBarErrorType>[FluentBarErrorType.darkMode]);
    expect(find.text('Saved'), findsOneWidget);
    manager.resetForTesting();
    await tester.pump();
  });

  testWidgets('a theme that keeps failing is reported once, however often the bar is rebuilt', (WidgetTester tester) async {
    final FluentBarEntry<void> entry = await show(tester, _BrokenModeTheme());

    for (int i = 0; i < 5; i++) {
      entry.update(message: 'Saved $i');
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(errors.map((FluentBarException e) => e.type), <FluentBarErrorType>[FluentBarErrorType.darkMode]);
    manager.resetForTesting();
    await tester.pump();
  });
}
