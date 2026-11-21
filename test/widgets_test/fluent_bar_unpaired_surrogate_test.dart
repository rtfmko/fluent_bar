import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester, {double scale = 1.0}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero))(context, child),
        ),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
  }

  testWidgets('unpaired surrogates in the title, message and action label are replaced by U+FFFD', (WidgetTester tester) async {
    await boot(tester);

    FluentBar.info<void>('a\uD800b\uDC00c', title: 'x\uDBFF').withAction('ok\uDC00').show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('a�b�c'), findsOneWidget);
    expect(find.text('x�'), findsOneWidget);
    expect(find.text('ok�'), findsOneWidget);
    manager.resetForTesting();
    await tester.pump();
  });

  testWidgets('a pair of surrogates is kept', (WidgetTester tester) async {
    await boot(tester);

    FluentBar.info<void>('go \u{1F600}').show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('go \u{1F600}'), findsOneWidget);
    manager.resetForTesting();
    await tester.pump();
  });

  testWidgets('a progress label with an unpaired surrogate does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FluentBarTaskProgressWidget(
            progressNotifier: ValueNotifier<FluentBarProgressState?>(const FluentBarProgressValue(0.5)),
            theme: FluentBarProgressTheme(showText: true, labelBuilder: (FluentBarProgressState state) => 'half\uD800'),
            defaultColor: Colors.white,
            successIcon: const Icon(Icons.check),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('half�'), findsOneWidget);
  });
}
