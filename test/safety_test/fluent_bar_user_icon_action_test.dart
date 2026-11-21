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
  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    manager.resetForTesting();
  });

  Future<void> show(WidgetTester tester, FluentBarItem<void> item) async {
    manager.resetForTesting();
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
    item.persistent().show();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a custom icon that throws in build is reported once and replaced by the default icon', (WidgetTester tester) async {
    final FluentBarItem<void> base = FluentBar.info<void>('Message');
    await show(
      tester,
      base.copyWith(
        appearance: base.appearance.copyWith(icon: Builder(builder: (BuildContext context) => throw StateError('icon'))),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(errors, hasLength(1));
    expect(errors.single.type, FluentBarErrorType.customBuilderAppearance);
    expect(find.text('Message'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('an action widget that throws in build is reported once and dropped', (WidgetTester tester) async {
    final FluentBarItem<void> base = FluentBar.info<void>('Message');
    await show(
      tester,
      base.copyWith(
        actions: FluentBarActions<void>(child: Builder(builder: (BuildContext context) => throw StateError('action'))),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(errors, hasLength(1));
    expect(errors.single.type, FluentBarErrorType.customButtonBuilder);
    expect(find.text('Message'), findsOneWidget);
  });
}
