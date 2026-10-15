import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoCloseType extends FluentBarType {
  const _NoCloseType();

  @override
  String get name => 'no_close';

  @override
  bool? get showCloseButton => false;
}

class _ThrowingCloseIconType extends FluentBarType {
  const _ThrowingCloseIconType();

  @override
  String get name => 'throwing_close_icon';

  @override
  Widget? get closeIcon => throw StateError('no icon');
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final Finder closeButton = find.byType(FluentBarCloseButton);

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero), TextDirection direction = TextDirection.ltr}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: Directionality(
          textDirection: direction,
          child: const Scaffold(body: SizedBox()),
        ),
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
    await tester.pump(const Duration(milliseconds: 500));
  }

  const FluentBarConfig withButton = FluentBarConfig(defaultTransitionDuration: Duration.zero, defaultShowCloseButton: true);

  group('showing', () {
    testWidgets('a bar has no close button unless it is asked for', (WidgetTester tester) async {
      await boot(tester);

      FluentBar.info<void>('Plain').persistent().show();
      await settle(tester);
      expect(closeButton, findsNothing);

      FluentBar.dismissAndClear();
      await settle(tester);
      FluentBar.info<void>('With a button').persistent().withCloseButton().show();
      await settle(tester);
      expect(closeButton, findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('the bar decides, then its type, then the config', (WidgetTester tester) async {
      await boot(tester, config: withButton);

      FluentBar.info<void>('From the config').persistent().withId('bar').show();
      await settle(tester);
      expect(closeButton, findsOneWidget);

      FluentBar.custom<void>(const _NoCloseType(), 'The type says no').persistent().withId('bar').show();
      await settle(tester);
      expect(closeButton, findsNothing);

      FluentBar.custom<void>(const _NoCloseType(), 'The bar says yes').persistent().withCloseButton().withId('bar').show();
      await settle(tester);
      expect(closeButton, findsOneWidget);

      FluentBar.info<void>('The bar says no').persistent().withoutCloseButton().withId('bar').show();
      await settle(tester);
      expect(closeButton, findsNothing);

      FluentBar.custom<void>(FluentBarType.info.copyWith(showCloseButton: false), 'A copied type says no').persistent().withId('bar').show();
      await settle(tester);
      expect(closeButton, findsNothing);

      await cleanup(tester);
    });

    final Map<String, FluentBarItem<void> Function()> presets = <String, FluentBarItem<void> Function()>{
      'snack': () => FluentBar.snack<void>('Snack'),
      'toast': () => FluentBar.toast<void>('Toast'),
      'banner': () => FluentBar.banner<void>('Banner'),
      'loading': () => FluentBar.loading<void>('Loading'),
      'undismissible': () => FluentBar.info<void>('Locked').persistent().undismissible(),
    };

    for (final MapEntry<String, FluentBarItem<void> Function()> preset in presets.entries) {
      testWidgets('${preset.key} stays without the button when the config turns it on, and takes it when asked', (WidgetTester tester) async {
        await boot(tester, config: withButton);

        preset.value().show();
        await settle(tester);
        expect(closeButton, findsNothing);

        FluentBar.dismissAndClear();
        await settle(tester);
        preset.value().withCloseButton().show();
        await settle(tester);
        expect(closeButton, findsOneWidget);

        await cleanup(tester);
      });
    }

    testWidgets('turning the button on for a visible bar keeps the state of its content', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Stable').persistent().show()!;
      await settle(tester);
      final Element before = tester.element(find.text('Stable'));

      entry.patchAppearance((FluentBarAppearance<void> appearance) => appearance.copyWith(showCloseButton: true));
      await settle(tester);

      expect(closeButton, findsOneWidget);
      expect(tester.element(find.text('Stable')), same(before));

      await cleanup(tester);
    });
  });

  group('closing', () {
    testWidgets('a tap closes the bar with its own reason and counts as an interaction of the user', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      void record(FluentBarAnalyticsPayload payload) => events.add(payload.event);
      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      FluentBarMetrics? metrics;
      int taps = 0;
      FluentBar.info<void>('Close me').persistent().withCloseButton().onTap((_) => taps++).onDismiss((_, FluentBarMetrics m) => metrics = m).show();
      await settle(tester);

      await tester.tap(closeButton);
      await settle(tester);

      expect(FluentBar.activeItems, isEmpty);
      expect(metrics!.dismissReason, FluentBarDismissReason.closeButton);
      expect(metrics!.dismissReason.isByUser, isTrue);
      expect(metrics!.countOf(FluentBarInteraction.close), 1);
      expect(metrics!.wasUntouched, isFalse);
      expect(metrics!.wasTapped, isFalse);
      expect(metrics!.toFlatMap()['interaction_close'], 1);
      expect(taps, 0, reason: 'the tap on the button is not a tap on the bar');
      expect(events, isNot(contains(FluentBarAnalyticsEvent.tapped)));

      await cleanup(tester);
    });

    testWidgets('it is the way out of a bar that ignores taps and swipes', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('Only the button').persistent().undismissible().withCloseButton().show();
      await settle(tester);

      await tester.tap(find.text('Only the button'));
      await settle(tester);
      expect(FluentBar.activeItems, hasLength(1));

      await tester.tap(closeButton);
      await settle(tester);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('it stands next to the action and does not run it', (WidgetTester tester) async {
      await boot(tester);
      int undone = 0;
      FluentBar.info<void>('Moved to trash').persistent().withAction('Undo', onPressed: (_, _) => undone++).withCloseButton().show();
      await settle(tester);

      expect(find.text('Undo'), findsOneWidget);
      expect(tester.getCenter(closeButton).dx, greaterThan(tester.getCenter(find.text('Undo')).dx));

      await tester.tap(closeButton);
      await settle(tester);
      expect(undone, 0);
      expect(FluentBar.activeItems, isEmpty);

      await cleanup(tester);
    });

    testWidgets('it hides a bar with unfinished progress without ending the progress', (WidgetTester tester) async {
      await boot(tester);
      FluentBarMetrics? metrics;
      FluentBar.info<void>('Uploading').withLinearProgress(value: 0.3).withCloseButton().onDismiss((_, FluentBarMetrics m) => metrics = m).show();
      await settle(tester);

      await tester.tap(closeButton);
      await settle(tester);

      expect(FluentBar.activeItems, isEmpty);
      expect(metrics!.progressOutcome, isNull);

      await cleanup(tester);
    });

    testWidgets('a second tap while the bar is leaving does nothing', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig());
      int dismissed = 0;
      FluentBar.info<void>('Twice').persistent().withCloseButton().onDismiss((_, _) => dismissed++).show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(closeButton);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(closeButton, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(dismissed, 1);

      await cleanup(tester);
    });

    testWidgets('the widget closes a bar from a custom content builder too', (WidgetTester tester) async {
      await boot(tester);
      FluentBarMetrics? metrics;
      FluentBar.info<void>('Custom')
          .persistent()
          .withContent(
            (BuildContext context, FluentBarEntry<void> entry) => Material(
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('My own layout')),
                  FluentBarCloseButton(controller: entry.controller),
                ],
              ),
            ),
          )
          .onDismiss((_, FluentBarMetrics m) => metrics = m)
          .show();
      await settle(tester);

      await tester.tap(closeButton);
      await settle(tester);

      expect(metrics!.dismissReason, FluentBarDismissReason.closeButton);

      await cleanup(tester);
    });
  });

  group('look', () {
    testWidgets('the theme gives the icon, its size, color, padding and place', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarTheme theme = FluentBarTheme.material.copyWith(
        closeIcon: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const Icon(Icons.cancel),
        closeIconSize: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => 30,
        closeIconColor: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const Color(0xFF00FF00),
        closeButtonPadding: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const EdgeInsets.all(2),
        closeButtonAlignment: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => CrossAxisAlignment.start,
      );

      FluentBar.info<void>('One\nTwo\nThree\nFour').withTitle('Tall').persistent().withTheme(theme).withCloseButton().show();
      await settle(tester);

      final IconThemeData iconTheme = IconTheme.of(tester.element(find.byIcon(Icons.cancel)));
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(iconTheme.size, 30);
      expect(iconTheme.color, const Color(0xFF00FF00));
      expect(tester.getSize(closeButton), const Size(34, 34));
      expect(tester.getTopLeft(closeButton).dy, closeTo(tester.getTopLeft(find.text('Tall')).dy, 1), reason: 'aligned to the top of the content');

      await cleanup(tester);
    });

    testWidgets('by default the button is centered against a tall bar', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('One\nTwo\nThree\nFour').persistent().withCloseButton().show();
      await settle(tester);

      expect(tester.getCenter(closeButton).dy, closeTo(tester.getCenter(find.text('One\nTwo\nThree\nFour')).dy, 1));

      await cleanup(tester);
    });

    testWidgets('a bar can bring its own icon, which wins over the theme', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('Own icon').persistent().withCloseButton(icon: const Icon(Icons.expand_more)).show();
      await settle(tester);

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await cleanup(tester);
    });

    testWidgets('a type gives the icon to its bars: the bar wins over the type, the type over the theme', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarType collapsing = FluentBarType.info.copyWith(closeIcon: const Icon(Icons.expand_more));
      FluentBar.custom<void>(collapsing, 'Type icon').persistent().withCloseButton().show();
      FluentBar.custom<void>(collapsing, 'Bar icon').atBottom().persistent().withCloseButton(icon: const Icon(Icons.minimize)).show();
      await settle(tester);

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.minimize), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await cleanup(tester);
    });

    testWidgets('a type whose close icon throws is reported and the theme gives the icon', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      FluentBar.custom<void>(const _ThrowingCloseIconType(), 'Still fine').persistent().withCloseButton().show();
      await settle(tester);

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(errors.map((FluentBarException e) => e.type), contains(FluentBarErrorType.fluentBarType));
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('the cupertino theme has its own cross', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.info<void>('iOS').persistent().withTheme(FluentBarTheme.cupertino).withCloseButton().show();
      await settle(tester);

      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

      await cleanup(tester);
    });

    testWidgets('a theme whose close icon throws falls back to the base theme', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      final FluentBarTheme broken = FluentBarTheme.material.copyWith(closeIcon: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => throw StateError('no icon'));
      FluentBar.info<void>('Still fine').persistent().withTheme(broken).withCloseButton().show();
      await settle(tester);

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(errors, isNotEmpty);
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('in a right-to-left app the button sits at the left end', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) => Directionality(
            textDirection: TextDirection.rtl,
            child: FluentBarScope(
              config: const FluentBarConfig(defaultTransitionDuration: Duration.zero),
              child: child!,
            ),
          ),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      FluentBar.info<void>('Right to left').persistent().withCloseButton().show();
      await settle(tester);

      expect(tester.getCenter(closeButton).dx, lessThan(tester.getCenter(find.text('Right to left')).dx));

      await cleanup(tester);
    });

    testWidgets('a long text, an action and the button fit a narrow phone', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await boot(tester);

      FluentBar.info<void>(
        'A long message that has to wrap on a narrow phone and still leave room for both controls',
      ).withTitle('Long title of the bar').persistent().withAction('Retry').withCloseButton().show();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(closeButton, findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cleanup(tester);
    });
  });

  group('screen readers', () {
    testWidgets('the button is announced with the label of the app localization', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.info<void>('Readable').persistent().withCloseButton().show();
      await settle(tester);

      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      // ignore: deprecated_member_use
      expect(tester.getSemantics(find.bySemanticsLabel('Close')), containsSemantics(label: 'Close', isButton: true));

      handle.dispose();
      await cleanup(tester);
    });

    testWidgets('the config can give the label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(
        tester,
        config: const FluentBarConfig(defaultTransitionDuration: Duration.zero, closeButtonLabel: 'Dismiss the message'),
      );
      FluentBar.info<void>('Readable').persistent().withCloseButton().show();
      await settle(tester);

      expect(find.bySemanticsLabel('Dismiss the message'), findsOneWidget);

      handle.dispose();
      await cleanup(tester);
    });
  });

  test('the setting takes part in the equality of the appearance and the config', () {
    expect(const FluentBarAppearance<void>(showCloseButton: true), isNot(const FluentBarAppearance<void>()));
    expect(const FluentBarAppearance<void>(showCloseButton: true).hashCode, const FluentBarAppearance<void>(showCloseButton: true).hashCode);
    expect(const FluentBarConfig(defaultShowCloseButton: true), isNot(const FluentBarConfig()));
    expect(const FluentBarConfig(closeButtonLabel: 'x'), isNot(const FluentBarConfig()));
    expect(const FluentBarConfig().copyWith(defaultShowCloseButton: true, closeButtonLabel: 'x'), const FluentBarConfig(defaultShowCloseButton: true, closeButtonLabel: 'x'));
    expect(const FluentBarConfig().defaultShowCloseButton, isFalse);
  });
}
