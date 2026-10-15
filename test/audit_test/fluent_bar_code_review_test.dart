import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _OwnIconTheme extends FluentBarTheme {
  const _OwnIconTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => const BoxDecoration(color: Color(0xFF222222));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  Widget defaultIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode, double? overrideSize}) => const Icon(Icons.circle);
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  late List<FluentBarException> errors;
  void record(FluentBarException e, StackTrace _) => errors.add(e);

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    errors = <FluentBarException>[];
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    FluentBar.addErrorHandler(record);
  }

  Future<void> cleanup(WidgetTester tester) async {
    FluentBar.removeErrorHandler(record);
    manager.resetForTesting();
    await tester.pump();
  }

  group('the icon comes from the bar, then the type, then the theme', () {
    testWidgets('a theme with its own default icon does not hide the icon of a type', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.custom<void>(FluentBarType.info.copyWith(icon: const Icon(Icons.star)), 'Typed').withTheme(const _OwnIconTheme()).persistent().show();
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsNothing);

      await cleanup(tester);
    });

    testWidgets('the icon of the bar wins over the type, and the theme fills in without either', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.custom<void>(FluentBarType.info.copyWith(icon: const Icon(Icons.star)), 'Own').withIcon(const Icon(Icons.bolt)).withTheme(const _OwnIconTheme()).persistent().show();
      FluentBar.info<void>('Plain').atBottom().withTheme(const _OwnIconTheme()).persistent().show();
      await tester.pump();

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.circle), findsOneWidget);

      await cleanup(tester);
    });
  });

  group('a negative amount of time', () {
    testWidgets('addDuration with a negative amount is reported and does not close the bar', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Ten seconds').withDuration(const Duration(seconds: 10)).show()!;
      await tester.pump();

      entry.addDuration(const Duration(seconds: -20));
      await tester.pump(const Duration(seconds: 1));

      expect(entry.controller.stateNotifier.value.isVisible, isTrue);
      expect(errors.single.type, FluentBarErrorType.invalidCall);
      expect(errors.single.severity.isWarning, isTrue);

      await cleanup(tester);
    });

    testWidgets('subtractDuration with a negative amount is reported and adds nothing', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Ten seconds').withDuration(const Duration(seconds: 10)).show()!;
      await tester.pump();

      entry.subtractDuration(const Duration(seconds: -20));

      expect(entry.controller.totalDurationNotifier.value, const Duration(seconds: 10));
      expect(errors.single.type, FluentBarErrorType.invalidCall);

      await cleanup(tester);
    });
  });

  testWidgets('cancelProgress on a bar without progress changes nothing and reports no cancellation', (WidgetTester tester) async {
    await boot(tester);
    final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
    void listen(FluentBarAnalyticsPayload payload) => events.add(payload.event);
    FluentBar.addAnalyticsListener(listen);
    addTearDown(() => FluentBar.removeAnalyticsListener(listen));
    final FluentBarEntry<void> entry = FluentBar.info<void>('Plain bar').persistent().show()!;
    await tester.pump();

    entry.cancelProgress(fallbackMessage: 'Cancelled');
    await tester.pump();

    expect(events, isNot(contains(FluentBarAnalyticsEvent.progressCanceled)));
    expect(find.text('Plain bar'), findsOneWidget);
    expect(find.text('Cancelled'), findsNothing);
    expect(entry.internalController.progressOutcome, isNull);

    entry.cancelProgress(dismiss: true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Plain bar'), findsNothing);

    await cleanup(tester);
  });
}
