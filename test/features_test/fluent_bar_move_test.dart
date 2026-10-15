import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> advance(WidgetTester tester, int milliseconds) async {
    for (int passed = 0; passed < milliseconds; passed += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  double moveOpacity(WidgetTester tester) {
    final Finder fades = find.ancestor(of: find.text('Message'), matching: find.byType(FadeTransition));
    return tester.widgetList<FadeTransition>(fades).map((FadeTransition fade) => fade.opacity.value).reduce((double a, double b) => a < b ? a : b);
  }

  testWidgets('a visible bar fades in at its new place instead of jumping there', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().atTop().withEntrance(FluentBarEntranceAnimation.slide).show()!;
    await advance(tester, 600);

    final State<StatefulWidget> widgetState = tester.state(find.byType(FluentBarWrapper<void>));
    final double topY = tester.getCenter(find.text('Message')).dy;
    expect(moveOpacity(tester), 1.0);

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
    await tester.pump();

    expect(tester.getCenter(find.text('Message')).dy, greaterThan(topY), reason: 'the bar is already at the bottom');
    expect(moveOpacity(tester), 0.0, reason: 'and starts transparent');
    expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.visible);
    expect(tester.state(find.byType(FluentBarWrapper<void>)), same(widgetState), reason: 'the same widget, nothing is rebuilt from scratch');

    await tester.pump(const Duration(milliseconds: 150));
    expect(moveOpacity(tester), inExclusiveRange(0.0, 1.0));

    await advance(tester, 400);
    expect(moveOpacity(tester), 1.0);
    expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.visible);

    await cleanup(tester);
  });

  testWidgets('a move inside one region fades too', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().atTop().show()!;
    await advance(tester, 600);

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.center));
    await tester.pump();
    expect(moveOpacity(tester), 0.0);

    await advance(tester, 500);
    expect(moveOpacity(tester), 1.0);

    await cleanup(tester);
  });

  testWidgets('other updates do not fade the bar', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().atTop().show()!;
    await advance(tester, 600);

    entry.controller.updateContent(type: FluentBarType.success);
    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(dismissOnTap: false));
    await tester.pump();

    expect(moveOpacity(tester), 1.0);

    await cleanup(tester);
  });

  testWidgets('a bar without animations moves at once', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().atTop().withoutAnimations().show()!;
    await advance(tester, 200);

    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
    await tester.pump();

    expect(find.ancestor(of: find.text('Message'), matching: find.byType(FadeTransition)), findsNothing);
    expect(find.text('Message'), findsOneWidget);

    await cleanup(tester);
  });
}
