import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const int mb = 1024 * 1024;

  group('formatBytes', () {
    test('picks a binary unit and keeps one decimal only while it is needed', () {
      expect(FluentBarProgressBytes.formatBytes(0), '0 B');
      expect(FluentBarProgressBytes.formatBytes(512), '512 B');
      expect(FluentBarProgressBytes.formatBytes(1024), '1 KB');
      expect(FluentBarProgressBytes.formatBytes(1536), '1.5 KB');
      expect(FluentBarProgressBytes.formatBytes(3250586), '3.1 MB');
      expect(FluentBarProgressBytes.formatBytes(50 * mb), '50 MB');
      expect(FluentBarProgressBytes.formatBytes(150 * mb + 300000), '150 MB');
      expect(FluentBarProgressBytes.formatBytes(3 * 1024 * mb), '3 GB');
      expect(FluentBarProgressBytes.formatBytes(5 * 1024 * 1024 * mb), '5 TB');
    });

    test('can borrow the unit of another number and drop the unit', () {
      expect(FluentBarProgressBytes.formatBytes(512 * 1024, unitOf: 50 * mb), '0.5 MB');
      expect(FluentBarProgressBytes.formatBytes(512 * 1024, unitOf: 50 * mb, withUnit: false), '0.5');
    });
  });

  group('a known size', () {
    test('gives a fraction and the amount as text', () {
      const FluentBarProgressBytes state = FluentBarProgressBytes(3250586, 50 * mb);

      expect(state.hasTotal, isTrue);
      expect(state.progress, closeTo(0.062, 0.001));
      expect(state.isCompleted, isFalse);
      expect(state.text, '3.1 / 50 MB');
      expect(state.format(), '3.1 / 50 MB');
    });

    test('the label can be a percent or both', () {
      expect(const FluentBarProgressBytes(25 * mb, 50 * mb, label: FluentBarBytesLabel.percent).text, '50%');
      expect(const FluentBarProgressBytes(25 * mb, 50 * mb, label: FluentBarBytesLabel.both).text, '25 / 50 MB · 50%');
    });

    test('reaching the size completes it, going over does not break it', () {
      expect(const FluentBarProgressBytes(50 * mb, 50 * mb).isCompleted, isTrue);
      expect(const FluentBarProgressBytes(50 * mb, 50 * mb).progress, 1.0);

      const FluentBarProgressBytes over = FluentBarProgressBytes(60 * mb, 50 * mb);
      expect(over.isCompleted, isTrue);
      expect(over.progress, 1.0);
      expect(over.text, '50 / 50 MB');
    });

    test('a negative received counts as nothing', () {
      const FluentBarProgressBytes state = FluentBarProgressBytes(-5, 50 * mb);

      expect(state.progress, 0.0);
      expect(state.text, '0 / 50 MB');
    });
  });

  group('an unknown size', () {
    for (final int? total in <int?>[null, 0, -1]) {
      test('total $total is indeterminate and still shows what has arrived', () {
        final FluentBarProgressBytes state = FluentBarProgressBytes(3250586, total);

        expect(state.hasTotal, isFalse);
        expect(state.progress, isNull);
        expect(state.isCompleted, isFalse);
        expect(state.text, '3.1 MB');
      });
    }

    test('the label style does not matter without a size', () {
      expect(const FluentBarProgressBytes(2048, null, label: FluentBarBytesLabel.percent).text, '2 KB');
    });
  });

  test('equality covers received, total and the label', () {
    expect(const FluentBarProgressState.bytes(1, 2), const FluentBarProgressBytes(1, 2));
    expect(const FluentBarProgressBytes(1, 2), isNot(const FluentBarProgressBytes(1, 3)));
    expect(const FluentBarProgressBytes(1, 2), isNot(const FluentBarProgressBytes(1, 2, label: FluentBarBytesLabel.percent)));
    expect(const FluentBarProgressBytes(1, 2).hashCode, const FluentBarProgressBytes(1, 2).hashCode);
  });

  group('on a bar', () {
    final FluentBarManager manager = FluentBarManager.instance;

    Future<void> boot(WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();
    }

    Future<void> cleanup(WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pump();
    }

    testWidgets('updateBytes fits the callback of a network library and shows the amount', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withLinearProgress(showText: true).show()!;
      await tester.pump();

      final void Function(int received, int total) onReceiveProgress = entry.updateBytes;

      onReceiveProgress(3250586, 50 * mb);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(entry.item.progressState, const FluentBarProgressBytes(3250586, 50 * mb));
      expect(find.text('3.1 / 50 MB'), findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('an unknown size keeps the bar open and shows what has arrived', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withDuration(const Duration(seconds: 1)).withLinearProgress(showText: true).show()!;
      await tester.pump();

      entry.updateBytes(2 * mb, -1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('2 MB'), findsOneWidget);
      expect(FluentBar.activeItems, contains(entry), reason: 'unfinished progress never times out');

      await cleanup(tester);
    });

    testWidgets('reaching the size completes the progress and the bar leaves by itself', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      manager.addAnalyticsListener((FluentBarAnalyticsPayload payload) => events.add(payload.event));

      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withDuration(const Duration(seconds: 1)).withLinearProgress(showText: true).show()!;
      await tester.pump();

      entry.updateBytes(10 * mb, 50 * mb);
      entry.updateBytes(50 * mb, 50 * mb);
      await tester.pump();
      expect(events, contains(FluentBarAnalyticsEvent.progressCompleted));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    for (final bool circular in <bool>[false, true]) {
      testWidgets('one bar goes from endless to a normal progress and back (${circular ? 'circle' : 'line'})', (WidgetTester tester) async {
        await boot(tester);
        final FluentBarItem<void> draft = FluentBar.info<void>('Downloading');
        final FluentBarEntry<void> entry = (circular ? draft.withCircularProgress(showText: true) : draft.withLinearProgress(showText: true)).show()!;
        await tester.pump();

        double? shownValue() =>
            circular ? tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value : tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value;

        entry.updateBytes(5 * mb, null);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(shownValue(), isNull, reason: 'the size is unknown: endless');

        entry.updateBytes(25 * mb, 50 * mb);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(shownValue(), closeTo(0.5, 0.01), reason: 'the size arrived: a normal progress');

        entry.updateBytes(30 * mb, -1);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(shownValue(), isNull, reason: 'and endless again');

        await cleanup(tester);
      });
    }

    testWidgets('the percent label counts up, the combined label is shown as it is', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withLinearProgress(showText: true).show()!;
      await tester.pump();

      entry.updateBytes(25 * mb, 50 * mb, label: FluentBarBytesLabel.both);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('25 / 50 MB · 50%'), findsOneWidget);

      entry.updateBytes(25 * mb, 50 * mb, label: FluentBarBytesLabel.percent);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('50%'), findsOneWidget);

      await cleanup(tester);
    });
  });
}
