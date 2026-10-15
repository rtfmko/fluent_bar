import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentBarItem<String> base() => FluentBarItem<String>(type: FluentBarType.info, message: 'Message');

  group('immutability', () {
    test('every modifier returns a new item and leaves the original untouched', () {
      final FluentBarItem<String> original = base();
      final FluentBarItem<String> changed = original.withTitle('Title').atBottom().withBackground(Colors.red).persistent();

      expect(changed, isNot(same(original)));
      expect(original.title, isNull);
      expect(original.behavior.position, isNull);
      expect(original.appearance.backgroundColor, isNull);
      expect(original.isPersistent, isNull);
      expect(changed.uuid, original.uuid, reason: 'it is still the same bar being configured');
    });

    test('modifiers keep what earlier modifiers set', () {
      final FluentBarItem<String> item = base().withTitle('Title').atBottom().withPriority(FluentBarPriority.high).withBackground(Colors.red).withoutIcon();

      expect(item.title, 'Title');
      expect(item.behavior.position, FluentBarPosition.bottom);
      expect(item.behavior.priority, FluentBarPriority.high);
      expect(item.appearance.backgroundColor, Colors.red);
      expect(item.appearance.showIcon, isFalse);
      expect(item.message, 'Message');
    });

    test('a later modifier of the same kind wins', () {
      expect(base().atTop().atBottom().atCenter().behavior.position, FluentBarPosition.center);
      expect(base().withBackground(Colors.red).withBackground(Colors.blue).appearance.backgroundColor, Colors.blue);
      expect(base().persistent().withDuration(const Duration(seconds: 3)).isPersistent, isFalse);
    });
  });

  group('content', () {
    test('title, id, payload and meta', () {
      final FluentBarItem<String> item = base().withTitle('Title').withId('id').withPayload('data').withMeta(const <String, dynamic>{'k': 1});

      expect(item.title, 'Title');
      expect(item.id, 'id');
      expect(item.payload, 'data');
      expect(item.meta, <String, dynamic>{'k': 1});
    });
  });

  group('lifetime', () {
    test('withDuration makes the bar timed; persistent makes it stay', () {
      final FluentBarItem<String> timed = base().withDuration(const Duration(seconds: 7));
      expect(timed.duration, const Duration(seconds: 7));
      expect(timed.isPersistent, isFalse);
      expect(timed.resolveEffectiveDuration(const FluentBarConfig()), const Duration(seconds: 7));

      final FluentBarItem<String> sticky = base().persistent();
      expect(sticky.isPersistent, isTrue);
      expect(sticky.resolveEffectiveDuration(const FluentBarConfig()), isNull);
    });

    test('withTimeoutBar turns the countdown bar on, optionally with position and direction', () {
      expect(base().withTimeoutBar().appearance.showTimeoutBar, isTrue);
      expect(base().withTimeoutBar().appearance.timeoutBarPosition, isNull);

      final FluentBarAppearance<String> appearance = base().withTimeoutBar(position: FluentBarTimeoutBarPosition.top, direction: FluentBarTimeoutBarDirection.reverse).appearance;
      expect(appearance.timeoutBarPosition, FluentBarTimeoutBarPosition.top);
      expect(appearance.timeoutBarDirection, FluentBarTimeoutBarDirection.reverse);
    });
  });

  group('progress', () {
    test('withProgress sets the state and leaves the look to the theme', () {
      final FluentBarItem<String> item = base().withProgress(const FluentBarProgressFraction(2, 5));

      expect(item.progressState, const FluentBarProgressFraction(2, 5));
      expect(item.appearance.progressTheme, isNull);
    });

    test('withLinearProgress: indeterminate by default, at the bottom, no text', () {
      final FluentBarItem<String> item = base().withLinearProgress();
      final FluentBarProgressTheme theme = item.appearance.progressTheme!;

      expect(item.progressState, const FluentBarProgressState.indeterminate());
      expect(theme.style, FluentBarProgressStyle.linear);
      expect(theme.position, FluentBarProgressPosition.bottom);
      expect(theme.showText, isFalse);
    });

    test('withLinearProgress accepts a value, text, position, color and text effect', () {
      final FluentBarItem<String> item = base().withLinearProgress(
        value: 0.4,
        showText: true,
        position: FluentBarProgressPosition.top,
        color: Colors.orange,
        textEffect: FluentBarProgressTextEffect.roll,
      );
      final FluentBarProgressTheme theme = item.appearance.progressTheme!;

      expect(item.progressState, const FluentBarProgressValue(0.4));
      expect(theme.showText, isTrue);
      expect(theme.position, FluentBarProgressPosition.top);
      expect(theme.progressColor, Colors.orange);
      expect(theme.textEffect, FluentBarProgressTextEffect.roll);
    });

    test('withCircularProgress: replaces the icon by default and accepts a size', () {
      final FluentBarItem<String> item = base().withCircularProgress(value: 0.9, size: 40, showText: true);
      final FluentBarProgressTheme theme = item.appearance.progressTheme!;

      expect(item.progressState, const FluentBarProgressValue(0.9));
      expect(theme.style, FluentBarProgressStyle.circular);
      expect(theme.position, FluentBarProgressPosition.replaceIcon);
      expect(theme.size, 40);
      expect(theme.showText, isTrue);
      expect(base().withCircularProgress().progressState, const FluentBarProgressState.indeterminate());

      expect(base().withCircularProgress().appearance.progressTheme?.successIconDuration, isNull);
      expect(base().withCircularProgress(successIconDuration: const Duration(seconds: 2)).appearance.progressTheme?.successIconDuration, const Duration(seconds: 2));
      expect(base().withLinearProgress(successIconDuration: const Duration(seconds: 3)).appearance.progressTheme?.successIconDuration, const Duration(seconds: 3));
    });

    test('an explicit state wins over a value; out-of-range values are clamped instead of failing', () {
      expect(base().withLinearProgress(value: 0.1, state: const FluentBarProgressFraction(1, 3)).progressState, const FluentBarProgressFraction(1, 3));
      expect(base().withLinearProgress(value: 7).progressState, const FluentBarProgressValue(1.0));
      expect(base().withCircularProgress(value: -2).progressState, const FluentBarProgressValue(0.0));
      expect(base().withLinearProgress(value: double.nan).progressState, const FluentBarProgressValue(0.0));
    });

    test('progress modifiers keep the rest of an existing progress theme', () {
      final FluentBarItem<String> item = base()
          .copyWith(
            appearance: const FluentBarAppearance<String>(progressTheme: FluentBarProgressTheme(thickness: 9, textAlign: FluentBarProgressTextAlign.center)),
          )
          .withCircularProgress();

      expect(item.appearance.progressTheme!.thickness, 9);
      expect(item.appearance.progressTheme!.textAlign, FluentBarProgressTextAlign.center);
      expect(item.appearance.progressTheme!.style, FluentBarProgressStyle.circular);
    });
  });

  group('position and queue', () {
    test('at / atTop / atBottom / atCenter', () {
      expect(base().at(FluentBarPosition.left).behavior.position, FluentBarPosition.left);
      expect(base().atTop().behavior.position, FluentBarPosition.top);
      expect(base().atBottom().behavior.position, FluentBarPosition.bottom);
      expect(base().atCenter().behavior.position, FluentBarPosition.center);
    });

    test('priority, force and duplicate policy', () {
      expect(base().withPriority(FluentBarPriority.critical).behavior.priority, FluentBarPriority.critical);
      expect(base().behavior.isForce, isFalse);
      expect(base().forced().behavior.isForce, isTrue);
      expect(base().withDuplicatePolicy(FluentBarDuplicatePolicy.allow).behavior.duplicatePolicy, FluentBarDuplicatePolicy.allow);
      expect(base().withRelocationStrategy(FluentBarRelocationStrategy.ignore).behavior.relocationStrategy, FluentBarRelocationStrategy.ignore);
    });
  });

  group('gestures and feedback', () {
    test('swipeable, dismissOnTap and pauseOnTouch default to "on" and can be turned off', () {
      expect(base().swipeable().behavior.isSwipeEnabled, isTrue);
      expect(base().swipeable(false).behavior.isSwipeEnabled, isFalse);
      expect(base().dismissOnTap().behavior.dismissOnTap, isTrue);
      expect(base().dismissOnTap(false).behavior.dismissOnTap, isFalse);
      expect(base().pauseOnTouch().behavior.pauseOnTouch, isTrue);
      expect(base().pauseOnTouch(false).behavior.pauseOnTouch, isFalse);
    });

    test('undismissible turns off both swipe and tap', () {
      final FluentBarBehavior behavior = base().undismissible().behavior;

      expect(behavior.isSwipeEnabled, isFalse);
      expect(behavior.dismissOnTap, isFalse);
    });

    test('haptic and safe area', () {
      expect(base().withHaptic(FluentBarHapticType.heavy).behavior.haptic, FluentBarHapticType.heavy);
      expect(base().behavior.useSafeArea, isNull);
      expect(base().withoutSafeArea().behavior.useSafeArea, isFalse);
    });
  });

  group('appearance', () {
    test('background, icon and no icon', () {
      const Icon icon = Icon(Icons.star);

      expect(base().withBackground(Colors.teal).appearance.backgroundColor, Colors.teal);

      final FluentBarAppearance<String> withIcon = base().withoutIcon().withIcon(icon, color: Colors.amber, size: 30).appearance;
      expect(withIcon.icon, same(icon));
      expect(withIcon.iconColor, Colors.amber);
      expect(withIcon.iconSize, 30);
      expect(withIcon.showIcon, isTrue, reason: 'setting an icon also shows it');

      expect(base().withIcon(icon).withoutIcon().appearance.showIcon, isFalse);
    });

    test('theme and theme mode', () {
      expect(base().withTheme(FluentBarTheme.minimal).appearance.theme, FluentBarTheme.minimal);
      expect(base().withThemeMode(FluentBarThemeMode.system).appearance.themeMode, FluentBarThemeMode.system);
      expect(base().dark().appearance.themeMode, FluentBarThemeMode.dark);
      expect(base().light().appearance.themeMode, FluentBarThemeMode.light);
    });

    test('entrance animation and no animations', () {
      expect(base().withEntrance(FluentBarEntranceAnimation.flip3d).appearance.entranceAnimation, FluentBarEntranceAnimation.flip3d);
      expect(base().withoutAnimations().appearance.disableAnimations, isTrue);
    });

    test('withContent sets a custom content builder', () {
      Widget builder(BuildContext context, FluentBarEntry<String> entry) => const SizedBox();

      expect(base().withContent(builder).appearance.builder, builder);
    });
  });

  group('action and callbacks', () {
    test('withAction adds a button; it closes the bar by default', () {
      void pressed(FluentBarController<String> controller, String? payload) {}

      final FluentBarActions<String> actions = base().withAction('Undo', onPressed: pressed).actions!;
      expect(actions.label, 'Undo');
      expect(actions.onPressed, pressed);
      expect(actions.closeOnAction, isTrue);

      expect(base().withAction('Retry', closeOnAction: false).actions!.closeOnAction, isFalse);
      expect(base().withAction('One').withAction('Two').actions!.label, 'Two');
    });

    test('onTap, onShow and onDismiss are added one by one without losing each other', () {
      void tap(String? payload) {}
      void show(FluentBarItem<String> item) {}
      void dismiss(FluentBarItem<String> item, FluentBarMetrics metrics) {}

      final FluentBarCallbacks<String> callbacks = base().onTap(tap).onShow(show).onDismiss(dismiss).callbacks!;

      expect(callbacks.onTap, tap);
      expect(callbacks.onShow, show);
      expect(callbacks.onDismiss, dismiss);
      expect(base().callbacks, isNull);
    });
  });

  group('end to end', () {
    testWidgets('a fully chained bar is shown exactly as described', (WidgetTester tester) async {
      FluentBarManager.instance.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();
      final List<String> calls = <String>[];

      final FluentBarEntry<String>? entry = FluentBarItem<String>(type: FluentBarType.warning, message: 'Disk is almost full')
          .withTitle('Storage')
          .withId('disk')
          .withPayload('C:')
          .atBottom()
          .persistent()
          .withBackground(Colors.deepOrange)
          .withIcon(const Icon(Icons.storage))
          .withAction('CLEAN', closeOnAction: false, onPressed: (FluentBarController<String> c, String? payload) => calls.add('clean $payload'))
          .onTap((String? payload) => calls.add('tap $payload'))
          .onShow((FluentBarItem<String> item) => calls.add('show'))
          .dismissOnTap(false)
          .show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(FluentBarManager.instance.bottomActiveItem, same(entry));
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('Disk is almost full'), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
      final Container container = tester.widget<Container>(find.ancestor(of: find.text('Storage'), matching: find.byType(Container)).first);
      expect((container.decoration! as BoxDecoration).color, Colors.deepOrange);

      await tester.tap(find.text('CLEAN'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Disk is almost full'));
      await tester.pump();

      expect(calls, <String>['show', 'clean C:', 'tap C:']);
      expect(FluentBarManager.instance.bottomActiveItem, same(entry), reason: 'persistent, and dismissOnTap is off');

      FluentBarManager.instance.resetForTesting();
      await tester.pump();
    });
  });
}
