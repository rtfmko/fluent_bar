import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  const String sentence = 'A long message that has to wrap on a small screen. ';

  Future<void> show(WidgetTester tester, FluentBarItem<void> item, {required Size size, double textScale = 1.0}) async {
    manager.resetForTesting();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero))(context, child),
        ),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    item.show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  tearDown(manager.resetForTesting);

  group('no layout overflow', () {
    testWidgets('a 200x100 screen with a title, a long message, an action and a close button', (WidgetTester tester) async {
      await show(tester, FluentBar.info<void>(sentence * 5, title: 'Top').withCloseButton().withAction('Retry').persistent(), size: const Size(200, 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a 200x100 bottom bar with a long message', (WidgetTester tester) async {
      await show(tester, FluentBar.error<void>(sentence * 5, title: 'Bottom').atBottom().persistent(), size: const Size(200, 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a 2000x200 screen at text scale 3 with a long message', (WidgetTester tester) async {
      await show(tester, FluentBar.info<void>('A fairly long message that has to wrap on a small screen several times', title: 'A title').persistent(), size: const Size(2000, 200), textScale: 3.0);

      expect(tester.takeException(), isNull);
    });

    testWidgets('a 2000x200 screen at text scale 3 with an action, a close button, progress and a countdown', (WidgetTester tester) async {
      final FluentBarItem<void> item = FluentBar.info<void>(
        'A fairly long message that has to wrap',
        title: 'A title',
      ).withCloseButton().withAction('Retry now').withLinearProgress(value: 0.3, showText: true);
      await show(tester, item.withTimeoutBar(), size: const Size(2000, 200), textScale: 3.0);

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('at text scale 2 on 320 px the message keeps a usable width and the action goes under it', (WidgetTester tester) async {
    const String message = 'Your changes were saved to the cloud';
    await show(tester, FluentBar.info<void>(message, title: 'Saved').withCloseButton().withAction('Undo').persistent(), size: const Size(320, 480), textScale: 2.0);

    final Rect text = tester.getRect(find.text(message));
    final Rect action = tester.getRect(find.text('Undo'));
    expect(text.width, greaterThanOrEqualTo(120));
    expect(action.top, greaterThanOrEqualTo(text.bottom - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the action stays beside the text where there is room', (WidgetTester tester) async {
    const String message = 'Your changes were saved';
    await show(tester, FluentBar.info<void>(message, title: 'Saved').withCloseButton().withAction('Undo').persistent(), size: const Size(400, 200));

    expect(tester.getRect(find.text('Undo')).left, greaterThan(tester.getRect(find.text(message)).right));
  });
}
