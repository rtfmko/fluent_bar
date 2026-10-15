import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    FluentBarManager.instance.resetForTesting();
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
  });

  FluentBarItem<String> itemOf({
    Duration? duration = const Duration(seconds: 5),
    bool? isPersistent,
    FluentBarProgressState? progress,
    FluentBarBehavior? behavior,
    FluentBarCallbacks<String>? callbacks,
  }) => FluentBarItem<String>(
    id: 'id',
    type: FluentBarType.info,
    title: 'Title',
    message: 'Message',
    payload: 'payload',
    duration: duration,
    isPersistent: isPersistent,
    progressState: progress,
    behavior: behavior,
    callbacks: callbacks,
  );

  FluentBarControllerImpl<String> create({FluentBarItem<String>? item, bool shown = true}) {
    final FluentBarItem<String> source = item ?? itemOf();
    final FluentBarControllerImpl<String> controller = FluentBarControllerImpl<String>(source);
    if (shown) {
      controller.changeState(FluentBarLifecycleState.showing);
      controller.changeState(FluentBarLifecycleState.visible);
      controller.startTimersOnShow(source.isPersistent == true ? null : source.duration, FluentBarManager.instance);
    }
    return controller;
  }

  Duration remaining(FluentBarControllerImpl<String> c) => c.remainingDurationNotifier.value;

  const Duration s1 = Duration(seconds: 1);

  group('initial state', () {
    test('timed item', () {
      final FluentBarControllerImpl<String> c = create(shown: false);

      expect(c.stateNotifier.value, FluentBarLifecycleState.queued);
      expect(c.itemNotifier.value.message, 'Message');
      expect(c.totalDurationNotifier.value, const Duration(seconds: 5));
      expect(remaining(c), const Duration(seconds: 5));
      expect(c.elapsedDurationNotifier.value, Duration.zero);
      expect(c.remainingProgressNotifier.value, 1.0);
      expect(c.elapsedProgressNotifier.value, 0.0);
      expect(c.taskProgressNotifier.value, isNull);
      expect(c.progressStateNotifier.value, isNull);
      expect(c.isActionExecutingNotifier.value, isFalse);
      expect(c.isDisposed, isFalse);
      expect(c.isClosedBeforeShow, isFalse);
      c.dispose();
    });

    test('persistent item has no lifetime', () {
      final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true), shown: false);

      expect(c.totalDurationNotifier.value, isNull);
      expect(remaining(c), Duration.zero);
      expect(c.remainingProgressNotifier.value, 0.0);
      expect(c.elapsedProgressNotifier.value, 0.0);
      c.dispose();
    });

    test('item with unfinished progress is persistent and exposes the progress', () {
      final FluentBarControllerImpl<String> c = create(item: itemOf(progress: const FluentBarProgressValue(0.3)), shown: false);

      expect(c.totalDurationNotifier.value, isNull);
      expect(c.taskProgressNotifier.value, 0.3);
      expect(c.progressStateNotifier.value, const FluentBarProgressValue(0.3));
      c.dispose();
    });
  });

  group('countdown', () {
    test('does not run until the bar is shown', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(shown: false);
        async.elapse(const Duration(seconds: 30));

        expect(remaining(c), const Duration(seconds: 5));
        expect(c.isDisposed, isFalse);
        c.dispose();
      });
    });

    test('publishes elapsed and remaining time while visible', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        expect(c.elapsedDurationNotifier.value, s1);
        expect(remaining(c), const Duration(seconds: 4));
        expect(c.remainingProgressNotifier.value, closeTo(0.8, 0.001));
        expect(c.elapsedProgressNotifier.value, closeTo(0.2, 0.001));
        c.dispose();
      });
    });

    test('expires and closes itself with final values', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        final List<double> progress = <double>[];
        c.elapsedProgressNotifier.addListener(() => progress.add(c.elapsedProgressNotifier.value));

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(progress.last, 1.0);
        expect(c.isDisposed, isTrue);
      });
    });

    test('a zero duration expires on the next event loop turn', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(duration: Duration.zero));
        expect(c.isDisposed, isFalse);

        async.elapse(Duration.zero);
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('a persistent bar never expires', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
        async.elapse(const Duration(hours: 1));

        expect(c.isDisposed, isFalse);
        expect(async.pendingTimers, isEmpty);
        c.dispose();
      });
    });

    test('stops when the bar starts hiding', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        bool completed = false;
        c.dismiss().then((_) => completed = true);
        expect(c.stateNotifier.value, FluentBarLifecycleState.hiding);

        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 4));
        expect(completed, isFalse);

        c.notifyDismissCompleted();
        async.flushMicrotasks();
        expect(completed, isTrue);
        c.dispose();
      });
    });

    test('stopTimers freezes the countdown for good', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.stopTimers();
        c.resume();
        c.addDuration(s1);
        async.elapse(const Duration(seconds: 30));

        expect(c.isDisposed, isFalse);
        expect(async.pendingTimers, isEmpty);
        c.dispose();
      });
    });
  });

  group('pause / resume', () {
    test('time stands still while paused; repeated calls are no-ops', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.pause();
        c.pause();
        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 4));
        expect(async.pendingTimers, isEmpty);

        c.resume();
        c.resume();
        async.elapse(const Duration(seconds: 3));
        expect(c.isDisposed, isFalse);
        expect(remaining(c), s1);

        async.elapse(s1);
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('pause before show keeps the bar paused once it is shown', () {
      fakeAsync((FakeAsync async) {
        final FluentBarItem<String> item = itemOf();
        final FluentBarControllerImpl<String> c = FluentBarControllerImpl<String>(item);
        c.pause();

        c.changeState(FluentBarLifecycleState.visible);
        c.startTimersOnShow(item.duration, FluentBarManager.instance);
        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 5));

        c.resume();
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });
  });

  group('addDuration / subtractDuration', () {
    test('shift the budget while running', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.addDuration(const Duration(seconds: 3));
        expect(c.totalDurationNotifier.value, const Duration(seconds: 8));
        expect(remaining(c), const Duration(seconds: 7));

        c.subtractDuration(const Duration(seconds: 2));
        expect(c.totalDurationNotifier.value, const Duration(seconds: 6));
        expect(remaining(c), const Duration(seconds: 5));

        async.elapse(const Duration(seconds: 4));
        expect(c.isDisposed, isFalse);
        async.elapse(s1);
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('work while paused and do not resume the bar', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);
        c.pause();

        c.addDuration(const Duration(seconds: 3));
        c.subtractDuration(s1);
        expect(remaining(c), const Duration(seconds: 6));

        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 6));
        expect(c.isDisposed, isFalse);
        c.dispose();
      });
    });

    test('subtracting more than is left is rejected with a warning', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.subtractDuration(const Duration(seconds: 4));
        c.subtractDuration(const Duration(seconds: 10));

        expect(remaining(c), const Duration(seconds: 4));
        expect(errors, hasLength(2));
        expect(errors.first.type, FluentBarErrorType.subtractDuration);
        expect(errors.first.severity, FluentBarErrorSeverity.warning);
        c.dispose();
      });
    });

    test('are ignored for a bar that is not shown or is persistent', () {
      final FluentBarControllerImpl<String> queued = create(shown: false);
      queued.addDuration(s1);
      queued.subtractDuration(s1);
      expect(queued.totalDurationNotifier.value, const Duration(seconds: 5));
      queued.dispose();

      final FluentBarControllerImpl<String> persistent = create(item: itemOf(isPersistent: true));
      persistent.addDuration(s1);
      persistent.subtractDuration(s1);
      expect(persistent.totalDurationNotifier.value, isNull);
      expect(errors, isEmpty);
      persistent.dispose();
    });
  });

  group('updateDuration', () {
    test('without reset keeps the time already spent', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(const Duration(seconds: 2));

        c.updateDuration(const Duration(seconds: 10));

        expect(c.itemNotifier.value.duration, const Duration(seconds: 10));
        expect(c.totalDurationNotifier.value, const Duration(seconds: 10));
        expect(c.elapsedDurationNotifier.value, const Duration(seconds: 2));
        expect(remaining(c), const Duration(seconds: 8));
        c.dispose();
      });
    });

    test('with reset starts the countdown over', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(const Duration(seconds: 2));

        c.updateDuration(const Duration(seconds: 3), resetTimer: true);
        expect(remaining(c), const Duration(seconds: 3));
        expect(c.elapsedDurationNotifier.value, Duration.zero);

        async.elapse(const Duration(seconds: 2));
        expect(c.isDisposed, isFalse);
        async.elapse(s1);
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('explicitly drops time added by addDuration', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        c.addDuration(const Duration(seconds: 20));

        c.updateDuration(const Duration(seconds: 5));
        expect(c.totalDurationNotifier.value, const Duration(seconds: 5));
        c.dispose();
      });
    });

    test('shorter than the time already spent expires the bar', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(const Duration(seconds: 3));

        c.updateDuration(s1);
        expect(remaining(c), Duration.zero);

        async.elapse(Duration.zero);
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('null makes the bar persistent, a new duration makes it timed again', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.updateDuration(null);
        expect(c.itemNotifier.value.isPersistent, isTrue);
        expect(c.itemNotifier.value.duration, isNull);
        expect(c.totalDurationNotifier.value, isNull);
        async.elapse(const Duration(hours: 1));
        expect(c.isDisposed, isFalse);

        c.updateDuration(const Duration(seconds: 2));
        expect(c.itemNotifier.value.isPersistent, isFalse);
        expect(remaining(c), const Duration(seconds: 2));
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });
  });

  group('setLoading', () {
    test('holds the countdown and reports loading', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.setLoading(isLoading: true);
        expect(c.isActionExecutingNotifier.value, isTrue);
        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 4));

        c.setLoading(isLoading: false);
        expect(c.isActionExecutingNotifier.value, isFalse);
        async.elapse(const Duration(seconds: 4));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('with pauseTimeoutTimer: false the countdown keeps running', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();

        c.setLoading(isLoading: true, pauseTimeoutTimer: false);
        expect(c.isActionExecutingNotifier.value, isTrue);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('is independent of an explicit pause', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();

        c.pause();
        c.setLoading(isLoading: true);
        c.setLoading(isLoading: false);
        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 5));

        c.setLoading(isLoading: true);
        c.resume();
        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 5));

        c.setLoading(isLoading: false);
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('disables gestures while loading and restores the previous values', () {
      final FluentBarControllerImpl<String> unset = create(item: itemOf(isPersistent: true));
      unset.setLoading(isLoading: true);
      expect(unset.itemNotifier.value.behavior.isSwipeEnabled, isFalse);
      expect(unset.itemNotifier.value.behavior.dismissOnTap, isFalse);
      unset.setLoading(isLoading: false);
      expect(unset.itemNotifier.value.behavior.isSwipeEnabled, isNull);
      expect(unset.itemNotifier.value.behavior.dismissOnTap, isNull);
      unset.dispose();

      final FluentBarControllerImpl<String> explicit = create(
        item: itemOf(isPersistent: true, behavior: const FluentBarBehavior(isSwipeEnabled: true, dismissOnTap: false, position: FluentBarPosition.bottom)),
      );
      explicit.setLoading(isLoading: true, isSwipeEnabled: true, dismissOnTap: true);
      expect(explicit.itemNotifier.value.behavior.isSwipeEnabled, isTrue);
      expect(explicit.itemNotifier.value.behavior.dismissOnTap, isTrue);
      explicit.setLoading(isLoading: false);
      expect(explicit.itemNotifier.value.behavior.isSwipeEnabled, isTrue);
      expect(explicit.itemNotifier.value.behavior.dismissOnTap, isFalse);
      expect(explicit.itemNotifier.value.behavior.position, FluentBarPosition.bottom, reason: 'other behavior fields must survive');
      explicit.dispose();
    });

    test('repeating the same value changes nothing', () {
      final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
      c.setLoading(isLoading: true);
      c.setLoading(isLoading: true, isSwipeEnabled: true);
      expect(c.itemNotifier.value.behavior.isSwipeEnabled, isFalse);

      c.setLoading(isLoading: false);
      expect(c.itemNotifier.value.behavior.isSwipeEnabled, isNull);
      c.dispose();
    });
  });

  group('handleAction', () {
    test('passes the controller and payload, then closes the bar by default', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        String? received;

        c.handleAction(onPressed: (FluentBarController<String> controller, String? payload) => received = payload);
        async.flushMicrotasks();

        expect(received, 'payload');
        expect(c.isDisposed, isTrue);
      });
    });

    test('with closeOnAction: false keeps the bar and holds time while the action runs', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        final Completer<void> action = Completer<void>();
        async.elapse(s1);

        c.handleAction(onPressed: (_, _) => action.future, closeOnAction: false);
        async.flushMicrotasks();
        expect(c.isActionExecutingNotifier.value, isTrue);

        async.elapse(const Duration(seconds: 30));
        expect(remaining(c), const Duration(seconds: 4));

        action.complete();
        async.flushMicrotasks();
        expect(c.isActionExecutingNotifier.value, isFalse);
        expect(c.isDisposed, isFalse);

        async.elapse(const Duration(seconds: 4));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('ignores a second call while the first one is running', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
        final Completer<void> action = Completer<void>();
        int calls = 0;

        FutureOr<void> onPressed(FluentBarController<String> controller, String? payload) {
          calls++;
          return action.future;
        }

        c.handleAction(onPressed: onPressed, closeOnAction: false, throttleDuration: Duration.zero);
        c.handleAction(onPressed: onPressed, closeOnAction: false, throttleDuration: Duration.zero);
        async.flushMicrotasks();
        expect(calls, 1);

        action.complete();
        async.flushMicrotasks();
        c.dispose();
      });
    });

    test('throttles calls that come too quickly', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
        int calls = 0;
        void onPressed(FluentBarController<String> controller, String? payload) => calls++;

        c.handleAction(onPressed: onPressed, closeOnAction: false, throttleDuration: const Duration(hours: 1));
        async.flushMicrotasks();
        c.handleAction(onPressed: onPressed, closeOnAction: false, throttleDuration: const Duration(hours: 1));
        async.flushMicrotasks();
        expect(calls, 1);

        c.handleAction(onPressed: onPressed, closeOnAction: false, throttleDuration: Duration.zero);
        async.flushMicrotasks();
        expect(calls, 2);
        c.dispose();
      });
    });

    test('a throwing action is reported and does not leave the button loading', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));

        c.handleAction(onPressed: (_, _) => throw Exception('boom'), closeOnAction: false);
        async.flushMicrotasks();

        expect(errors.single.type, FluentBarErrorType.actionPressed);
        expect(c.isActionExecutingNotifier.value, isFalse);
        c.dispose();
      });
    });

    test('does nothing for a bar that is not visible, and works without onPressed', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> queued = create(shown: false);
        int calls = 0;
        queued.handleAction(onPressed: (_, _) => calls++);
        async.flushMicrotasks();
        expect(calls, 0);
        expect(queued.isDisposed, isFalse);
        queued.dispose();

        final FluentBarControllerImpl<String> visible = create();
        visible.handleAction();
        async.flushMicrotasks();
        expect(visible.isDisposed, isTrue);
      });
    });
  });

  group('progress', () {
    test('unfinished progress on a timed bar stops the countdown', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);

        c.updateProgress(const FluentBarProgressValue(0.4));
        expect(c.taskProgressNotifier.value, 0.4);
        expect(c.itemNotifier.value.progressState, const FluentBarProgressValue(0.4));
        expect(c.totalDurationNotifier.value, isNull);

        async.elapse(const Duration(hours: 1));
        expect(c.isDisposed, isFalse);
        c.dispose();
      });
    });

    test('completion applies the completed texts, fires the callback once and restarts the countdown', () {
      fakeAsync((FakeAsync async) {
        int completed = 0;
        final FluentBarControllerImpl<String> c = create(
          item: itemOf(
            progress: const FluentBarProgressFraction(1, 4),
            callbacks: FluentBarCallbacks<String>(onProgressCompleted: (_) => completed++),
          ),
        );
        async.elapse(const Duration(hours: 1));

        c.updateProgress(const FluentBarProgressFraction(4, 4), completedMessage: 'Done', completedTitle: 'Finished', completedType: FluentBarType.success);
        c.updateProgress(const FluentBarProgressFraction(4, 4));
        async.flushMicrotasks();

        expect(completed, 1);
        expect(c.itemNotifier.value.message, 'Done');
        expect(c.itemNotifier.value.title, 'Finished');
        expect(c.itemNotifier.value.type, FluentBarType.success);
        expect(c.taskProgressNotifier.value, 1.0);
        expect(remaining(c), const Duration(seconds: 5));

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('completion keeps the original texts when no completed values are given', () {
      final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true, progress: const FluentBarProgressValue(0.1)));
      c.updateProgress(const FluentBarProgressValue(1.0));

      expect(c.itemNotifier.value.message, 'Message');
      expect(c.itemNotifier.value.title, 'Title');
      expect(c.itemNotifier.value.type, FluentBarType.info);
      c.dispose();
    });

    test('cancelProgress clears the progress, applies fallbacks and restarts the countdown', () {
      fakeAsync((FakeAsync async) {
        int canceled = 0;
        final FluentBarControllerImpl<String> c = create(
          item: itemOf(
            progress: const FluentBarProgressValue(0.5),
            callbacks: FluentBarCallbacks<String>(onProgressCanceled: (_) => canceled++),
          ),
        );

        c.cancelProgress(fallbackMessage: 'Canceled', fallbackType: FluentBarType.warning);
        async.flushMicrotasks();

        expect(canceled, 1);
        expect(c.itemNotifier.value.message, 'Canceled');
        expect(c.itemNotifier.value.type, FluentBarType.warning);
        expect(c.itemNotifier.value.progressState, isNull);
        expect(c.taskProgressNotifier.value, isNull);
        expect(c.progressStateNotifier.value, isNull);
        expect(remaining(c), const Duration(seconds: 5));

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(c.isDisposed, isTrue);
      });
    });

    test('cancelProgress without fallbacks keeps the texts; with dismiss closes the bar', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> kept = create(item: itemOf(progress: const FluentBarProgressValue(0.5)));
        kept.cancelProgress();
        expect(kept.itemNotifier.value.message, 'Message');
        expect(kept.itemNotifier.value.type, FluentBarType.info);
        kept.dispose();

        final FluentBarControllerImpl<String> closed = create(item: itemOf(progress: const FluentBarProgressValue(0.5)));
        closed.cancelProgress(dismiss: true);
        async.flushMicrotasks();
        expect(closed.isDisposed, isTrue);
      });
    });
  });

  group('rebindItem', () {
    test('replaces the content but keeps the identity (uuid) of the bar', () {
      final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
      final String uuid = c.itemNotifier.value.uuid;

      c.rebindItem(FluentBarItem<String>(type: FluentBarType.error, message: 'New', isPersistent: true));

      expect(c.itemNotifier.value.message, 'New');
      expect(c.itemNotifier.value.type, FluentBarType.error);
      expect(c.itemNotifier.value.uuid, uuid);
      c.dispose();
    });

    test('with the same duration keeps spent time and time added by addDuration', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(s1);
        c.addDuration(const Duration(seconds: 10));

        c.rebindItem(itemOf().copyWith(message: 'Other'));
        expect(c.totalDurationNotifier.value, const Duration(seconds: 15));
        expect(remaining(c), const Duration(seconds: 14));
        c.dispose();
      });
    });

    test('with a new duration retargets; with resetTimer starts over', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        async.elapse(const Duration(seconds: 2));

        c.rebindItem(itemOf(duration: const Duration(seconds: 10)));
        expect(remaining(c), const Duration(seconds: 8));

        c.rebindItem(itemOf(duration: const Duration(seconds: 10)), resetTimer: true);
        expect(remaining(c), const Duration(seconds: 10));
        c.dispose();
      });
    });

    test('to a persistent item stops the countdown', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();

        c.rebindItem(itemOf(isPersistent: true));
        expect(c.totalDurationNotifier.value, isNull);
        async.elapse(const Duration(hours: 1));
        expect(c.isDisposed, isFalse);
        c.dispose();
      });
    });

    test('with completed progress counts as completion', () {
      fakeAsync((FakeAsync async) {
        int completed = 0;
        final FluentBarControllerImpl<String> c = create(
          item: itemOf(
            progress: const FluentBarProgressValue(0.5),
            callbacks: FluentBarCallbacks<String>(onProgressCompleted: (_) => completed++),
          ),
        );

        c.rebindItem(
          itemOf(
            progress: const FluentBarProgressValue(1.0),
            callbacks: FluentBarCallbacks<String>(onProgressCompleted: (_) => completed++),
          ),
        );

        expect(completed, 1);
        expect(c.taskProgressNotifier.value, 1.0);
        expect(remaining(c), const Duration(seconds: 5));
        c.dispose();
      });
    });
  });

  group('content updates', () {
    test('updateContent changes only the given fields and notifies listeners', () {
      final FluentBarControllerImpl<String> c = create(shown: false);
      int notifications = 0;
      c.itemNotifier.addListener(() => notifications++);

      c.updateContent(message: 'Changed');
      expect(c.itemNotifier.value.message, 'Changed');
      expect(c.itemNotifier.value.title, 'Title');
      expect(c.itemNotifier.value.payload, 'payload');

      c.updateContent(title: 'T2', payload: 'p2', type: FluentBarType.error);
      expect(c.itemNotifier.value.title, 'T2');
      expect(c.itemNotifier.value.payload, 'p2');
      expect(c.itemNotifier.value.type, FluentBarType.error);

      c.updateContent(message: 'Changed');
      expect(notifications, 2, reason: 'an identical update must not notify');
      c.dispose();
    });

    test('updateActions and updateAppearance replace the values; actions can be cleared', () {
      final FluentBarControllerImpl<String> c = create(shown: false);

      c.updateActions(const FluentBarActions<String>(label: 'Undo'));
      expect(c.itemNotifier.value.actions?.label, 'Undo');
      c.updateActions(null);
      expect(c.itemNotifier.value.actions, isNull);

      c.updateAppearance(const FluentBarAppearance<String>(showIcon: false));
      expect(c.itemNotifier.value.appearance.showIcon, isFalse);
      c.dispose();
    });

    test('updateBehavior can make a timed bar persistent', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();

        c.updateBehavior(behavior: const FluentBarBehavior(dismissOnTap: false), isPersistent: true);
        expect(c.itemNotifier.value.behavior.dismissOnTap, isFalse);
        expect(c.totalDurationNotifier.value, isNull);

        async.elapse(const Duration(hours: 1));
        expect(c.isDisposed, isFalse);
        c.dispose();
      });
    });
  });

  group('effects', () {
    List<FluentBarEffectEvent> listen(FluentBarControllerImpl<String> c) {
      final List<FluentBarEffectEvent> events = <FluentBarEffectEvent>[];
      c.effectStream.listen(events.add);
      return events;
    }

    test('requested before the bar is visible is played once it becomes visible', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(shown: false);
        final List<FluentBarEffectEvent> events = listen(c);

        c.shake();
        c.bounce();
        async.flushMicrotasks();
        expect(events, isEmpty);
        expect(c.latestEffect?.type, FluentBarEffect.bounce);

        c.changeState(FluentBarLifecycleState.visible);
        async.flushMicrotasks();
        expect(events.single.type, FluentBarEffect.bounce, reason: 'only the latest pending effect is played');

        c.clearLatestEffect();
        expect(c.latestEffect, isNull);
        c.dispose();
      });
    });

    test('every effect is emitted with its defaults when the bar is visible', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
        final List<FluentBarEffectEvent> events = listen(c);

        c.shake();
        c.bounce();
        c.pulse();
        c.heartbeat();
        c.customEffect();
        async.flushMicrotasks();

        expect(events.map((FluentBarEffectEvent e) => e.type), FluentBarEffect.values);
        expect(events.map((FluentBarEffectEvent e) => e.intensity), <double>[8.0, 0.1, 1.05, 1.15, 1.0]);
        expect(events.map((FluentBarEffectEvent e) => e.duration.inMilliseconds), <int>[400, 400, 600, 800, 500]);
        expect(events.every((FluentBarEffectEvent e) => !e.repeat), isTrue);
        c.dispose();
      });
    });

    test('triggerEffect uses the same defaults and accepts overrides', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
        final List<FluentBarEffectEvent> events = listen(c);

        for (final FluentBarEffect effect in FluentBarEffect.values) {
          c.triggerEffect(effect);
        }
        c.triggerEffect(FluentBarEffect.shake, intensity: -3, duration: const Duration(seconds: 2), repeat: true);
        async.flushMicrotasks();

        expect(events.take(5).map((FluentBarEffectEvent e) => e.intensity), <double>[8.0, 0.1, 1.05, 1.15, 1.0]);
        expect(events.take(5).map((FluentBarEffectEvent e) => e.duration.inMilliseconds), <int>[400, 400, 600, 800, 500]);
        expect(events.last.intensity, 3.0, reason: 'intensity is taken by absolute value');
        expect(events.last.duration, const Duration(seconds: 2));
        expect(events.last.repeat, isTrue);
        c.dispose();
      });
    });

    test('invalid values are normalised', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(item: itemOf(isPersistent: true));
        final List<FluentBarEffectEvent> events = listen(c);

        c.shake(duration: Duration.zero);
        c.pulse(duration: const Duration(seconds: -1));
        c.bounce(scale: 50);
        async.flushMicrotasks();

        expect(events[0].duration, const Duration(milliseconds: 400));
        expect(events[1].duration, const Duration(milliseconds: 400));
        expect(events[2].intensity, 2.0, reason: 'bounce scale is clamped');
        c.dispose();
      });
    });
  });

  group('close and dispose', () {
    test('closing a bar that was never shown marks and disposes it', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create(shown: false);
        final List<FluentBarLifecycleState> states = <FluentBarLifecycleState>[];
        c.stateNotifier.addListener(() => states.add(c.stateNotifier.value));

        c.close();

        expect(c.isClosedBeforeShow, isTrue);
        expect(states, <FluentBarLifecycleState>[FluentBarLifecycleState.dismissed]);
        expect(c.isDisposed, isTrue);
      });
    });

    test('dispose completes a pending dismiss and is idempotent', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        bool completed = false;
        c.dismiss().then((_) => completed = true);

        c.dispose();
        c.dispose();
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('every public method is safe after dispose', () {
      fakeAsync((FakeAsync async) {
        final FluentBarControllerImpl<String> c = create();
        c.dispose();

        c.pause();
        c.resume();
        c.addDuration(s1);
        c.subtractDuration(s1);
        c.updateDuration(s1, resetTimer: true);
        c.updateContent(message: 'x');
        c.updateBehavior(isPersistent: true);
        c.updateActions(null);
        c.updateAppearance(const FluentBarAppearance<String>());
        c.patchAppearance((FluentBarAppearance<String> a) => a);
        c.patchBehavior((FluentBarBehavior b) => b);
        c.removeAction();
        c.makePersistent();
        c.updateProgress(const FluentBarProgressValue(1.0));
        c.cancelProgress();
        c.setLoading(isLoading: true);
        c.rebindItem(itemOf(), resetTimer: true);
        c.startTimersOnShow(s1, FluentBarManager.instance);
        c.stopTimers();
        c.changeState(FluentBarLifecycleState.visible);
        c.notifyDismissCompleted();
        c.shake();
        c.triggerEffect(FluentBarEffect.pulse);
        c.force();
        c.close();
        c.handleAction(onPressed: (_, _) => fail('must not be called'));
        bool dismissed = false;
        c.dismiss().then((_) => dismissed = true);
        async.flushMicrotasks();

        expect(dismissed, isTrue);
        expect(async.pendingTimers, isEmpty);
        expect(errors, isEmpty);
      });
    });
  });
}
