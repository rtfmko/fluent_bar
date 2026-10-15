import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingTheme extends FluentBarTheme {
  const _ThrowingTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => const BoxDecoration(color: Color(0xFF222222));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  double closeIconSize(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => throw StateError('size');
}

class _ThrowingIconSizeTheme extends _ThrowingTheme {
  const _ThrowingIconSizeTheme();

  @override
  double iconSize(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => throw StateError('icon size');
}

class _StretchTheme extends FluentBarTheme {
  final CrossAxisAlignment alignment;

  const _StretchTheme(this.alignment);

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => const BoxDecoration(color: Color(0xFF222222));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle(color: Color(0xFFFFFFFF));

  @override
  CrossAxisAlignment closeButtonAlignment(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => alignment;
}

int _probeInits = 0;

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _probeInits++;
  }

  @override
  Widget build(BuildContext context) => const Text('probe');
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig(defaultTransitionDuration: Duration.zero), Widget home = const Scaffold(body: SizedBox())}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: home,
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  group('close button', () {
    testWidgets('a theme class that throws for the close button is reported and the built-in theme draws the bar', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      FluentBar.info<void>('Still drawn').persistent().withTheme(const _ThrowingTheme()).withCloseButton().show();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.byType(FluentBarCloseButton), findsOneWidget);
      expect(errors.map((FluentBarException e) => e.type), contains(FluentBarErrorType.fluentBarTheme));

      await cleanup(tester);
    });

    testWidgets('a theme class that throws for the icon size of an own icon is reported and the built-in theme draws the bar', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      FluentBar.info<void>('Own icon').persistent().withTheme(const _ThrowingIconSizeTheme()).withIcon(const Icon(Icons.star)).show();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(errors.map((FluentBarException e) => e.type), contains(FluentBarErrorType.fluentBarTheme));

      await cleanup(tester);
    });

    testWidgets('its default color follows a message style changed with copyWith', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarTheme theme = FluentBarTheme.material.copyWith(messageStyle: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const TextStyle(color: Color(0xFFFF0000)));
      FluentBar.info<void>('Red').persistent().withTheme(theme).withCloseButton().show();
      await settle(tester);

      expect(IconTheme.of(tester.element(find.byIcon(Icons.close_rounded))).color, const Color(0xFFFF0000).withValues(alpha: 0.7));

      await cleanup(tester);
    });

    for (final CrossAxisAlignment alignment in <CrossAxisAlignment>[CrossAxisAlignment.stretch, CrossAxisAlignment.baseline]) {
      testWidgets('an alignment that is not a placement (${alignment.name}) is drawn as center', (WidgetTester tester) async {
        await boot(tester);
        FluentBar.info<void>('One\nTwo\nThree').persistent().withTheme(_StretchTheme(alignment)).withCloseButton().show();
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(tester.getCenter(find.byType(FluentBarCloseButton)).dy, closeTo(tester.getCenter(find.text('One\nTwo\nThree')).dy, 1));
        expect(tester.getSize(find.byType(FluentBarCloseButton)).height, lessThan(60));

        await cleanup(tester);
      });
    }

    testWidgets('it closes a bar that is loading or busy with its action: the way out of a task that hangs', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> loading = FluentBar.info<void>('Saving').persistent().withCloseButton().show()!;
      await settle(tester);
      loading.controller.setLoading(isLoading: true);
      await tester.pump();

      await tester.tap(find.byType(FluentBarCloseButton));
      await settle(tester);
      expect(FluentBar.activeItems, isEmpty);

      FluentBarMetrics? metrics;
      FluentBar.info<void>(
        'Downloading',
      ).withLinearProgress(value: 0.3).withCancelButton('Cancel', onCancel: () => Completer<void>().future).withCloseButton().onDismiss((_, FluentBarMetrics m) => metrics = m).show();
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      await tester.tap(find.byType(FluentBarCloseButton));
      await settle(tester);
      expect(FluentBar.activeItems, isEmpty);
      expect(metrics!.dismissReason, FluentBarDismissReason.closeButton);

      await cleanup(tester);
    });
  });

  group('screen reader', () {
    testWidgets('its dismiss gesture closes the bar as the user, with its own reason and interaction', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBarMetrics? metrics;
      FluentBar.info<void>('Read and dismissed').persistent().onDismiss((_, FluentBarMetrics m) => metrics = m).show();
      await settle(tester);

      tester.getSemantics(find.text('Read and dismissed')).owner!.performAction(tester.getSemantics(find.text('Read and dismissed')).id, SemanticsAction.dismiss);
      await settle(tester);

      expect(FluentBar.activeItems, isEmpty);
      expect(metrics!.dismissReason, FluentBarDismissReason.accessibility);
      expect(metrics!.dismissReason.isByUser, isTrue);
      expect(metrics!.countOf(FluentBarInteraction.accessibility), 1);
      expect(metrics!.wasUntouched, isFalse);

      handle.dispose();
      await cleanup(tester);
    });
  });

  group('icon', () {
    testWidgets('a leaving icon keeps its state while it fades out', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig());
      _probeInits = 0;
      final FluentBarEntry<void> entry = FluentBar.info<void>('With an icon').persistent().withIcon(const _Probe()).show()!;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_probeInits, 1);

      entry.patchAppearance((FluentBarAppearance<void> appearance) => appearance.copyWith(icon: const Icon(Icons.star)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('probe'), findsOneWidget, reason: 'still leaving');
      expect(_probeInits, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('probe'), findsNothing);

      await cleanup(tester);
    });
  });

  group('action', () {
    testWidgets('a leaving action keeps its state while it fades out', (WidgetTester tester) async {
      await boot(tester);
      _probeInits = 0;
      final FluentBarActions<void> actions = FluentBarActions<void>(
        builder: (BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode mode) => const _Probe(),
      );
      final FluentBarEntry<void> entry = FluentBar.info<void>('With an action').persistent().copyWith(actions: actions).show()!;
      await settle(tester);
      expect(_probeInits, 1);

      entry.controller.removeAction();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('probe'), findsOneWidget, reason: 'still fading out');
      expect(_probeInits, 1);

      await settle(tester);
      expect(find.text('probe'), findsNothing);

      await cleanup(tester);
    });

    testWidgets('a leaving action takes no room and cannot be tapped', (WidgetTester tester) async {
      await boot(tester);
      int taps = 0;
      final FluentBarEntry<void> entry = FluentBar.info<void>('Message').persistent().withAction('Open', closeOnAction: false, onPressed: (_, _) => taps++).show()!;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      entry.controller.removeAction();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Open'), warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });
  });

  group('cancel button', () {
    testWidgets('an error of the stopped task does not turn a cancelled bar into a failed one', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      void record(FluentBarAnalyticsPayload payload) => events.add(payload.event);
      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').persistent().withLinearProgress(value: 0.2).withCancelButton('Cancel', canceledMessage: 'Cancelled').show()!;
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      entry.failProgress(message: 'Failed: the request was cancelled');
      await settle(tester);

      expect(entry.item.message, 'Cancelled');
      expect(entry.internalController.progressOutcome, FluentBarProgressOutcome.canceled);
      expect(events, isNot(contains(FluentBarAnalyticsEvent.progressFailed)));

      await cleanup(tester);
    });

    testWidgets('while the task is being stopped an update keeps the progress and applies the rest', (WidgetTester tester) async {
      await boot(tester);
      final Completer<void> stopping = Completer<void>();
      final FluentBarEntry<void> entry = FluentBar.info<void>('Downloading').withId('job').withLinearProgress(value: 0.2).withCancelButton('Cancel', onCancel: () => stopping.future).show()!;
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(pauseOnTouch: false));
      FluentBar.info<void>('Stopping the download').withId('job').withLinearProgress(value: 0.5).show();
      await tester.pump();

      expect(entry.item.behavior.pauseOnTouch, isFalse);
      expect(entry.item.message, 'Stopping the download');
      expect(entry.item.progressState, const FluentBarProgressState.value(0.2));

      stopping.complete();
      await settle(tester);
      await cleanup(tester);
    });

    testWidgets('a progress completed by a re-show reaches listeners once, already without the button', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = FluentBar.info<void>('Working').withId('job').withLinearProgress(value: 0.4).withCancelButton('Cancel').show()!;
      await settle(tester);

      final List<bool> hadButton = <bool>[];
      void onItem() => hadButton.add(entry.controller.itemNotifier.value.actions != null);
      entry.controller.itemNotifier.addListener(onItem);

      FluentBar.info<void>('Done').withId('job').withLinearProgress(value: 1).show();
      await tester.pump();
      entry.controller.itemNotifier.removeListener(onItem);

      expect(hadButton, <bool>[false]);

      await cleanup(tester);
    });

    testWidgets('on a bar without progress it runs the callback, shows the message and reports no cancelled progress', (WidgetTester tester) async {
      await boot(tester);
      final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
      void record(FluentBarAnalyticsPayload payload) => events.add(payload.event);
      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      int cancels = 0;
      final FluentBarEntry<void> entry = FluentBar.info<void>('Sending in 5 seconds').persistent().withCancelButton('Cancel', onCancel: () => cancels++, canceledMessage: 'Not sent').show()!;
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(cancels, 1);
      expect(entry.item.message, 'Not sent');
      expect(entry.item.actions, isNull);
      expect(events, isNot(contains(FluentBarAnalyticsEvent.progressCanceled)));

      entry.updateValue(0.3);
      await tester.pump();
      expect(entry.item.progressState, const FluentBarProgressState.value(0.3), reason: 'nothing was cancelled, so nothing is locked');

      await cleanup(tester);
    });
  });

  group('tags', () {
    testWidgets('closeTag closes a bar that is on its way to another region instead of letting it queue there', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig());
      FluentBarMetrics? metrics;
      FluentBar.info<void>('Bottom').persistent().atBottom().show();
      final FluentBarEntry<void> top = FluentBar.info<void>('Top').persistent().atTop().withTag('screen').onDismiss((_, FluentBarMetrics m) => metrics = m).show()!;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      top.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom));
      await tester.pump(const Duration(milliseconds: 50));

      FluentBar.closeTag('screen');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(FluentBar.findByTag('screen'), isEmpty);
      expect(FluentBar.allQueueLength, 0);
      expect(top.internalController.isDisposed, isTrue);
      expect(metrics!.dismissReason, FluentBarDismissReason.manual);
      expect(FluentBar.bottomActiveItem!.item.message, 'Bottom');

      await cleanup(tester);
    });

    testWidgets('the owner closes its bars after the frame, so listeners of the app never run in a locked tree', (WidgetTester tester) async {
      final ValueNotifier<bool> showOwner = ValueNotifier<bool>(true);
      addTearDown(showOwner.dispose);
      await boot(
        tester,
        home: ValueListenableBuilder<bool>(
          valueListenable: showOwner,
          builder: (BuildContext context, bool show, _) => show
              ? const FluentBarOwner(
                  tag: 'screen',
                  child: Scaffold(body: SizedBox()),
                )
              : const Scaffold(body: SizedBox()),
        ),
      );
      FluentBar.info<void>('Shown').persistent().withTag('screen').show();
      FluentBar.info<void>('Queued').persistent().withTag('screen').show();
      await settle(tester);

      final List<SchedulerPhase> phases = <SchedulerPhase>[];
      void record(FluentBarAnalyticsPayload payload) => phases.add(SchedulerBinding.instance.schedulerPhase);
      manager.addAnalyticsListener(record);
      addTearDown(() => manager.removeAnalyticsListener(record));

      showOwner.value = false;
      await settle(tester);
      await settle(tester);

      expect(phases, isNotEmpty);
      expect(phases, isNot(contains(SchedulerPhase.persistentCallbacks)));
      expect(FluentBar.findByTag('screen'), isEmpty);

      await cleanup(tester);
    });

    testWidgets('a tag handed from one owner to another in the same frame keeps its bars', (WidgetTester tester) async {
      Widget owner(int key) => FluentBarOwner(
        key: ValueKey<int>(key),
        tag: 'screen',
        child: const Scaffold(body: SizedBox()),
      );

      await boot(tester, home: owner(1));
      FluentBar.info<void>('Mine').persistent().withTag('screen').show();
      await settle(tester);

      await tester.pumpWidget(
        MaterialApp(
          builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
          home: owner(2),
        ),
      );
      await settle(tester);

      expect(FluentBar.findByTag('screen'), hasLength(1));

      await cleanup(tester);
    });

    test('toString names the tags', () {
      expect(FluentBar.info<void>('x').withTag('checkout').toString(), contains('tags: {checkout}'));
      expect(FluentBar.info<void>('x').toString(), isNot(contains('tags')));
    });
  });
}
