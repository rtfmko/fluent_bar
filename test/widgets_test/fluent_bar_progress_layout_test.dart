import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });
  tearDown(() => FluentBar.removeErrorHandler(onError));

  Widget progress(FluentBarProgressState state, FluentBarProgressTheme theme) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 240,
          child: FluentBarTaskProgressWidget(progressNotifier: ValueNotifier<FluentBarProgressState?>(state), theme: theme, defaultColor: Colors.white, successIcon: const Icon(Icons.check)),
        ),
      ),
    ),
  );

  group('text placement', () {
    testWidgets('circular in a compact position: the text is centered inside the ring', (WidgetTester tester) async {
      for (final FluentBarProgressPosition position in <FluentBarProgressPosition>[FluentBarProgressPosition.left, FluentBarProgressPosition.right, FluentBarProgressPosition.replaceIcon]) {
        await tester.pumpWidget(progress(const FluentBarProgressFraction(1, 5), FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: position, showText: true, size: 40)));
        await tester.pumpAndSettle();

        final Rect ring = tester.getRect(find.byType(CircularProgressIndicator));
        final Rect label = tester.getRect(find.byType(FluentBarProgressLabel));
        expect(ring.size, const Size(40, 40), reason: position.name);
        expect(ring.contains(label.center), isTrue, reason: position.name);
        expect((label.center - ring.center).distance, lessThan(1.0), reason: position.name);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('circular at top/bottom: the text is beside the ring, on the chosen side', (WidgetTester tester) async {
      Future<(Rect, Rect)> rects(FluentBarProgressTextAlign align) async {
        await tester.pumpWidget(
          progress(const FluentBarProgressValue(0.5), FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.bottom, showText: true, textAlign: align)),
        );
        await tester.pumpAndSettle();
        return (tester.getRect(find.byType(CircularProgressIndicator)), tester.getRect(find.byType(FluentBarProgressLabel)));
      }

      final (Rect ringR, Rect labelR) = await rects(FluentBarProgressTextAlign.right);
      expect(labelR.left, greaterThan(ringR.right));

      final (Rect ringL, Rect labelL) = await rects(FluentBarProgressTextAlign.left);
      expect(labelL.right, lessThan(ringL.left));

      final (Rect ringC, Rect labelC) = await rects(FluentBarProgressTextAlign.center);
      expect(ringC.contains(labelC.center), isTrue);
    });

    testWidgets('linear: the text is under the bar and aligned as configured', (WidgetTester tester) async {
      Future<(Rect, Rect)> rects(FluentBarProgressTextAlign align) async {
        await tester.pumpWidget(progress(const FluentBarProgressValue(0.5), FluentBarProgressTheme(showText: true, textAlign: align)));
        await tester.pumpAndSettle();
        return (tester.getRect(find.byType(LinearProgressIndicator)), tester.getRect(find.byType(FluentBarProgressLabel)));
      }

      final (Rect barL, Rect labelL) = await rects(FluentBarProgressTextAlign.left);
      expect(labelL.top, greaterThan(barL.bottom));
      expect(labelL.left, closeTo(barL.left, 0.5));

      final (Rect barR, Rect labelR) = await rects(FluentBarProgressTextAlign.right);
      expect(labelR.right, closeTo(barR.right, 0.5));

      final (Rect barC, Rect labelC) = await rects(FluentBarProgressTextAlign.center);
      expect(labelC.center.dx, closeTo(barC.center.dx, 0.5));
    });

    testWidgets('a track decoration wraps the linear bar', (WidgetTester tester) async {
      const BoxDecoration track = BoxDecoration(color: Colors.black);
      await tester.pumpWidget(progress(const FluentBarProgressValue(0.5), const FluentBarProgressTheme(trackDecoration: track)));

      final DecoratedBox box = tester.widget<DecoratedBox>(find.ancestor(of: find.byType(LinearProgressIndicator), matching: find.byType(DecoratedBox)).first);
      expect(box.decoration, track);
    });
  });

  group('labels', () {
    testWidgets('a custom label builder is used as is', (WidgetTester tester) async {
      await tester.pumpWidget(progress(const FluentBarProgressFraction(2, 5), FluentBarProgressTheme(showText: true, labelBuilder: (FluentBarProgressState state) => 'step two')));
      await tester.pumpAndSettle();

      expect(tester.widget<FluentBarProgressLabel>(find.byType(FluentBarProgressLabel)).text, 'step two');
    });

    testWidgets('a throwing label builder is reported and the default label is shown', (WidgetTester tester) async {
      await tester.pumpWidget(progress(const FluentBarProgressFraction(2, 5), FluentBarProgressTheme(showText: true, labelBuilder: (FluentBarProgressState state) => throw Exception('boom'))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.widget<FluentBarProgressLabel>(find.byType(FluentBarProgressLabel)).text, '2 / 5');
      expect(errors.map((FluentBarException e) => e.type), contains(FluentBarErrorType.fluentBarResolver));
    });

    testWidgets('a custom text style is applied', (WidgetTester tester) async {
      const TextStyle style = TextStyle(fontSize: 22, color: Colors.orange);
      await tester.pumpWidget(progress(const FluentBarProgressValue(0.5), const FluentBarProgressTheme(showText: true, textStyle: style)));
      await tester.pumpAndSettle();

      final TextStyle applied = tester.widget<FluentBarProgressLabel>(find.byType(FluentBarProgressLabel)).style;
      expect(applied.fontSize, 22);
      expect(applied.color, Colors.orange);
      expect(applied.fontFeatures, const <FontFeature>[FontFeature.tabularFigures()], reason: 'digits must not jump in width');
    });
  });

  group('success icon in the default bar widget', () {
    Future<double> successIconSize(WidgetTester tester, FluentBarProgressTheme theme) async {
      final FluentBarEntry<void> entry = FluentBarEntry<void>(
        item: FluentBarItem<void>(
          type: FluentBarType.info,
          message: 'Done',
          progressState: const FluentBarProgressValue(1.0),
          appearance: FluentBarAppearance<void>(progressTheme: theme, iconSize: 30),
        ),
      );
      addTearDown(entry.internalController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultFluentBarWidget<void>(entry: entry, config: const FluentBarConfig()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return tester.widget<Icon>(find.descendant(of: find.byKey(const ValueKey<String>('success_icon')), matching: find.byType(Icon))).size!;
    }

    testWidgets('circular beside the content: the icon matches the diameter of the ring', (WidgetTester tester) async {
      const FluentBarProgressTheme theme = FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.left, size: 44);
      expect(await successIconSize(tester, theme), 44);
    });

    testWidgets('linear, or replacing the icon: the icon matches the icon size of the bar', (WidgetTester tester) async {
      expect(await successIconSize(tester, const FluentBarProgressTheme(size: 44)), 30);
      expect(await successIconSize(tester, const FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.replaceIcon, size: 44)), 30);
    });
  });

  group('action button while loading', () {
    testWidgets('a tap is swallowed: neither the action nor the bar tap handler fires', (WidgetTester tester) async {
      int pressed = 0;
      int barTaps = 0;
      final FluentBarEntry<void> entry = FluentBarEntry<void>(
        item: FluentBarItem<void>(type: FluentBarType.info, message: 'Bar', isPersistent: true),
      );
      entry.internalController.changeState(FluentBarLifecycleState.visible);
      addTearDown(entry.internalController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GestureDetector(
                onTap: () => barTaps++,
                child: FluentBarAction<void>(
                  controller: entry.controller,
                  closeOnAction: false,
                  loaderColor: Colors.white,
                  throttleDuration: Duration.zero,
                  onPressed: (FluentBarController<void> controller, void payload) => pressed++,
                  child: const Padding(padding: EdgeInsets.all(12), child: Text('ACTION')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ACTION'));
      await tester.pump();
      expect(pressed, 1);
      expect(barTaps, 0);

      entry.controller.setLoading(isLoading: true);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('ACTION'), warnIfMissed: false);
      await tester.pump();
      expect(pressed, 1, reason: 'the action must not run twice');
      expect(barTaps, 0, reason: 'the tap must not leak to the bar and dismiss it');

      entry.controller.setLoading(isLoading: false);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('ACTION'));
      await tester.pump();
      expect(pressed, 2);
    });
  });
}
