import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const TextStyle style = TextStyle(fontSize: 20, height: 1.0);
  const Duration duration = Duration(milliseconds: 300);

  Widget label(String text, FluentBarProgressTextEffect effect, {double? value, Duration effectDuration = duration, bool reduceMotion = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: FluentBarProgressLabel(text: text, style: style, effect: effect, duration: effectDuration, value: value),
      ),
    ),
  );

  String rendered(WidgetTester tester) => tester.widgetList<Text>(find.byType(Text)).map((Text t) => t.data).join();

  group('every effect', () {
    for (final FluentBarProgressTextEffect effect in FluentBarProgressTextEffect.values) {
      testWidgets('${effect.name}: shows the text, and after the transition only the new text is left', (WidgetTester tester) async {
        await tester.pumpWidget(label('41%', effect, value: 0.41));
        expect(rendered(tester), '41%');

        await tester.pumpWidget(label('42%', effect, value: 0.42));
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull);
        expect(rendered(tester), contains('2'));

        await tester.pumpAndSettle();
        expect(rendered(tester), '42%');
      });

      testWidgets('${effect.name}: handles a change in the number of characters and a full replacement', (WidgetTester tester) async {
        await tester.pumpWidget(label('9%', effect, value: 0.09));
        await tester.pumpWidget(label('10%', effect, value: 0.10));
        await tester.pumpAndSettle();
        expect(rendered(tester), '10%');

        await tester.pumpWidget(label('3 / 5', effect, value: 0.6));
        await tester.pumpAndSettle();
        expect(rendered(tester), '3 / 5');

        await tester.pumpWidget(label('', effect));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(rendered(tester), '');
      });
    }
  });

  group('none and count', () {
    testWidgets('change the text instantly, without a transition', (WidgetTester tester) async {
      for (final FluentBarProgressTextEffect effect in <FluentBarProgressTextEffect>[FluentBarProgressTextEffect.none, FluentBarProgressTextEffect.count]) {
        await tester.pumpWidget(label('41%', effect));
        await tester.pumpWidget(label('42%', effect));

        expect(rendered(tester), '42%');
        expect(find.byType(AnimatedSwitcher), findsNothing);
      }
    });
  });

  group('whole-label effects (fade, pop)', () {
    for (final FluentBarProgressTextEffect effect in <FluentBarProgressTextEffect>[FluentBarProgressTextEffect.fade, FluentBarProgressTextEffect.pop]) {
      testWidgets('${effect.name}: old and new labels overlap during the transition', (WidgetTester tester) async {
        await tester.pumpWidget(label('41%', effect));
        await tester.pumpWidget(label('42%', effect));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('41%'), findsOneWidget);
        expect(find.text('42%'), findsOneWidget);
      });

      testWidgets('${effect.name}: the same text does not start a transition', (WidgetTester tester) async {
        await tester.pumpWidget(label('41%', effect, value: 0.41));
        await tester.pumpWidget(label('41%', effect, value: 0.415));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('41%'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      });
    }
  });

  group('per-character effects (roll, flip)', () {
    for (final FluentBarProgressTextEffect effect in <FluentBarProgressTextEffect>[FluentBarProgressTextEffect.roll, FluentBarProgressTextEffect.flip]) {
      testWidgets('${effect.name}: only the characters that changed are animated', (WidgetTester tester) async {
        await tester.pumpWidget(label('41%', effect, value: 0.41));
        await tester.pumpWidget(label('42%', effect, value: 0.42));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('4'), findsOneWidget);
        expect(find.text('%'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('${effect.name}: digits keep their place when a new digit appears on the left', (WidgetTester tester) async {
        await tester.pumpWidget(label('9%', effect, value: 0.09));
        final double percentBefore = tester.getTopRight(find.text('%')).dx;

        await tester.pumpWidget(label('19%', effect, value: 0.19));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('9'), findsOneWidget);
        expect(find.text('%'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(rendered(tester), '19%');
        expect(tester.getTopRight(find.text('%')).dx, greaterThanOrEqualTo(percentBefore));
      });
    }

    testWidgets('roll: digits move up when the value grows and down when it falls', (WidgetTester tester) async {
      Future<double> incomingOffset(String from, double fromValue, String to, double toValue) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(label(from, FluentBarProgressTextEffect.roll, value: fromValue));
        final double restingY = tester.getCenter(find.text(from)).dy;

        await tester.pumpWidget(label(to, FluentBarProgressTextEffect.roll, value: toValue));
        await tester.pump(const Duration(milliseconds: 60));
        final double incomingY = tester.getCenter(find.text(to)).dy;
        await tester.pumpAndSettle();
        return incomingY - restingY;
      }

      expect(await incomingOffset('1', 0.1, '2', 0.2), greaterThan(0));
      expect(await incomingOffset('2', 0.2, '1', 0.1), lessThan(0));
    });

    testWidgets('roll: without a value the direction stays "up"', (WidgetTester tester) async {
      await tester.pumpWidget(label('1', FluentBarProgressTextEffect.roll));
      final double restingY = tester.getCenter(find.text('1')).dy;

      await tester.pumpWidget(label('2', FluentBarProgressTextEffect.roll));
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.getCenter(find.text('2')).dy, greaterThan(restingY));
      await tester.pumpAndSettle();
    });
  });

  group('quick changes', () {
    double opacityOf(Element element) {
      double opacity = 1.0;
      element.visitAncestorElements((Element ancestor) {
        final Widget widget = ancestor.widget;
        if (widget is Opacity) opacity *= widget.opacity;
        if (widget is FadeTransition) opacity *= widget.opacity.value;
        return true;
      });
      return opacity;
    }

    double brightestText(WidgetTester tester) => tester.elementList(find.byType(Text)).map(opacityOf).fold(0.0, (double a, double b) => a > b ? a : b);

    for (final FluentBarProgressTextEffect effect in <FluentBarProgressTextEffect>[FluentBarProgressTextEffect.fade, FluentBarProgressTextEffect.pop]) {
      testWidgets('${effect.name}: the label never dims during a change', (WidgetTester tester) async {
        await tester.pumpWidget(label('41%', effect, value: 0.41));
        await tester.pumpWidget(label('42%', effect, value: 0.42));
        double darkest = 1.0;
        for (int frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final double brightest = brightestText(tester);
          if (brightest < darkest) darkest = brightest;
        }
        expect(darkest, greaterThan(0.9));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('roll: characters slide without fading', (WidgetTester tester) async {
      await tester.pumpWidget(label('41%', FluentBarProgressTextEffect.roll, value: 0.41));
      await tester.pumpWidget(label('42%', FluentBarProgressTextEffect.roll, value: 0.42));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(tester.elementList(find.byType(Text)).map(opacityOf), everyElement(1.0));
      await tester.pumpAndSettle();
    });

    for (final FluentBarProgressTextEffect effect in <FluentBarProgressTextEffect>[
      FluentBarProgressTextEffect.fade,
      FluentBarProgressTextEffect.pop,
      FluentBarProgressTextEffect.roll,
      FluentBarProgressTextEffect.flip,
    ]) {
      testWidgets('${effect.name}: a change plays to the end, values that came meanwhile are skipped and the last one plays next', (WidgetTester tester) async {
        await tester.pumpWidget(label('1%', effect, value: 0.01));
        await tester.pumpWidget(label('2%', effect, value: 0.02));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(label('3%', effect, value: 0.03));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpWidget(label('4%', effect, value: 0.04));
        await tester.pump(const Duration(milliseconds: 50));

        expect(rendered(tester), contains('2'));
        expect(rendered(tester), isNot(contains('4')));

        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('3'), findsNothing);
        expect(find.text('3%'), findsNothing);

        await tester.pumpAndSettle();
        expect(rendered(tester), '4%');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('changes start at most every 120 ms, even with a shorter duration', (WidgetTester tester) async {
      const Duration short = Duration(milliseconds: 40);
      await tester.pumpWidget(label('1%', FluentBarProgressTextEffect.fade, value: 0.01, effectDuration: short));
      await tester.pumpWidget(label('2%', FluentBarProgressTextEffect.fade, value: 0.02, effectDuration: short));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpWidget(label('3%', FluentBarProgressTextEffect.fade, value: 0.03, effectDuration: short));
      await tester.pump(const Duration(milliseconds: 30));

      expect(rendered(tester), '2%');

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(rendered(tester), '3%');
    });

    testWidgets('a value that returns to the shown text before its turn plays nothing', (WidgetTester tester) async {
      await tester.pumpWidget(label('1%', FluentBarProgressTextEffect.fade, value: 0.01));
      await tester.pumpWidget(label('2%', FluentBarProgressTextEffect.fade, value: 0.02));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(label('3%', FluentBarProgressTextEffect.fade, value: 0.03));
      await tester.pumpWidget(label('2%', FluentBarProgressTextEffect.fade, value: 0.02));
      await tester.pump(const Duration(milliseconds: 250));

      expect(rendered(tester), '2%');
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('switching to an effect without animation shows the latest text at once', (WidgetTester tester) async {
      await tester.pumpWidget(label('1%', FluentBarProgressTextEffect.flip, value: 0.01));
      await tester.pumpWidget(label('2%', FluentBarProgressTextEffect.flip, value: 0.02));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(label('3%', FluentBarProgressTextEffect.none, value: 0.03));

      expect(rendered(tester), '3%');
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('accessibility and edge cases', () {
    testWidgets('with "reduce motion" enabled every effect switches instantly', (WidgetTester tester) async {
      for (final FluentBarProgressTextEffect effect in FluentBarProgressTextEffect.values) {
        await tester.pumpWidget(label('41%', effect, reduceMotion: true));
        await tester.pumpWidget(label('42%', effect, reduceMotion: true));

        expect(rendered(tester), '42%', reason: effect.name);
        expect(tester.hasRunningAnimations, isFalse, reason: effect.name);
      }
    });

    testWidgets('a zero duration switches instantly', (WidgetTester tester) async {
      await tester.pumpWidget(label('41%', FluentBarProgressTextEffect.roll, effectDuration: Duration.zero));
      await tester.pumpWidget(label('42%', FluentBarProgressTextEffect.roll, effectDuration: Duration.zero));

      expect(rendered(tester), '42%');
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('fast consecutive updates end on the latest text', (WidgetTester tester) async {
      for (final FluentBarProgressTextEffect effect in FluentBarProgressTextEffect.values) {
        await tester.pumpWidget(const SizedBox());
        for (int i = 0; i <= 20; i++) {
          await tester.pumpWidget(label('$i%', effect, value: i / 100));
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: effect.name);
        expect(rendered(tester), '20%', reason: effect.name);
      }
    });

    testWidgets('the effect can be changed on the fly', (WidgetTester tester) async {
      await tester.pumpWidget(label('1%', FluentBarProgressTextEffect.roll, value: 0.01));
      await tester.pumpWidget(label('2%', FluentBarProgressTextEffect.pop, value: 0.02));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(label('3%', FluentBarProgressTextEffect.flip, value: 0.03));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(rendered(tester), '3%');
    });
  });

  group('inside FluentBarTaskProgressWidget', () {
    Widget progress(ValueNotifier<FluentBarProgressState?> notifier, FluentBarProgressTheme theme, {FluentBarProgressTextEffect? textEffect}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: FluentBarTaskProgressWidget(progressNotifier: notifier, theme: theme, textEffect: textEffect, defaultColor: Colors.white, successIcon: const Icon(Icons.check)),
          ),
        ),
      ),
    );

    FluentBarProgressLabel labelOf(WidgetTester tester) => tester.widget<FluentBarProgressLabel>(find.byType(FluentBarProgressLabel));

    testWidgets('the effect and duration come from the progress theme', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressFraction(1, 5));
      addTearDown(notifier.dispose);

      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(showText: true, textEffect: FluentBarProgressTextEffect.flip, textEffectDuration: Duration(milliseconds: 700))));

      expect(labelOf(tester).effect, FluentBarProgressTextEffect.flip);
      expect(labelOf(tester).duration, const Duration(milliseconds: 700));
      expect(labelOf(tester).text, '1 / 5');
      expect(labelOf(tester).value, 0.2);
    });

    testWidgets('an explicit effect overrides the theme', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressValue(0.5));
      addTearDown(notifier.dispose);

      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(showText: true, textEffect: FluentBarProgressTextEffect.flip), textEffect: FluentBarProgressTextEffect.roll));
      await tester.pumpAndSettle();

      expect(labelOf(tester).effect, FluentBarProgressTextEffect.roll);
    });

    testWidgets('count (default) counts percents up; other effects show the target value at once', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressValue(0.0));
      addTearDown(notifier.dispose);

      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(showText: true)));
      await tester.pumpAndSettle();
      notifier.value = const FluentBarProgressValue(0.8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final int midway = int.parse(labelOf(tester).text.replaceAll('%', ''));
      expect(midway, inExclusiveRange(0, 80), reason: 'the number is still counting');
      await tester.pumpAndSettle();
      expect(labelOf(tester).text, '80%');

      notifier.value = const FluentBarProgressValue(0.0);
      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(showText: true, textEffect: FluentBarProgressTextEffect.roll)));
      await tester.pumpAndSettle();
      notifier.value = const FluentBarProgressValue(0.8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(labelOf(tester).text, '80%', reason: 'the label animates the change itself, the string is not interpolated');
      await tester.pumpAndSettle();
    });

    testWidgets('fractions roll digit by digit', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressFraction(1, 5));
      addTearDown(notifier.dispose);

      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(showText: true, textEffect: FluentBarProgressTextEffect.roll)));
      await tester.pumpAndSettle();
      notifier.value = const FluentBarProgressFraction(2, 5);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget, reason: 'the total does not change and is not animated');

      await tester.pumpAndSettle();
      expect(find.text('1'), findsNothing);
    });

    testWidgets('no label is built when the text is hidden or the progress is indeterminate', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressValue(0.5));
      addTearDown(notifier.dispose);

      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(textEffect: FluentBarProgressTextEffect.roll)));
      expect(find.byType(FluentBarProgressLabel), findsNothing);

      notifier.value = const FluentBarProgressIndeterminate();
      await tester.pumpWidget(progress(notifier, const FluentBarProgressTheme(showText: true, textEffect: FluentBarProgressTextEffect.roll)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FluentBarProgressLabel), findsNothing);
    });
  });
}
