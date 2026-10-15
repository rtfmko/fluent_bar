import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  setUp(() => FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch());
  tearDown(() => FluentBarControllerImpl.stopwatchFactory = Stopwatch.new);

  Future<void> boot(WidgetTester tester, {FluentBarConfig? config}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarEntry<void> entryOf(FluentBarItem<void> item) => FluentBarEntry<void>(item: item);

  group('progress theme', () {
    test('getters return defaults, but only explicitly set values take part in merging', () {
      const FluentBarProgressTheme empty = FluentBarProgressTheme();
      expect(empty.style, FluentBarProgressStyle.linear);
      expect(empty.position, FluentBarProgressPosition.bottom);
      expect(empty.thickness, 4.0);
      expect(empty.size, 24.0);
      expect(empty.showText, isFalse);
      expect(empty.textAlign, FluentBarProgressTextAlign.right);
      expect(empty.textEffect, FluentBarProgressTextEffect.count);
      expect(empty.textEffectDuration, const Duration(milliseconds: 300));
      expect(empty.successIconDuration, isNull);

      expect(empty, isNot(const FluentBarProgressTheme(showText: false)));
      expect(empty.hashCode, isNot(const FluentBarProgressTheme(showText: false).hashCode));
    });

    test('mergedOver keeps what is set and fills the rest from the lower level, field by field', () {
      Widget builder(BuildContext c, ValueListenable<FluentBarProgressState?> n) => const SizedBox();
      String label(FluentBarProgressState s) => 'x';

      final FluentBarProgressTheme lower = FluentBarProgressTheme(
        style: FluentBarProgressStyle.circular,
        position: FluentBarProgressPosition.left,
        trackDecoration: const BoxDecoration(color: Colors.black),
        progressColor: Colors.blue,
        thickness: 9,
        size: 40,
        showText: true,
        textAlign: FluentBarProgressTextAlign.left,
        textEffect: FluentBarProgressTextEffect.roll,
        textEffectDuration: const Duration(seconds: 1),
        successIconColor: Colors.green,
        successIcon: const Icon(Icons.check),
        successIconDuration: const Duration(seconds: 2),
        textStyle: const TextStyle(fontSize: 20),
        labelBuilder: label,
        progressBuilder: builder,
      );

      expect(const FluentBarProgressTheme().mergedOver(null), const FluentBarProgressTheme());
      expect(const FluentBarProgressTheme().mergedOver(lower), lower, reason: 'an empty theme takes everything from below');

      final FluentBarProgressTheme merged = const FluentBarProgressTheme(progressColor: Colors.red, showText: false).mergedOver(lower);
      expect(merged.progressColor, Colors.red);
      expect(merged.showText, isFalse, reason: 'an explicit false is a value, not "not set"');
      expect(merged.style, FluentBarProgressStyle.circular);
      expect(merged.thickness, 9);
      expect(merged.textEffect, FluentBarProgressTextEffect.roll);
      expect(merged.successIconDuration, const Duration(seconds: 2));
      expect(merged.labelBuilder, label);
      expect(merged.progressBuilder, builder);

      expect(lower.copyWith(successIconDuration: const Duration(seconds: 5)).successIconDuration, const Duration(seconds: 5));
    });

    test('a bar built with the chain picks up global and type settings it did not set itself', () {
      const FluentBarConfig config = FluentBarConfig(
        progressTheme: FluentBarProgressTheme(thickness: 10, textEffect: FluentBarProgressTextEffect.roll, showText: true, progressColor: Colors.blue),
      );
      final FluentBarType type = FluentBarType.info.copyWith(progressTheme: const FluentBarProgressTheme(progressColor: Colors.orange));

      FluentBarProgressTheme theme = entryOf(FluentBar.custom<void>(type, 'm').withLinearProgress(value: 0.5)).resolveProgressTheme(config);
      expect(theme.style, FluentBarProgressStyle.linear);
      expect(theme.thickness, 10);
      expect(theme.textEffect, FluentBarProgressTextEffect.roll);
      expect(theme.showText, isTrue);
      expect(theme.progressColor, Colors.orange, reason: 'the type beats the config');

      theme = entryOf(FluentBar.custom<void>(type, 'm').withLinearProgress(value: 0.5, showText: false, color: Colors.red)).resolveProgressTheme(config);
      expect(theme.showText, isFalse);
      expect(theme.progressColor, Colors.red);
      expect(theme.thickness, 10);

      theme = entryOf(FluentBar.info<void>('m').withCircularProgress()).resolveProgressTheme(config);
      expect(theme.style, FluentBarProgressStyle.circular);
      expect(theme.position, FluentBarProgressPosition.replaceIcon);
      expect(theme.thickness, 10);
    });
  });

  group('duration', () {
    testWidgets('bar -> type -> config.defaultDuration', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultDuration: Duration(seconds: 9)));

      final FluentBarEntry<void> plain = FluentBar.info<void>('Plain').withId('plain').show()!;
      final FluentBarEntry<void> error = FluentBar.error<void>('Error').withId('error').atBottom().show()!;
      await settle(tester);

      expect(plain.controller.totalDurationNotifier.value, const Duration(seconds: 9), reason: 'info has no duration of its own');
      expect(error.controller.totalDurationNotifier.value, const Duration(seconds: 6), reason: 'the error type sets its own');

      await FluentBar.closeAll(skipAnimation: true);
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(defaultDuration: const Duration(seconds: 2)));
      final FluentBarEntry<void> next = FluentBar.info<void>('Next').withId('next').show()!;
      final FluentBarEntry<void> local = FluentBar.info<void>('Local').withId('local').withDuration(const Duration(seconds: 30)).atBottom().show()!;
      await settle(tester);
      expect(next.controller.totalDurationNotifier.value, const Duration(seconds: 2));
      expect(local.controller.totalDurationNotifier.value, const Duration(seconds: 30));

      expect(const FluentBarConfig(defaultDuration: Duration(seconds: 2)), isNot(const FluentBarConfig()));
      await cleanup(tester);
    });
  });

  group('timeout bar position', () {
    test('bar -> type -> config', () {
      const FluentBarConfig config = FluentBarConfig(defaultTimeoutBarPosition: FluentBarTimeoutBarPosition.bottom);
      final FluentBarType type = FluentBarType.info.copyWith(timeoutBarPosition: FluentBarTimeoutBarPosition.top);

      expect(entryOf(FluentBar.info<void>('m')).resolveTimeoutBarPosition(config), FluentBarTimeoutBarPosition.bottom);
      expect(entryOf(FluentBar.custom<void>(type, 'm')).resolveTimeoutBarPosition(config), FluentBarTimeoutBarPosition.top);
      expect(entryOf(FluentBar.custom<void>(type, 'm').withTimeoutBar(position: FluentBarTimeoutBarPosition.bottom)).resolveTimeoutBarPosition(config), FluentBarTimeoutBarPosition.bottom);

      expect(FluentBarType.info.timeoutBarPosition, isNull);
      expect(FluentBarType.guard(type).timeoutBarPosition, FluentBarTimeoutBarPosition.top);
    });

    test('the timeout bar color of a type keeps its value through copyWith', () {
      final FluentBarType type = FluentBarType.info.copyWith(timeoutBarColor: Colors.pink);
      expect(type.timeoutBarColor, Colors.pink);
      expect(FluentBarType.info.timeoutBarColor, isNull);
    });
  });

  group('haptics switch', () {
    final List<String> haptics = <String>[];

    setUp(() {
      haptics.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      });
    });

    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    testWidgets('enableHaptics: false silences both built-in and custom haptics', (WidgetTester tester) async {
      await boot(tester);
      int custom = 0;

      FluentBar.success<void>('On').withId('on').show();
      FluentBar.info<void>('Custom').withId('custom').atBottom().copyWith(callbacks: FluentBarCallbacks<void>(haptic: () => custom++)).show();
      await settle(tester);
      expect(haptics, isNotEmpty);
      expect(custom, 1);

      await FluentBar.closeAll(skipAnimation: true);
      haptics.clear();
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(enableHaptics: false));

      final FluentBarEntry<void> entry = FluentBar.success<void>('Off').withId('off').withLinearProgress(value: 0.2).show()!;
      FluentBar.info<void>('Custom off')
          .withId('custom_off')
          .atBottom()
          .copyWith(
            callbacks: FluentBarCallbacks<void>(haptic: () => custom++, progressCompletedHaptic: () => custom++),
          )
          .show();
      await settle(tester);
      entry.completeProgress();
      FluentBar.find('custom_off')!.controller.updateProgress(const FluentBarProgressState.value(1.0));
      await settle(tester);

      expect(haptics, isEmpty);
      expect(custom, 1, reason: 'custom haptic callbacks are not called either');
      expect(const FluentBarConfig(enableHaptics: false), isNot(const FluentBarConfig()));

      await cleanup(tester);
    });
  });

  group('indicator layout', () {
    testWidgets('every style, position and kind of progress fits into the bar, with and without text', (WidgetTester tester) async {
      const List<FluentBarProgressState> states = <FluentBarProgressState>[
        FluentBarProgressState.value(0.42),
        FluentBarProgressState.fraction(17, 20),
        FluentBarProgressState.indeterminate(),
        FluentBarProgressState.value(1.0),
      ];

      for (final FluentBarProgressStyle style in FluentBarProgressStyle.values) {
        for (final FluentBarProgressPosition position in FluentBarProgressPosition.values) {
          for (final bool showText in <bool>[true, false]) {
            for (final FluentBarProgressState state in states) {
              await boot(tester);
              FluentBar.info<void>('Message')
                  .withTitle('Title')
                  .withId('layout')
                  .withProgress(state)
                  .copyWith(
                    appearance: FluentBarAppearance<void>(
                      progressTheme: FluentBarProgressTheme(style: style, position: position, showText: showText),
                    ),
                  )
                  .show();
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));

              expect(tester.takeException(), isNull, reason: '$style / $position / showText: $showText / $state');
              expect(find.text('Message'), findsOneWidget);
            }
          }
        }
      }

      await cleanup(tester);
    });

    testWidgets('a linear indicator in the icon slot keeps its label inside the slot', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('Message').withId('layout').withLinearProgress(state: const FluentBarProgressState.fraction(17, 20), showText: true, position: FluentBarProgressPosition.replaceIcon).show();
      await settle(tester);

      final Rect slot = tester.getRect(find.byType(FluentBarTaskProgressWidget));
      final Rect label = tester.getRect(find.byType(FluentBarProgressLabel));
      expect(find.text('85%'), findsOneWidget);
      expect(slot.width, lessThanOrEqualTo(24));
      expect(slot.height, lessThanOrEqualTo(24));
      expect(slot.contains(label.topLeft) && slot.contains(label.bottomRight - const Offset(0.01, 0.01)), isTrue);
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    group('in place of the icon only the percent is shown', () {
      Future<void> showInIcon(WidgetTester tester, FluentBarProgressState state, {bool isCircular = false, String Function(FluentBarProgressState state)? labelBuilder}) async {
        await boot(tester);
        if (labelBuilder != null) FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(labelBuilder: labelBuilder)));
        final FluentBarItem<void> item = FluentBar.info<void>('Message').withId('layout');
        (isCircular ? item.withCircularProgress(state: state, showText: true) : item.withLinearProgress(state: state, showText: true, position: FluentBarProgressPosition.replaceIcon)).show();
        await settle(tester);
      }

      for (final bool isCircular in <bool>[false, true]) {
        final String kind = isCircular ? 'ring' : 'line';

        testWidgets('$kind: a fraction shows its percent', (WidgetTester tester) async {
          await showInIcon(tester, const FluentBarProgressState.fraction(3, 4), isCircular: isCircular);
          expect(find.text('75%'), findsOneWidget);
          expect(find.textContaining('/'), findsNothing);
          await cleanup(tester);
        });

        testWidgets('$kind: bytes with a total show their percent', (WidgetTester tester) async {
          await showInIcon(tester, const FluentBarProgressState.bytes(5242880, 20971520), isCircular: isCircular);
          expect(find.text('25%'), findsOneWidget);
          expect(find.textContaining('MB'), findsNothing);
          await cleanup(tester);
        });

        testWidgets('$kind: bytes without a total show no text', (WidgetTester tester) async {
          await showInIcon(tester, const FluentBarProgressState.bytes(5242880, null), isCircular: isCircular);
          expect(find.byType(FluentBarProgressLabel), findsNothing);
          expect(find.textContaining('MB'), findsNothing);
          await cleanup(tester);
        });

        testWidgets('$kind: a custom label gives way to the percent', (WidgetTester tester) async {
          await showInIcon(tester, const FluentBarProgressState.value(0.4), isCircular: isCircular, labelBuilder: (FluentBarProgressState state) => 'Custom label');
          expect(find.text('40%'), findsOneWidget);
          expect(find.text('Custom label'), findsNothing);
          await cleanup(tester);
        });
      }

      testWidgets('outside the icon slot a fraction keeps its own text', (WidgetTester tester) async {
        await boot(tester);
        FluentBar.info<void>('Message').withId('layout').withLinearProgress(state: const FluentBarProgressState.fraction(3, 4), showText: true).show();
        await settle(tester);
        expect(find.text('3 / 4'), findsOneWidget);
        await cleanup(tester);
      });
    });

    testWidgets('completing a linear progress with text does not change the size of the bar', (WidgetTester tester) async {
      for (final FluentBarProgressPosition position in <FluentBarProgressPosition>[FluentBarProgressPosition.bottom, FluentBarProgressPosition.top]) {
        await boot(tester);
        final FluentBarEntry<void> entry = FluentBar.info<void>(
          'Message',
        ).withId('layout').withLinearProgress(value: 0.4, showText: true, position: position).withDuration(const Duration(seconds: 30)).show()!;
        await settle(tester);
        final Rect before = tester.getRect(find.byType(DefaultFluentBarWidget<void>));

        entry.updateValue(1.0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.getRect(find.byType(DefaultFluentBarWidget<void>)), before, reason: '$position, mid-transition');
        await tester.pump(const Duration(seconds: 1));
        expect(tester.getRect(find.byType(DefaultFluentBarWidget<void>)), before, reason: '$position, settled');
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      }

      await cleanup(tester);
    });
  });

  group('success icon', () {
    Future<void> pumpIndicator(WidgetTester tester, ValueNotifier<FluentBarProgressState?> notifier, FluentBarProgressTheme theme, {Widget? afterSuccess}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FluentBarTaskProgressWidget(
            progressNotifier: notifier,
            theme: theme,
            defaultColor: Colors.white,
            successIcon: const Icon(Icons.check_circle, key: Key('success')),
            afterSuccess: afterSuccess,
          ),
        ),
      ),
    );

    testWidgets('stays forever by default', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressState.value(1.0));
      addTearDown(notifier.dispose);

      await pumpIndicator(tester, notifier, const FluentBarProgressTheme());
      await tester.pump(const Duration(minutes: 1));

      expect(find.byKey(const Key('success')), findsOneWidget);
    });

    testWidgets('with successIconDuration it is shown, then collapses; a new progress brings the indicator back', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressState.value(0.5));
      addTearDown(notifier.dispose);
      const FluentBarProgressTheme theme = FluentBarProgressTheme(successIconDuration: Duration(seconds: 2));

      await pumpIndicator(tester, notifier, theme);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      notifier.value = const FluentBarProgressState.value(1.0);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('success')), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('success')), findsNothing, reason: 'the success icon is gone after its time');
      expect(tester.getSize(find.byType(AnimatedSize)).height, 0);

      notifier.value = const FluentBarProgressState.value(0.1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('afterSuccess takes the place of the icon; turning the duration off restores it', (WidgetTester tester) async {
      final ValueNotifier<FluentBarProgressState?> first = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressState.value(1.0));
      final ValueNotifier<FluentBarProgressState?> second = ValueNotifier<FluentBarProgressState?>(const FluentBarProgressState.value(1.0));
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      const FluentBarProgressTheme theme = FluentBarProgressTheme(successIconDuration: Duration(seconds: 1));
      const Widget regularIcon = Icon(Icons.info, key: Key('regular'));

      await pumpIndicator(tester, first, theme, afterSuccess: regularIcon);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('regular')), findsOneWidget);
      expect(find.byKey(const Key('success')), findsNothing);

      await pumpIndicator(tester, second, const FluentBarProgressTheme(), afterSuccess: regularIcon);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('success')), findsOneWidget);
    });

    testWidgets('in a real bar the regular icon returns to the icon slot', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.success<void>('Uploading')
          .withId('upload')
          .withCircularProgress(value: 0.3)
          .copyWith(
            appearance: const FluentBarAppearance<void>(
              progressTheme: FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.replaceIcon, successIconDuration: Duration(seconds: 1)),
            ),
          )
          .withDuration(const Duration(seconds: 30))
          .show()!;
      await settle(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      entry.completeProgress();
      await settle(tester);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget, reason: 'the regular icon of the success type');

      await cleanup(tester);
    });
  });
}
