import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => throw StateError('paint');

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> expectCaught(WidgetTester tester, Widget content) async {
    await boot(tester);

    FluentBar.info<void>('Fallback content', id: 'b').persistent().withContent((BuildContext context, FluentBarEntry<void> entry) => content).show();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(errors, hasLength(1));
    expect(errors.single.type, FluentBarErrorType.customBuilderAppearance);
    expect(find.text('Fallback content'), findsOneWidget, reason: 'the default content is drawn instead');
    await cleanup(tester);
  }

  group('a content widget that throws', () {
    testWidgets('in build is reported once and replaced by the default content', (WidgetTester tester) async {
      await expectCaught(tester, Builder(builder: (BuildContext context) => throw StateError('build')));
    });

    testWidgets('in layout is reported once and replaced by the default content', (WidgetTester tester) async {
      await expectCaught(tester, LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) => throw StateError('layout')));
    });

    testWidgets('in paint is reported once and replaced by the default content', (WidgetTester tester) async {
      await expectCaught(tester, CustomPaint(painter: _BoomPainter(), size: const Size(40, 40)));
    });

    testWidgets('leaves FlutterError.onError as it was', (WidgetTester tester) async {
      await boot(tester);
      final FlutterExceptionHandler? before = FlutterError.onError;

      FluentBar.info<void>('x', id: 'b').persistent().withContent((BuildContext context, FluentBarEntry<void> entry) => CustomPaint(painter: _BoomPainter())).show();
      await tester.pump();
      await tester.pump();

      expect(FlutterError.onError, same(before));
      await cleanup(tester);
    });
  });

  group('an overflow is not a failure', () {
    Future<void> expectKept(WidgetTester tester, FluentBarItem<void> item) async {
      await boot(tester);

      item.persistent().show();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final Object? exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect((exception! as FlutterError).message, contains('overflowed'));
      expect(errors, isEmpty);
      expect(find.byKey(const ValueKey<String>('wide')), findsOneWidget);
      await cleanup(tester);
    }

    Widget wide() => const SizedBox(
      width: 24,
      height: 24,
      child: Row(key: ValueKey<String>('wide'), children: <Widget>[SizedBox(width: 500, height: 10)]),
    );

    testWidgets('an overflowing content widget stays and only Flutter reports the overflow', (WidgetTester tester) async {
      await expectKept(tester, FluentBar.info<void>('x', id: 'b').withContent((BuildContext context, FluentBarEntry<void> entry) => wide()));
    });

    testWidgets('an overflowing custom icon stays and only Flutter reports the overflow', (WidgetTester tester) async {
      await expectKept(tester, FluentBar.info<void>('x', id: 'b').withIcon(wide()));
    });
  });

  testWidgets('new content after a failure is drawn', (WidgetTester tester) async {
    await boot(tester);
    bool isBroken = true;

    final FluentBarEntry<void> entry = FluentBar.info<void>('Fallback content', id: 'b')
        .persistent()
        .withContent((BuildContext context, FluentBarEntry<void> e) => isBroken ? Builder(builder: (BuildContext context) => throw StateError('build')) : Text('healthy ${e.item.message}'))
        .show()!;
    await tester.pump();
    await tester.pump();
    expect(find.text('Fallback content'), findsOneWidget);
    expect(errors, hasLength(1));

    isBroken = false;
    entry.update(message: 'again');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('healthy again'), findsOneWidget);
    expect(errors, hasLength(1));
    await cleanup(tester);
  });

  testWidgets('a healthy content widget is drawn and nothing is reported', (WidgetTester tester) async {
    await boot(tester);

    FluentBar.info<void>('x', id: 'b').persistent().withContent((BuildContext context, FluentBarEntry<void> entry) => const Text('custom')).show();
    await tester.pump();
    await tester.pump();

    expect(find.text('custom'), findsOneWidget);
    expect(errors, isEmpty);
    await cleanup(tester);
  });
}
