import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<FluentBarEntry<void>> show(WidgetTester tester, FluentBarItem<void> item) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(
          config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, defaultReverseTransitionDuration: Duration.zero),
        ),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    final FluentBarEntry<void> entry = item.persistent().show()!;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return entry;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarItem<void> base() => FluentBar.info<void>('Uploading the quarterly report', title: 'Upload');

  FluentBarItem<void> withProgress(FluentBarItem<void> item, {required bool circular, required FluentBarProgressPosition position, FluentBarProgressState? state}) {
    final FluentBarProgressState value = state ?? const FluentBarProgressState.value(0.4);
    return circular ? item.withCircularProgress(state: value, position: position, showText: true) : item.withLinearProgress(state: value, position: position, showText: true);
  }

  tearDown(manager.resetForTesting);

  group('a completed ring without a type leaves one icon', () {
    for (final bool circular in <bool>[true]) {
      for (final FluentBarProgressPosition position in FluentBarProgressPosition.values) {
        testWidgets('${circular ? 'circular' : 'linear'} at ${position.name}', (WidgetTester tester) async {
          final FluentBarEntry<void> entry = await show(tester, withProgress(base(), circular: circular, position: position));

          entry.completeProgress(message: 'Report uploaded');
          await settle(tester);

          expect(find.byIcon(Icons.check_circle), findsOneWidget);
          expect(find.byIcon(Icons.info_outline), findsNothing);
          expect(find.text('Report uploaded'), findsOneWidget);
        });
      }
    }
  });

  testWidgets('a ring with its text inside is big enough to read the text', (WidgetTester tester) async {
    await show(tester, withProgress(base(), circular: true, position: FluentBarProgressPosition.left));

    expect(tester.getSize(find.byType(CircularProgressIndicator)).width, greaterThanOrEqualTo(36));
    final Text label = tester.widget<Text>(find.descendant(of: find.byType(FluentBarProgressLabel), matching: find.byType(Text)));
    expect(label.style!.fontSize, greaterThanOrEqualTo(10));
  });

  group('a linear indicator in place of the icon', () {
    testWidgets('has room for a line and a label', (WidgetTester tester) async {
      await show(tester, withProgress(base(), circular: false, position: FluentBarProgressPosition.replaceIcon));

      expect(tester.getSize(find.byType(LinearProgressIndicator)).width, greaterThanOrEqualTo(46));
    });

    testWidgets('tells a fraction from a value', (WidgetTester tester) async {
      await show(tester, withProgress(base(), circular: false, position: FluentBarProgressPosition.replaceIcon, state: const FluentBarProgressState.fraction(3, 8)));

      expect(find.text('3 / 8'), findsOneWidget);
    });
  });

  group('a failed progress leaves no indicator, the bar shows the error icon', () {
    for (final bool circular in <bool>[true, false]) {
      for (final FluentBarProgressPosition position in FluentBarProgressPosition.values) {
        testWidgets('${circular ? 'ring' : 'line'} at ${position.name}', (WidgetTester tester) async {
          final FluentBarEntry<void> entry = await show(tester, withProgress(base(), circular: circular, position: position));
          entry.failProgress(message: 'Upload failed');
          await settle(tester);

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(find.text('Upload failed'), findsOneWidget);
          expect(entry.item.type, FluentBarType.error);
        });
      }
    }
  });

  testWidgets('the Retry button of a failed circular loading bar is inside the bar and can be tapped', (WidgetTester tester) async {
    int retries = 0;
    final FluentBarEntry<void> entry = await show(tester, FluentBar.loading<void>('working', id: 'load'));

    entry.failProgress(message: 'failed', retryLabel: 'Retry', onRetry: () => retries++);
    await settle(tester);

    final Rect bar = tester.getRect(find.descendant(of: find.byType(DefaultFluentBarWidget<void>), matching: find.byType(DecoratedBox)).first);
    expect(bar.contains(tester.getRect(find.text('Retry')).center), isTrue);
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(retries, 1);
  });
}
