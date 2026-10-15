import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ColorlessTheme extends FluentBarTheme {
  const _ColorlessTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => const BoxDecoration(color: Color(0xFF263238));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(fontSize: 15);

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(fontSize: 13);

  @override
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(fontSize: 13);
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester, {FluentBarConfig? config}) async {
    manager.resetForTesting();
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

  void turnOnReduceMotion(WidgetTester tester, {bool android = false}) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(reduceMotion: !android, disableAnimations: android);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Finder ancestorOf(String text, Type type) => find.ancestor(of: find.text(text), matching: find.byType(type));

  Color backgroundOf(WidgetTester tester, String text) => (tester.widget<Container>(ancestorOf(text, Container).first).decoration! as BoxDecoration).color!;

  group('reduce motion', () {
    testWidgets('the config follows the system setting unless told otherwise', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );

      const FluentBarConfig following = FluentBarConfig();
      const FluentBarConfig independent = FluentBarConfig(respectSystemReduceMotion: false);
      expect(following.respectSystemReduceMotion, isTrue);
      expect(following.reducesMotion(context), isFalse);

      turnOnReduceMotion(tester);
      await tester.pump();
      expect(following.reducesMotion(context), isTrue);
      expect(independent.reducesMotion(context), isFalse);

      turnOnReduceMotion(tester, android: true);
      await tester.pump();
      expect(following.reducesMotion(context), isTrue);
      expect(independent.reducesMotion(context), isFalse);

      expect(following.copyWith(respectSystemReduceMotion: false), independent);
      expect(following, isNot(independent));
      expect(following.hashCode, isNot(independent.hashCode));
    });

    testWidgets('a bar fades in instead of sliding, and its own transition builder is not used', (WidgetTester tester) async {
      turnOnReduceMotion(tester);
      await boot(tester);
      int customTransitions = 0;

      FluentBar.info<void>('Sliding').withId('a').persistent().swipeable(false).withEntrance(FluentBarEntranceAnimation.bouncingSlide).show();
      FluentBar.show<void>(
        message: 'Custom',
        id: 'b',
        isPersistent: true,
        options: FluentBarOptions<void>(
          behavior: const FluentBarBehavior(position: FluentBarPosition.bottom, isSwipeEnabled: false),
          appearance: FluentBarAppearance<void>(
            transitionBuilder: (BuildContext context, Animation<double> animation, Widget child) {
              customTransitions++;
              return ScaleTransition(scale: animation, child: child);
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(ancestorOf('Sliding', SlideTransition), findsNothing);
      expect(ancestorOf('Custom', ScaleTransition), findsNothing);
      expect(customTransitions, 0);
      final double opacity = tester.widget<FadeTransition>(ancestorOf('Sliding', FadeTransition).last).opacity.value;
      expect(opacity, greaterThan(0.0));
      expect(opacity, lessThan(1.0));

      await settle(tester);
      expect(tester.widget<FadeTransition>(ancestorOf('Sliding', FadeTransition).last).opacity.value, 1.0);

      await cleanup(tester);
    });

    testWidgets('with the Android setting there is no slide and no attention effect either', (WidgetTester tester) async {
      turnOnReduceMotion(tester, android: true);
      await boot(tester);

      final FluentBarEntry<void> entry = FluentBar.info<void>('Sliding').withId('a').persistent().swipeable(false).withEntrance(FluentBarEntranceAnimation.bouncingSlide).show()!;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(ancestorOf('Sliding', SlideTransition), findsNothing);
      expect(tester.widget<FadeTransition>(ancestorOf('Sliding', FadeTransition).last).opacity.value, 1.0);

      entry.heartbeat(repeat: true);
      await settle(tester);
      expect(tester.binding.transientCallbackCount, 0);

      await cleanup(tester);
    });

    testWidgets('an app that does not follow the setting keeps its motion', (WidgetTester tester) async {
      turnOnReduceMotion(tester);
      await boot(tester, config: const FluentBarConfig(respectSystemReduceMotion: false));

      final FluentBarEntry<void> entry = FluentBar.info<void>('Sliding').withId('a').persistent().swipeable(false).withEntrance(FluentBarEntranceAnimation.bouncingSlide).show()!;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(ancestorOf('Sliding', SlideTransition), findsOneWidget);

      await settle(tester);
      entry.heartbeat(repeat: true);
      await settle(tester);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await cleanup(tester);
    });

    testWidgets('attention effects are not played; one that is running stops when the setting is turned on', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Calm').withId('a').persistent().show()!;
      await settle(tester);
      expect(tester.binding.transientCallbackCount, 0);

      entry.heartbeat(repeat: true);
      await settle(tester);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      turnOnReduceMotion(tester);
      await settle(tester);
      expect(tester.binding.transientCallbackCount, 0);

      entry
        ..shake()
        ..bounce()
        ..pulse(repeat: true);
      await settle(tester);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('the icon changes at once, while without the setting the old and the new one cross over', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Icon').withId('a').persistent().show()!;
      await settle(tester);

      entry.controller.updateContent(type: FluentBarType.success);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await settle(tester);

      FluentBar.dismissAndClear();
      turnOnReduceMotion(tester);
      await settle(tester);
      final FluentBarEntry<void> calm = FluentBar.info<void>('Calm').withId('b').persistent().show()!;
      await settle(tester);

      calm.controller.updateContent(type: FluentBarType.error);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await cleanup(tester);
    });
  });

  group('restyle', () {
    testWidgets('a color fade starts from the current color and is instant on the first build and with a zero duration', (WidgetTester tester) async {
      Color? seen;
      Widget fade(Color color, {Duration duration = kFluentBarRestyleDuration}) => FluentBarColorFade(
        color: color,
        duration: duration,
        builder: (BuildContext context, Color? value) {
          seen = value;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(fade(Colors.red));
      expect(seen, Colors.red);

      await tester.pumpWidget(fade(Colors.blue));
      await tester.pump(const Duration(milliseconds: 150));
      expect(seen, isNot(Colors.red));
      expect(seen, isNot(Colors.blue));
      await tester.pump(const Duration(milliseconds: 150));
      expect(seen!.toARGB32(), Colors.blue.toARGB32());

      await tester.pumpWidget(fade(Colors.green, duration: Duration.zero));
      await tester.pump();
      expect(seen!.toARGB32(), Colors.green.toARGB32());
    });

    testWidgets('a color that is not set is not faded to or from: it just appears or goes', (WidgetTester tester) async {
      Color? seen = Colors.pink;
      Widget fade(Color? color) => FluentBarColorFade(
        color: color,
        builder: (BuildContext context, Color? value) {
          seen = value;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(fade(null));
      expect(seen, isNull);

      await tester.pumpWidget(fade(Colors.red));
      await tester.pump(const Duration(milliseconds: 100));
      expect(seen, Colors.red);

      await tester.pumpWidget(fade(null));
      await tester.pump(const Duration(milliseconds: 100));
      expect(seen, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a theme without its own text and icon colors works, also when the bar switches to and from it', (WidgetTester tester) async {
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message')
          .withId('a')
          .withTitle('Title')
          .withTheme(const _ColorlessTheme())
          .withDuration(const Duration(seconds: 30))
          .withTimeoutBar()
          .withAction('Action', closeOnAction: false)
          .withLinearProgress(value: 0.4, showText: true)
          .show()!;
      await settle(tester);
      expect(find.text('Title'), findsOneWidget);
      expect(backgroundOf(tester, 'Message'), const Color(0xFF263238));

      for (final FluentBarTheme theme in <FluentBarTheme>[FluentBarTheme.material, const _ColorlessTheme(), FluentBarTheme.minimal, const _ColorlessTheme()]) {
        entry.controller.updateAppearance(entry.item.appearance.copyWith(theme: theme));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
      await settle(tester);

      expect(errors, isEmpty);
      await cleanup(tester);
    });

    testWidgets('sizes are not blended: a bar may switch between bounded and unbounded constraints', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> toast = FluentBar.toast<void>('Toast', id: 't').persistent().show()!;
      final FluentBarEntry<void> withAction = FluentBar.info<void>('With action').withId('a').persistent().atTop().withAction('Go', closeOnAction: false).show()!;
      await settle(tester);
      expect(tester.widget<Container>(ancestorOf('Toast', Container).first).constraints!.maxWidth, 320);

      toast.controller.updateAppearance(toast.item.appearance.copyWith(constraints: const BoxConstraints()));
      withAction.controller.updateAppearance(withAction.item.appearance.copyWith(actionsConstraints: const BoxConstraints(), constraints: const BoxConstraints(minWidth: 200)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(tester.widget<Container>(ancestorOf('Toast', Container).first).constraints!.maxWidth, double.infinity);
      expect(tester.widget<Container>(ancestorOf('Go', Container).first).constraints!.maxWidth, double.infinity);

      await cleanup(tester);
    });

    testWidgets('a decoration of another build is applied at once; similar ones blend', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Decorated').withId('d').persistent().show()!;
      await settle(tester);

      BoxDecoration shown() => tester.widget<Container>(ancestorOf('Decorated', Container).first).decoration! as BoxDecoration;
      Future<void> apply(BoxDecoration decoration) async {
        entry.controller.updateAppearance(entry.item.appearance.copyWith(decoration: decoration));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }

      await apply(
        BoxDecoration(
          color: Colors.green,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
      );
      expect(shown().color, isNot(Colors.green));
      await settle(tester);
      expect(shown().color!.toARGB32(), Colors.green.toARGB32());

      const BoxDecoration oneSided = BoxDecoration(
        color: Colors.orange,
        border: BorderDirectional(start: BorderSide(color: Colors.white, width: 3)),
      );
      await apply(oneSided);
      expect(shown().color!.toARGB32(), Colors.orange.toARGB32());
      expect(shown().border, oneSided.border);

      for (final BoxDecoration decoration in <BoxDecoration>[
        const BoxDecoration(gradient: LinearGradient(colors: <Color>[Colors.red, Colors.blue])),
        oneSided,
        const BoxDecoration(gradient: RadialGradient(colors: <Color>[Colors.red, Colors.blue])),
        const BoxDecoration(color: Colors.black, boxShadow: <BoxShadow>[BoxShadow(blurRadius: 10), BoxShadow(blurRadius: 20)]),
        const BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(20)),
        ),
        oneSided,
        const BoxDecoration(),
      ]) {
        await apply(decoration);
      }

      await cleanup(tester);
    });

    testWidgets('changing the type of a shown bar fades its colors; a bar without animations changes at once', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultTheme: FluentBarTheme.material));
      final FluentBarEntry<void> entry = FluentBar.info<void>('Animated').withId('a').persistent().show()!;
      final FluentBarEntry<void> instant = FluentBar.info<void>('Instant').withId('b').persistent().atBottom().withoutAnimations().show()!;
      await settle(tester);
      final Color info = backgroundOf(tester, 'Animated');
      expect(backgroundOf(tester, 'Instant'), info);

      entry.controller.updateContent(type: FluentBarType.error);
      instant.controller.updateContent(type: FluentBarType.error);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final Color error = backgroundOf(tester, 'Instant');
      expect(error, isNot(info));
      expect(backgroundOf(tester, 'Animated'), isNot(info));
      expect(backgroundOf(tester, 'Animated'), isNot(error));

      await tester.pump(const Duration(milliseconds: 200));
      expect(backgroundOf(tester, 'Animated'), error);

      await cleanup(tester);
    });
  });

  group('icon identity', () {
    testWidgets('an icon created again is the same icon; a different glyph is a new one', (WidgetTester tester) async {
      await boot(tester);
      FluentBarItem<void> bar(IconData glyph) => FluentBar.info<void>('Bar').withId('a').persistent().withIcon(Icon(glyph, size: 20 + glyph.codePoint % 2));

      bar(Icons.star).show();
      await settle(tester);

      bar(Icons.star).show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.star), findsOneWidget);

      bar(Icons.favorite).show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await settle(tester);
      expect(find.byIcon(Icons.star), findsNothing);

      await cleanup(tester);
    });

    testWidgets('a type created again with copyWith does not replay the icon change either', (WidgetTester tester) async {
      await boot(tester);
      FluentBarItem<void> bar() => FluentBar.custom<void>(FluentBarType.info.copyWith(isSwipeEnabled: false), 'Bar').withId('a').persistent();

      bar().show();
      await settle(tester);
      bar().show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('the content of a bar survives a change of its gestures: nothing is rebuilt from scratch', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Upload').withId('a').withLinearProgress(value: 0.6, showText: true).withAction('Cancel', closeOnAction: false).show()!;
      await settle(tester);
      final State<StatefulWidget> before = tester.state(find.byType(FluentBarTaskProgressWidget));
      expect(find.text('60%'), findsOneWidget);

      entry.controller.setLoading(isLoading: true);
      await tester.pump();
      expect(tester.state(find.byType(FluentBarTaskProgressWidget)), same(before));
      expect(find.text('60%'), findsOneWidget);

      entry.controller.setLoading(isLoading: false);
      entry.controller.updateContent(type: FluentBarType.error);
      await settle(tester);
      expect(tester.state(find.byType(FluentBarTaskProgressWidget)), same(before));
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('a progress indicator in the icon slot stays the same widget when the bar completes with a new type', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Upload').withId('a').withCircularProgress(value: 0.4).show()!;
      await settle(tester);
      final State<StatefulWidget> before = tester.state(find.byType(FluentBarTaskProgressWidget));

      entry.completeProgress(message: 'Done', type: FluentBarType.success);
      await settle(tester);

      expect(tester.state(find.byType(FluentBarTaskProgressWidget)), same(before));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await cleanup(tester);
    });
  });

  group('progress animation', () {
    late ValueNotifier<FluentBarProgressState?> progress;

    Future<void> pumpIndicator(WidgetTester tester, {FluentBarProgressTheme theme = const FluentBarProgressTheme(), double initial = 0}) async {
      manager.resetForTesting();
      progress = ValueNotifier<FluentBarProgressState?>(FluentBarProgressState.value(initial));
      addTearDown(progress.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarTaskProgressWidget(progressNotifier: progress, theme: theme, defaultColor: Colors.blue, successIcon: const Icon(Icons.check)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
    }

    double shown(WidgetTester tester) => tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;

    Future<void> expectJump(WidgetTester tester, double to, Duration expected) async {
      progress.value = FluentBarProgressState.value(to);
      await tester.pump();
      await tester.pump(expected - const Duration(milliseconds: 20));
      expect((shown(tester) - to).abs(), greaterThan(1e-7), reason: 'still on its way to $to');
      await tester.pump(const Duration(milliseconds: 20));
      expect(shown(tester), to, reason: 'has reached $to exactly');
    }

    testWidgets('the further the jump, the longer it takes: a small step is quick, a big jump is slow', (WidgetTester tester) async {
      await pumpIndicator(tester, initial: 0.03);

      await expectJump(tester, 0.05, const Duration(milliseconds: 310));
      await expectJump(tester, 0.35, const Duration(milliseconds: 450));
      await expectJump(tester, 0.03, const Duration(milliseconds: 460));
      await expectJump(tester, 0.87, const Duration(milliseconds: 720));
    });

    testWidgets('a big jump starts gently, a small step responds at once', (WidgetTester tester) async {
      await pumpIndicator(tester, initial: 0.03);

      progress.value = const FluentBarProgressState.value(0.87);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 72));
      expect((shown(tester) - 0.03) / 0.84, lessThan(0.05));
      await tester.pump(const Duration(seconds: 1));

      progress.value = const FluentBarProgressState.value(0.89);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 31));
      expect((shown(tester) - 0.87) / 0.02, greaterThan(0.2));
    });

    testWidgets('a new value in the middle of a jump continues from where the indicator is', (WidgetTester tester) async {
      await pumpIndicator(tester);

      progress.value = const FluentBarProgressState.value(0.8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final double midway = shown(tester);
      expect(midway, greaterThan(0.1));
      expect(midway, lessThan(0.8));

      progress.value = const FluentBarProgressState.value(0.9);
      await tester.pump();
      expect(shown(tester), closeTo(midway, 0.0001));

      double previous = midway;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(shown(tester), greaterThanOrEqualTo(previous));
        previous = shown(tester);
      }
      expect(previous, closeTo(0.9, 0.0001));
    });

    testWidgets('progress started again after completion begins from zero', (WidgetTester tester) async {
      await pumpIndicator(tester, initial: 0.5);

      progress.value = const FluentBarProgressState.value(1.0);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);

      progress.value = const FluentBarProgressState.value(0.2);
      await tester.pump();
      await tester.pump();
      expect(shown(tester), lessThan(0.2));
      await tester.pump(const Duration(seconds: 2));
      expect(shown(tester), closeTo(0.2, 0.0001));
    });

    testWidgets('the duration comes from the theme: zero is instant, a short one is the same for every jump', (WidgetTester tester) async {
      await pumpIndicator(tester, theme: const FluentBarProgressTheme(animationDuration: Duration.zero));
      progress.value = const FluentBarProgressState.value(0.9);
      await tester.pump();
      expect(shown(tester), closeTo(0.9, 0.0001));

      await pumpIndicator(tester, theme: const FluentBarProgressTheme(animationDuration: Duration(milliseconds: 200)));
      await expectJump(tester, 0.05, const Duration(milliseconds: 200));
      await expectJump(tester, 0.95, const Duration(milliseconds: 200));

      await pumpIndicator(tester, theme: const FluentBarProgressTheme(animationDuration: Duration(seconds: 2)));
      await expectJump(tester, 1.0 - 0.0001, const Duration(milliseconds: 2000));
    });

    testWidgets('the percent on screen matches the value: 29% is not shown as 28%', (WidgetTester tester) async {
      expect(const FluentBarProgressState.value(0.29).format(), '29%');
      expect(const FluentBarProgressState.value(0.57).format(), '57%');
      expect(const FluentBarProgressState.value(0.58).format(), '58%');
      expect(const FluentBarProgressState.value(0.996).format(), '99%');
      expect(const FluentBarProgressState.value(0).format(), '0%');
      expect(const FluentBarProgressState.value(1).format(), '100%');

      await pumpIndicator(tester, theme: const FluentBarProgressTheme(showText: true));
      for (final double value in <double>[0.29, 0.57, 0.58]) {
        progress.value = FluentBarProgressState.value(value);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('${(value * 100).round()}%'), findsOneWidget);
      }
    });

    test('the duration is a part of the progress theme and merges like the rest of it', () {
      const FluentBarProgressTheme empty = FluentBarProgressTheme();
      const FluentBarProgressTheme slow = FluentBarProgressTheme(animationDuration: Duration(seconds: 2));

      expect(empty.animationDuration, const Duration(milliseconds: 800));
      expect(empty.mergedOver(slow).animationDuration, const Duration(seconds: 2));
      expect(slow.mergedOver(const FluentBarProgressTheme(animationDuration: Duration(seconds: 5))).animationDuration, const Duration(seconds: 2));
      expect(empty.copyWith(animationDuration: const Duration(seconds: 2)), slow);
      expect(slow.copyWith(showText: true).animationDuration, const Duration(seconds: 2));
      expect(empty, isNot(slow));
      expect(empty.hashCode, isNot(slow.hashCode));

      expect(
        FluentBar.info<void>('m').withLinearProgress(value: 0, animationDuration: const Duration(seconds: 2)).appearance.progressTheme,
        const FluentBarProgressTheme(style: FluentBarProgressStyle.linear, animationDuration: Duration(seconds: 2)),
      );
      expect(FluentBar.info<void>('m').withCircularProgress(value: 0, animationDuration: Duration.zero).appearance.progressTheme!.animationDuration, Duration.zero);
    });
  });
}
