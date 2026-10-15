import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  final List<FluentBarException> errors = <FluentBarException>[];
  final List<FluentBarAnalyticsEvent> events = <FluentBarAnalyticsEvent>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
  void onAnalytics(FluentBarAnalyticsPayload payload) => events.add(payload.event);

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    errors.clear();
    events.clear();
    FluentBar.addErrorHandler(onError);
    FluentBar.addAnalyticsListener(onAnalytics);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBar.removeAnalyticsListener(onAnalytics);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
    FluentBarManager.bindingLookup = FluentBarManager.defaultBindingLookup;
  });

  Widget app({FluentBarConfig? config, Widget? bottomNavigationBar, Widget body = const SizedBox()}) => MaterialApp(
    builder: FluentBarScope.builder(config: config ?? const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
    home: Scaffold(body: body, bottomNavigationBar: bottomNavigationBar),
  );

  Future<void> boot(WidgetTester tester, {FluentBarConfig? config, Widget? bottomNavigationBar}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(config: config, bottomNavigationBar: bottomNavigationBar));
    await tester.pump();
    errors.clear();
    events.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> shown(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Duration remaining(FluentBarEntry<dynamic> entry) => entry.controller.remainingDurationNotifier.value;

  group('pause on touch', () {
    testWidgets('holding a finger on the bar stops the countdown; releasing resumes it', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Hold me', duration: const Duration(seconds: 5));
      await shown(tester);
      expect(remaining(entry!), const Duration(seconds: 4));

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry));
      expect(remaining(entry), const Duration(seconds: 4));

      await gesture.moveBy(const Offset(0, 300));
      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
      expect(FluentBar.mainActiveItem, same(entry));

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('a cancelled touch resumes the countdown too', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Hold me', duration: const Duration(seconds: 5));
      await shown(tester);

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
      await tester.pump(const Duration(seconds: 10));
      await gesture.cancel();
      await tester.pump(const Duration(seconds: 2));

      expect(remaining(entry!), const Duration(seconds: 2));
      await cleanup(tester);
    });

    testWidgets('hovering with a mouse stops the countdown; leaving resumes it', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Hover me', duration: const Duration(seconds: 5));
      await shown(tester);

      final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Hover me')));
      await tester.pump(const Duration(seconds: 30));
      expect(remaining(entry!), const Duration(seconds: 4));

      await mouse.moveTo(const Offset(5, 590));
      await tester.pump(const Duration(seconds: 1));
      expect(remaining(entry), const Duration(seconds: 3));
      await cleanup(tester);
    });

    testWidgets('is independent of explicit pause() and of loading', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Hold me', duration: const Duration(seconds: 5));
      await shown(tester);

      entry!.controller.pause();
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
      await gesture.moveBy(const Offset(0, 300));
      await gesture.up();
      await tester.pump(const Duration(seconds: 30));
      expect(remaining(entry), const Duration(seconds: 4), reason: 'releasing a touch must not cancel an explicit pause');

      entry.controller.resume();
      await tester.pump(const Duration(seconds: 1));
      expect(remaining(entry), const Duration(seconds: 3));
      await cleanup(tester);
    });

    testWidgets('can be turned off: bar -> type -> config', (WidgetTester tester) async {
      Future<Duration> afterHolding({FluentBarConfig? config, FluentBarType type = FluentBarType.info, bool? local}) async {
        await boot(tester, config: config);
        final FluentBarEntry<void>? entry = FluentBar.show<void>(
          message: 'Bar',
          type: type,
          duration: const Duration(seconds: 50),
          options: FluentBarOptions<void>(behavior: FluentBarBehavior(pauseOnTouch: local)),
        );
        await shown(tester);
        final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Bar')));
        await tester.pump(const Duration(seconds: 10));
        final Duration left = remaining(entry!);
        await gesture.moveBy(const Offset(0, 300));
        await gesture.up();
        await cleanup(tester);
        return left;
      }

      const Duration paused = Duration(seconds: 49);
      const Duration running = Duration(seconds: 39);
      const FluentBarConfig off = FluentBarConfig(defaultPauseOnTouch: false, defaultTransitionDuration: Duration.zero);
      final FluentBarType typeOn = FluentBarType.info.copyWith(pauseOnTouch: true);
      final FluentBarType typeOff = FluentBarType.info.copyWith(pauseOnTouch: false);

      expect(await afterHolding(), paused, reason: 'on by default');
      expect(await afterHolding(config: off), running);
      expect(
        await afterHolding(config: off, type: typeOn),
        paused,
        reason: 'type beats config',
      );
      expect(await afterHolding(type: typeOff), running);
      expect(await afterHolding(type: typeOff, local: true), paused, reason: 'bar beats type');
      expect(await afterHolding(local: false), running);
    });

    testWidgets('turning it off while the bar is held releases the hold', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Hold me', duration: const Duration(seconds: 50));
      await shown(tester);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));
      await tester.pump(const Duration(seconds: 5));

      entry!.controller.updateBehavior(behavior: const FluentBarBehavior(pauseOnTouch: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(remaining(entry), const Duration(seconds: 44));
      await gesture.up();
      await cleanup(tester);
    });

    testWidgets('a bar removed while it is held does not leave anything behind', (WidgetTester tester) async {
      await boot(tester);
      FluentBar.show<void>(message: 'Hold me', duration: const Duration(seconds: 50));
      await shown(tester);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Hold me')));

      await FluentBar.closeAll(skipAnimation: true);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(FluentBar.activeItems, isEmpty);
    });
  });

  group('accessibility', () {
    testWidgets('the bar is a live region that reads its title and message', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.show<void>(message: 'Saved', title: 'Profile', isPersistent: true);
      await shown(tester);

      final SemanticsNode node = tester.getSemantics(find.byType(DefaultFluentBarWidget<void>));
      // ignore: deprecated_member_use
      expect(node, containsSemantics(isLiveRegion: true));
      expect(node.label, contains('Profile'));
      expect(node.label, contains('Saved'));

      await cleanup(tester);
      handle.dispose();
    });

    testWidgets('the screen reader "dismiss" action closes a bar that can be closed by hand', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.show<void>(message: 'Dismissible', isPersistent: true);
      await shown(tester);

      final SemanticsNode node = tester.getSemantics(find.byType(DefaultFluentBarWidget<void>));
      expect(node.getSemanticsData().hasAction(SemanticsAction.dismiss), isTrue);
      tester.semantics.performAction(find.semantics.byAction(SemanticsAction.dismiss), SemanticsAction.dismiss);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(FluentBar.mainActiveItem, isNull);
      handle.dispose();
    });

    testWidgets('a bar that cannot be closed by hand does not offer "dismiss"', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      FluentBar.show<void>(
        message: 'Sticky',
        isPersistent: true,
        options: const FluentBarOptions<void>(behavior: FluentBarBehavior(isSwipeEnabled: false, dismissOnTap: false)),
      );
      await shown(tester);

      final SemanticsNode node = tester.getSemantics(find.byType(DefaultFluentBarWidget<void>));
      expect(node.getSemanticsData().hasAction(SemanticsAction.dismiss), isFalse);

      await cleanup(tester);
      handle.dispose();
    });

    testWidgets('the action is announced as a button, disabled while it runs', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(
        message: 'With action',
        isPersistent: true,
        options: const FluentBarOptions<void>(actions: FluentBarActions<void>(label: 'UNDO', closeOnAction: false)),
      );
      await shown(tester);

      expect(tester.getSemantics(find.byType(FluentBarAction<void>)), matchesSemantics(label: 'UNDO', isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true));

      entry!.controller.setLoading(isLoading: true);
      await tester.pump();
      // ignore: deprecated_member_use
      expect(tester.getSemantics(find.byType(FluentBarAction<void>)), containsSemantics(isButton: true, hasEnabledState: true, isEnabled: false));

      entry.controller.setLoading(isLoading: false);
      await cleanup(tester);
      handle.dispose();
    });
  });

  group('completeProgress / failProgress', () {
    Future<(FluentBarEntry<String>, List<String>)> progressBar(WidgetTester tester, FluentBarProgressState state) async {
      await boot(tester);
      final List<String> calls = <String>[];
      final FluentBarEntry<String>? entry = FluentBar.show<String>(
        message: 'Uploading',
        title: 'Upload',
        duration: const Duration(seconds: 3),
        options: FluentBarOptions<String>(
          progressState: state,
          callbacks: FluentBarCallbacks<String>(onProgressCompleted: (_) => calls.add('completed'), onProgressFailed: (_) => calls.add('failed'), onProgressCanceled: (_) => calls.add('canceled')),
        ),
      );
      await shown(tester);
      return (entry!, calls);
    }

    testWidgets('completeProgress shows success, applies the new texts and type, then times out', (WidgetTester tester) async {
      final (FluentBarEntry<String> entry, List<String> calls) = await progressBar(tester, const FluentBarProgressState.indeterminate());
      await tester.pump(const Duration(seconds: 30));
      expect(FluentBar.mainActiveItem, same(entry), reason: 'persistent while in progress');

      entry.completeProgress(message: 'Uploaded', title: 'Done', type: FluentBarType.success);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(calls, <String>['completed']);
      expect(events, contains(FluentBarAnalyticsEvent.progressCompleted));
      expect(entry.item.message, 'Uploaded');
      expect(entry.item.title, 'Done');
      expect(entry.item.type, FluentBarType.success);
      expect(entry.item.progressState?.isCompleted, isTrue);
      expect(find.byKey(const ValueKey<String>('success_icon')), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('completeProgress keeps the kind of progress: a fraction ends as "total / total"', (WidgetTester tester) async {
      final (FluentBarEntry<String> entry, _) = await progressBar(tester, const FluentBarProgressFraction(2, 7));

      entry.controller.completeProgress();

      expect(entry.item.progressState, const FluentBarProgressFraction(7, 7));
      expect(entry.item.message, 'Uploading', reason: 'texts stay when nothing is passed');
      expect(entry.item.type, FluentBarType.info);
      await cleanup(tester);
    });

    testWidgets('completeProgress twice reports completion once', (WidgetTester tester) async {
      final (FluentBarEntry<String> entry, List<String> calls) = await progressBar(tester, const FluentBarProgressValue(0.5));

      entry.controller.completeProgress();
      entry.controller.completeProgress(message: 'Again');

      expect(calls, <String>['completed']);
      await cleanup(tester);
    });

    testWidgets('failProgress removes the indicator, turns the bar into an error and times out', (WidgetTester tester) async {
      final (FluentBarEntry<String> entry, List<String> calls) = await progressBar(tester, const FluentBarProgressValue(0.4));

      entry.failProgress(message: 'Upload failed');
      await tester.pump();

      expect(calls, <String>['failed']);
      expect(events, contains(FluentBarAnalyticsEvent.progressFailed));
      expect(events, isNot(contains(FluentBarAnalyticsEvent.progressCompleted)));
      expect(entry.item.message, 'Upload failed');
      expect(entry.item.title, 'Upload');
      expect(entry.item.type, FluentBarType.error, reason: 'error by default');
      expect(entry.item.progressState, isNull);
      expect(remaining(entry), const Duration(seconds: 3));

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('failProgress accepts its own title and type', (WidgetTester tester) async {
      final (FluentBarEntry<String> entry, _) = await progressBar(tester, const FluentBarProgressValue(0.4));

      entry.controller.failProgress(title: 'Oops', type: FluentBarType.warning);

      expect(entry.item.title, 'Oops');
      expect(entry.item.type, FluentBarType.warning);
      expect(entry.item.message, 'Uploading');
      await cleanup(tester);
    });

    testWidgets('success, failure and cancellation are three different outcomes', (WidgetTester tester) async {
      final (FluentBarEntry<String> a, List<String> callsA) = await progressBar(tester, const FluentBarProgressValue(0.1));
      a.controller.cancelProgress(fallbackMessage: 'Stopped');
      expect(callsA, <String>['canceled']);
      expect(a.item.type, FluentBarType.info, reason: 'cancel keeps the type unless told otherwise');
      expect(events, contains(FluentBarAnalyticsEvent.progressCanceled));
      await cleanup(tester);
    });

    testWidgets('a throwing onProgressFailed is reported and does not break the bar', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void>? entry = FluentBar.show<void>(
        message: 'Uploading',
        isPersistent: true,
        options: FluentBarOptions<void>(
          progressState: const FluentBarProgressValue(0.2),
          callbacks: FluentBarCallbacks<void>(onProgressFailed: (_) => throw Exception('boom')),
        ),
      );
      await shown(tester);

      entry!.controller.failProgress();
      await tester.pump();

      expect(errors.single.type, FluentBarErrorType.callbackProgressFailed);
      expect(entry.item.type, FluentBarType.error);
      await cleanup(tester);
    });

    test('both are safe after dispose and work without a manager', () {
      final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(
        FluentBarItem<void>(type: FluentBarType.info, message: 'Bar', isPersistent: true, progressState: const FluentBarProgressValue(0.3)),
      );

      controller.failProgress(message: 'Failed');
      expect(controller.itemNotifier.value.message, 'Failed');
      expect(controller.itemNotifier.value.type, FluentBarType.error);

      controller.dispose();
      controller.completeProgress();
      controller.failProgress();
    });
  });

  group('FluentBar.future', () {
    testWidgets('success: the loading bar turns into a success bar with the built message and times out', (WidgetTester tester) async {
      await boot(tester);
      final Completer<int> work = Completer<int>();

      final Future<int> returned = FluentBar.future<int>(work.future, loading: 'Saving…', title: 'Profile', id: 'save', success: (int count) => 'Saved $count items', error: (Object e) => 'Failed');
      await shown(tester);

      expect(returned, same(work.future));
      final FluentBarEntry<dynamic> entry = FluentBar.mainActiveItem!;
      expect(entry.item.message, 'Saving…');
      expect(entry.item.title, 'Profile');
      expect(entry.item.id, 'save');
      expect(entry.item.progressState, const FluentBarProgressState.indeterminate());
      await tester.pump(const Duration(minutes: 5));
      expect(FluentBar.mainActiveItem, same(entry), reason: 'stays while the future is running');

      work.complete(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(await returned, 3);
      expect(entry.item.message, 'Saved 3 items');
      expect(entry.item.type, FluentBarType.success);
      expect(events, contains(FluentBarAnalyticsEvent.progressCompleted));

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      expect(FluentBar.mainActiveItem, isNull);
    });

    testWidgets('failure: the bar turns into an error bar, and the caller still gets the error', (WidgetTester tester) async {
      await boot(tester);
      final Completer<int> work = Completer<int>();
      Object? caught;

      final Future<int> returned = FluentBar.future<int>(work.future, loading: 'Saving…', error: (Object e) => 'Failed: $e');
      unawaited(returned.then<void>((_) {}, onError: (Object e) => caught = e));
      await shown(tester);
      final FluentBarEntry<dynamic> entry = FluentBar.mainActiveItem!;

      work.completeError(StateError('no network'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(caught, isA<StateError>());
      expect(entry.item.message, contains('no network'));
      expect(entry.item.type, FluentBarType.error);
      expect(entry.item.progressState, isNull);
      expect(events, contains(FluentBarAnalyticsEvent.progressFailed));
      await cleanup(tester);
    });

    testWidgets('without message builders only the type changes; custom types are respected', (WidgetTester tester) async {
      await boot(tester);
      final Completer<void> ok = Completer<void>();
      final Completer<void> bad = Completer<void>();

      unawaited(FluentBar.future<void>(ok.future, loading: 'Working', successType: FluentBarType.info));
      unawaited(
        FluentBar.future<void>(
          bad.future,
          loading: 'Working below',
          errorType: FluentBarType.warning,
          options: const FluentBarOptions<void>(behavior: FluentBarBehavior(position: FluentBarPosition.bottom)),
        ).then<void>((_) {}, onError: (Object _) {}),
      );
      await shown(tester);

      ok.complete();
      bad.completeError(Exception('x'));
      await tester.pump();

      expect(FluentBar.mainActiveItem!.item.message, 'Working');
      expect(FluentBar.mainActiveItem!.item.type, FluentBarType.info);
      expect(FluentBar.bottomActiveItem!.item.message, 'Working below');
      expect(FluentBar.bottomActiveItem!.item.type, FluentBarType.warning);
      await cleanup(tester);
    });

    testWidgets('throwing message builders are reported and the previous text is kept', (WidgetTester tester) async {
      await boot(tester);
      final Completer<int> ok = Completer<int>();
      final Completer<int> bad = Completer<int>();

      unawaited(FluentBar.future<int>(ok.future, loading: 'Top', success: (int r) => throw Exception('success builder')));
      unawaited(
        FluentBar.future<int>(
          bad.future,
          loading: 'Bottom',
          error: (Object e) => throw Exception('error builder'),
          options: const FluentBarOptions<void>(behavior: FluentBarBehavior(position: FluentBarPosition.bottom)),
        ).then<void>((_) {}, onError: (Object _) {}),
      );
      await shown(tester);

      ok.complete(1);
      bad.completeError(Exception('x'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(FluentBar.mainActiveItem!.item.message, 'Top');
      expect(FluentBar.mainActiveItem!.item.type, FluentBarType.success);
      expect(FluentBar.bottomActiveItem!.item.message, 'Bottom');
      expect(FluentBar.bottomActiveItem!.item.type, FluentBarType.error);
      expect(errors.map((FluentBarException e) => e.type), everyElement(FluentBarErrorType.fluentBarResolver));
      expect(errors, hasLength(2));
      await cleanup(tester);
    });

    testWidgets('a bar closed before the future completes is simply left alone', (WidgetTester tester) async {
      await boot(tester);
      final Completer<int> work = Completer<int>();
      unawaited(FluentBar.future<int>(work.future, loading: 'Saving…', success: (int r) => 'Saved'));
      await shown(tester);

      await FluentBar.closeAll(skipAnimation: true);
      await tester.pump();
      work.complete(1);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(FluentBar.activeItems, isEmpty);
      expect(errors, isEmpty);
    });

    testWidgets('when the bar cannot be shown (queue is full) the future is returned untouched', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(maxQueueLength: 1));
      FluentBar.show<void>(message: 'Active', isPersistent: true);
      FluentBar.show<void>(message: 'Queued', isPersistent: true);
      final Completer<int> work = Completer<int>();

      final Future<int> returned = FluentBar.future<int>(work.future, loading: 'No room');
      work.complete(5);

      expect(returned, same(work.future));
      expect(await returned, 5);
      await cleanup(tester);
    });

    testWidgets('options are passed through, including an explicit progress state', (WidgetTester tester) async {
      await boot(tester);
      final Completer<void> work = Completer<void>();

      unawaited(
        FluentBar.future<void>(
          work.future,
          loading: 'Step',
          options: const FluentBarOptions<void>(
            progressState: FluentBarProgressFraction(1, 3),
            meta: <String, dynamic>{'k': 1},
            behavior: FluentBarBehavior(position: FluentBarPosition.bottom),
          ),
        ),
      );
      await shown(tester);

      final FluentBarEntry<dynamic> entry = FluentBar.bottomActiveItem!;
      expect(entry.item.progressState, const FluentBarProgressFraction(1, 3));
      expect(entry.item.meta, <String, dynamic>{'k': 1});

      work.complete();
      await tester.pump();
      expect(entry.item.progressState, const FluentBarProgressFraction(3, 3));
      await cleanup(tester);
    });
  });

  group('bottom inset (bars above the bottom navigation bar)', () {
    Widget navBar({double height = 80}) => FluentBarBottomInset(
      child: SizedBox(
        key: const Key('nav'),
        height: height,
        child: const ColoredBox(color: Colors.grey),
      ),
    );

    FluentBarEntry<void>? showBottom(String message) => FluentBar.show<void>(
      message: message,
      isPersistent: true,
      options: const FluentBarOptions<void>(behavior: FluentBarBehavior(position: FluentBarPosition.bottom)),
    );

    testWidgets('a bottom bar is lifted above a wrapped navigation bar; a top bar is not affected', (WidgetTester tester) async {
      await boot(tester, bottomNavigationBar: navBar());
      showBottom('Bottom');
      FluentBar.show<void>(message: 'Top', isPersistent: true);
      await shown(tester);

      expect(FluentBar.measuredBottomInset.value, 80);
      expect(manager.bottomInsetNotifier.value, 80);
      final Rect nav = tester.getRect(find.byKey(const Key('nav')));
      final Rect bar = tester.getRect(find.text('Bottom'));
      expect(bar.bottom, lessThanOrEqualTo(nav.top));
      expect(tester.getRect(find.text('Top')).top, lessThan(100));
      await cleanup(tester);
    });

    testWidgets('without a navigation bar the bar sits at the bottom edge', (WidgetTester tester) async {
      await boot(tester);
      showBottom('Bottom');
      await shown(tester);

      expect(manager.bottomInsetNotifier.value, 0);
      final double screenBottom = tester.getSize(find.byType(MaterialApp)).height;
      expect(screenBottom - tester.getRect(find.byType(DefaultFluentBarWidget<void>)).bottom, closeTo(0, 0.5));
      await cleanup(tester);
    });

    testWidgets('the bar follows the navigation bar when its height changes or it disappears', (WidgetTester tester) async {
      await boot(tester, bottomNavigationBar: navBar(height: 60));
      showBottom('Bottom');
      await shown(tester);
      expect(manager.bottomInsetNotifier.value, 60);
      final double initial = tester.getRect(find.text('Bottom')).bottom;

      await tester.pumpWidget(app(bottomNavigationBar: navBar(height: 120)));
      await tester.pump();
      await tester.pump();
      expect(manager.bottomInsetNotifier.value, 120);
      expect(tester.getRect(find.text('Bottom')).bottom, closeTo(initial - 60, 0.5));

      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(manager.bottomInsetNotifier.value, 0);
      expect(tester.getRect(find.text('Bottom')).bottom, closeTo(initial + 60, 0.5));
      await cleanup(tester);
    });

    testWidgets('a screen pushed over the navigation bar removes the inset; going back restores it', (WidgetTester tester) async {
      manager.resetForTesting();
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: FluentBarScope.builder(),
          home: Scaffold(body: const SizedBox(), bottomNavigationBar: navBar()),
        ),
      );
      await tester.pump();
      expect(manager.bottomInsetNotifier.value, 80);

      unawaited(navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Details')))));
      await tester.pumpAndSettle();
      expect(manager.bottomInsetNotifier.value, 0);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(manager.bottomInsetNotifier.value, 80);
      await cleanup(tester);
    });

    testWidgets('config.bottomInset is a fixed value that replaces the measured one', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(bottomInset: 100));
      showBottom('Bottom');
      await shown(tester);
      final double withConfigOnly = tester.getRect(find.text('Bottom')).bottom;

      await tester.pumpWidget(app(config: const FluentBarConfig(bottomInset: 100), bottomNavigationBar: navBar(height: 40)));
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(find.text('Bottom')).bottom, closeTo(withConfigOnly, 0.5), reason: 'a smaller panel changes nothing');

      await tester.pumpWidget(app(config: const FluentBarConfig(bottomInset: 100), bottomNavigationBar: navBar(height: 160)));
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(find.text('Bottom')).bottom, closeTo(withConfigOnly, 0.5), reason: 'a larger panel changes nothing either: the config value is explicit');

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(clearBottomInset: true));
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(find.text('Bottom')).bottom, closeTo(withConfigOnly - 60, 0.5));
      await cleanup(tester);
    });

    testWidgets('with useSafeArea: false the inset is still applied', (WidgetTester tester) async {
      await boot(tester, bottomNavigationBar: navBar());
      FluentBar.show<void>(
        message: 'Bottom',
        isPersistent: true,
        options: const FluentBarOptions<void>(behavior: FluentBarBehavior(position: FluentBarPosition.bottom, useSafeArea: false)),
      );
      await shown(tester);

      expect(tester.getRect(find.text('Bottom')).bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const Key('nav'))).top));
      await cleanup(tester);
    });

    testWidgets('a custom positionBuilder is in full control: no inset is added', (WidgetTester tester) async {
      await boot(tester, bottomNavigationBar: navBar());
      FluentBar.show<void>(
        message: 'Custom',
        isPersistent: true,
        options: FluentBarOptions<void>(
          behavior: FluentBarBehavior(
            position: FluentBarPosition.bottom,
            useSafeArea: false,
            positionBuilder: (BuildContext context, Widget child) => Align(alignment: Alignment.bottomCenter, child: child),
          ),
        ),
      );
      await shown(tester);

      expect(tester.getRect(find.text('Custom')).bottom, greaterThan(tester.getRect(find.byKey(const Key('nav'))).top));
      await cleanup(tester);
    });

    test('several owners: the largest active inset is used', () {
      manager.resetForTesting();
      final Object first = Object();
      final Object second = Object();

      manager.setBottomInset(first, 50);
      manager.setBottomInset(second, 90);
      expect(manager.bottomInsetNotifier.value, 90);

      manager.setBottomInset(second, null);
      expect(manager.bottomInsetNotifier.value, 50);

      manager.setBottomInset(first, 0);
      expect(manager.bottomInsetNotifier.value, 0);
      manager.setBottomInset(first, null);
      manager.setBottomInset(first, null);
      expect(manager.bottomInsetNotifier.value, 0);
    });
  });

  group('before Flutter is running', () {
    test('the default lookup returns the binding once it exists', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(FluentBarManager.defaultBindingLookup(), same(WidgetsBinding.instance));
    });

    testWidgets('initialize, updateConfig and show do not need a binding', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      FluentBarManager.bindingLookup = () => null;

      FluentBar.initialize(config: const FluentBarConfig(maxQueueLength: 4));
      FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 5));
      final FluentBarEntry<void>? entry = FluentBar.show<void>(message: 'Before runApp', isPersistent: true);

      expect(errors, isEmpty);
      expect(entry, isNotNull);
      expect(FluentBar.currentConfig.maxQueueLength, 5);
      expect(FluentBar.mainQueueLength, 1);

      await tester.pump(const Duration(milliseconds: 1));
      expect(FluentBar.mainQueueLength, 1);
      await cleanup(tester);
    });

    testWidgets('a bar requested before runApp is shown once the app is up, even without a scope', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

      bool flutterStarted = false;
      FluentBarManager.bindingLookup = () => flutterStarted ? WidgetsBinding.instance : null;
      FluentBar.initialize(config: const FluentBarConfig(), navigatorKey: navigatorKey);
      FluentBar.show<void>(message: 'Early', isPersistent: true);

      flutterStarted = true;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(find.text('Early'), findsOneWidget);
      expect(FluentBar.mainQueueLength, 0);
      await cleanup(tester);
    });

    testWidgets('with a binding, a bar that has no overlay yet is retried after the frame', (WidgetTester tester) async {
      manager.resetForTesting();
      await tester.pumpWidget(const SizedBox());
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      FluentBar.initialize(config: const FluentBarConfig(), navigatorKey: navigatorKey);
      await tester.pump();

      FluentBar.show<void>(message: 'Waiting', isPersistent: true);
      FluentBar.show<void>(message: 'Waiting too', isPersistent: true);
      expect(FluentBar.mainQueueLength, 2);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();

      expect(find.text('Waiting'), findsOneWidget);
      expect(FluentBar.mainQueueLength, 1);
      await cleanup(tester);
    });
  });
}
