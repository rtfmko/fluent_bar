import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('a throwing patchAppearance callback is reported and changes nothing', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().withBackground(Colors.teal).show()!;
    await tester.pump();

    expect(() => entry.patchAppearance((FluentBarAppearance<void> a) => throw StateError('broken')), returnsNormally);
    await tester.pump();

    expect(errors.single.type, FluentBarErrorType.patchCallback);
    expect(errors.single.severity, FluentBarErrorSeverity.error);
    expect(errors.single.error, isStateError);
    expect(entry.item.appearance.backgroundColor, Colors.teal);
    expect(entry.controller.stateNotifier.value.isVisible, isTrue);
    expect(tester.takeException(), isNull);

    entry.patchAppearance((FluentBarAppearance<void> a) => a.copyWith(backgroundColor: Colors.red));
    expect(entry.item.appearance.backgroundColor, Colors.red);
    await cleanup(tester);
  });

  testWidgets('a throwing patchBehavior callback is reported and changes nothing', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().show()!;
    await tester.pump();
    final FluentBarBehavior before = entry.item.behavior;

    expect(() => entry.patchBehavior((FluentBarBehavior b) => throw StateError('broken')), returnsNormally);
    await tester.pump();

    expect(errors.single.type, FluentBarErrorType.patchCallback);
    expect(entry.item.behavior, before);
    expect(find.text('Message'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });

  testWidgets('a throwing patchConfig callback is reported and keeps the config', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarConfig before = FluentBar.currentConfig;

    expect(() => FluentBar.patchConfig((FluentBarConfig c) => throw StateError('broken')), returnsNormally);
    await tester.pump();

    expect(errors.single.type, FluentBarErrorType.patchCallback);
    expect(FluentBar.currentConfig, before);
    expect(FluentBar.info<void>('Still works').show(), isNotNull);
    await tester.pump();
    expect(find.text('Still works'), findsOneWidget);
    await cleanup(tester);
  });
}
