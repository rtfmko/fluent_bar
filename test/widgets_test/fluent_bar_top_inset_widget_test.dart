import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar(this.height);

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

Future<void> _pumpApp(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: FluentBarScope.builder(),
      home: Scaffold(body: body),
    ),
  );
  await tester.pump();
}

void main() {
  late FluentBarManager manager;

  setUp(() {
    manager = FluentBarManager.instance;
    manager.resetForTesting();
  });

  testWidgets('an app bar reports its height after the frame, and withdraws it when removed', (WidgetTester tester) async {
    await _pumpApp(tester, const FluentBarTopInset(child: _Bar(56)));
    expect(manager.topInsetNotifier.value, 56);

    await _pumpApp(tester, const SizedBox());
    expect(manager.topInsetNotifier.value, 0);
  });

  testWidgets('a height change is reported in the next frame', (WidgetTester tester) async {
    await _pumpApp(tester, const FluentBarTopInset(child: _Bar(56)));
    expect(manager.topInsetNotifier.value, 56);

    await _pumpApp(tester, const FluentBarTopInset(child: _Bar(80)));
    expect(manager.topInsetNotifier.value, 80);
  });

  testWidgets('the height changes and the bar is removed one frame later: nothing stale is left', (WidgetTester tester) async {
    await _pumpApp(tester, const FluentBarTopInset(child: _Bar(56)));
    await _pumpApp(tester, const FluentBarTopInset(child: _Bar(80)));
    await _pumpApp(tester, const SizedBox());
    await tester.pump();

    expect(manager.topInsetNotifier.value, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an app bar and a bottom panel in one tree do not affect each other', (WidgetTester tester) async {
    await _pumpApp(
      tester,
      const Column(
        children: <Widget>[
          FluentBarTopInset(child: _Bar(56)),
          Spacer(),
          FluentBarBottomInset(child: SizedBox(height: 80)),
        ],
      ),
    );
    expect(manager.topInsetNotifier.value, 56);
    expect(manager.bottomInsetNotifier.value, 80);

    await _pumpApp(
      tester,
      const Column(
        children: <Widget>[
          Spacer(),
          FluentBarBottomInset(child: SizedBox(height: 80)),
        ],
      ),
    );
    expect(manager.topInsetNotifier.value, 0);
    expect(manager.bottomInsetNotifier.value, 80);
  });
}
