import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void tapA(String? payload) {}
  void tapB(String? payload) {}
  void pressA(FluentBarController<String> controller, String? payload) {}
  void pressB(FluentBarController<String> controller, String? payload) {}
  Widget builderA(BuildContext context, FluentBarEntry<String> entry) => const SizedBox();
  Widget builderB(BuildContext context, FluentBarEntry<String> entry) => const SizedBox();
  Widget positionA(BuildContext context, Widget child) => child;
  Widget positionB(BuildContext context, Widget child) => child;

  FluentBarItem<String> base() => FluentBarItem<String>(
    type: FluentBarType.info,
    message: 'Message',
    isPersistent: true,
    callbacks: FluentBarCallbacks<String>(onTap: tapA),
    actions: FluentBarActions<String>(label: 'Undo', onPressed: pressA),
    appearance: FluentBarAppearance<String>(builder: builderA),
    behavior: FluentBarBehavior(positionBuilder: positionA),
  );

  int notificationsFor(FluentBarItem<String> next) {
    final FluentBarControllerImpl<String> controller = FluentBarControllerImpl<String>(base());
    int notifications = 0;
    controller.itemNotifier.addListener(() => notifications++);

    controller.rebindItem(next);

    controller.dispose();
    return notifications;
  }

  test('an equal item with the same callbacks and builders does not notify', () {
    expect(notificationsFor(base()), 0);
  });

  test('a content change notifies', () {
    expect(notificationsFor(base().copyWith(message: 'Other')), 1);
  });

  group('callbacks', () {
    test('new instances with the same functions do not notify', () {
      expect(notificationsFor(base().copyWith(callbacks: FluentBarCallbacks<String>(onTap: tapA))), 0);
    });

    test('a replaced callback notifies', () {
      expect(notificationsFor(base().copyWith(callbacks: FluentBarCallbacks<String>(onTap: tapB))), 1);
      expect(
        notificationsFor(
          base().copyWith(
            callbacks: FluentBarCallbacks<String>(onTap: tapA, onShow: (_) {}),
          ),
        ),
        1,
      );
    });

    test('adding callbacks to an item that had none notifies', () {
      final FluentBarItem<String> without = FluentBarItem<String>(type: FluentBarType.info, message: 'Message', isPersistent: true);
      final FluentBarControllerImpl<String> controller = FluentBarControllerImpl<String>(without);
      int notifications = 0;
      controller.itemNotifier.addListener(() => notifications++);

      controller.rebindItem(without.copyWith(callbacks: FluentBarCallbacks<String>(onTap: tapA)));

      expect(notifications, 1);
      controller.dispose();
    });
  });

  group('actions', () {
    test('new instances with the same label and handler do not notify', () {
      expect(
        notificationsFor(
          base().copyWith(
            actions: FluentBarActions<String>(label: 'Undo', onPressed: pressA),
          ),
        ),
        0,
      );
    });

    test('a replaced handler, child or loading widget notifies', () {
      expect(
        notificationsFor(
          base().copyWith(
            actions: FluentBarActions<String>(label: 'Undo', onPressed: pressB),
          ),
        ),
        1,
      );
      expect(
        notificationsFor(
          base().copyWith(
            actions: FluentBarActions<String>(label: 'Undo', onPressed: pressA, child: const Text('x')),
          ),
        ),
        1,
      );
      expect(
        notificationsFor(
          base().copyWith(
            actions: FluentBarActions<String>(label: 'Undo', onPressed: pressA, actionLoadingWidget: const SizedBox()),
          ),
        ),
        1,
      );
    });

    test('removing the actions notifies', () {
      expect(notificationsFor(base().copyWith(clearActions: true)), 1);
    });
  });

  group('builders', () {
    test('new appearance with the same builder does not notify; a replaced builder does', () {
      expect(notificationsFor(base().copyWith(appearance: FluentBarAppearance<String>(builder: builderA))), 0);
      expect(notificationsFor(base().copyWith(appearance: FluentBarAppearance<String>(builder: builderB))), 1);
      expect(
        notificationsFor(
          base().copyWith(
            appearance: FluentBarAppearance<String>(builder: builderA, transitionBuilder: (BuildContext c, Animation<double> a, Widget child) => child),
          ),
        ),
        1,
      );
    });

    test('a replaced position builder notifies', () {
      expect(notificationsFor(base().copyWith(behavior: FluentBarBehavior(positionBuilder: positionA))), 0);
      expect(notificationsFor(base().copyWith(behavior: FluentBarBehavior(positionBuilder: positionB))), 1);
    });
  });

  group('progress', () {
    (FluentBarControllerImpl<String>, List<int>) track(FluentBarProgressState? initial) {
      final FluentBarControllerImpl<String> controller = FluentBarControllerImpl<String>(base().copyWith(progressState: initial));
      final List<int> counts = <int>[0, 0];
      controller.itemNotifier.addListener(() => counts[0]++);
      controller.progressStateNotifier.addListener(() => counts[1]++);
      addTearDown(controller.dispose);
      return (controller, counts);
    }

    test('a new progress value does not notify item listeners, but the item stays up to date', () {
      final (FluentBarControllerImpl<String> controller, List<int> counts) = track(const FluentBarProgressValue(0.1));

      for (int i = 2; i <= 9; i++) {
        controller.updateProgress(FluentBarProgressValue(i / 10));
      }

      expect(counts[0], 0, reason: 'the bar itself must not rebuild on every progress tick');
      expect(counts[1], 8, reason: 'the progress indicator has its own notifier');
      expect(controller.itemNotifier.value.progressState, const FluentBarProgressValue(0.9));
      expect(controller.taskProgressNotifier.value, 0.9);
    });

    test('fractions behave the same way', () {
      final (FluentBarControllerImpl<String> controller, List<int> counts) = track(const FluentBarProgressFraction(1, 5));

      controller.updateProgress(const FluentBarProgressFraction(2, 5));
      controller.updateProgress(const FluentBarProgressFraction(3, 5));

      expect(counts[0], 0);
      expect(counts[1], 2);
      expect(controller.itemNotifier.value.progressState, const FluentBarProgressFraction(3, 5));
    });

    test('progress appearing, completing, changing kind or disappearing notifies item listeners', () {
      final (FluentBarControllerImpl<String> controller, List<int> counts) = track(null);

      controller.updateProgress(const FluentBarProgressValue(0.1));
      expect(counts[0], 1, reason: 'appeared: the bar gets an indicator and becomes persistent');

      controller.updateProgress(const FluentBarProgressFraction(1, 5));
      expect(counts[0], 2, reason: 'kind changed: percent -> fraction');

      controller.updateProgress(const FluentBarProgressIndeterminate());
      expect(counts[0], 3, reason: 'kind changed: fraction -> indeterminate');

      controller.updateProgress(const FluentBarProgressValue(1.0));
      expect(counts[0], 4, reason: 'completed: the bar is timed again');

      controller.cancelProgress();
      expect(counts[0], 5, reason: 'disappeared');
    });

    test('a progress value that arrives together with other changes still notifies', () {
      final (FluentBarControllerImpl<String> controller, List<int> counts) = track(const FluentBarProgressValue(0.1));

      controller.rebindItem(base().copyWith(message: 'Almost there', progressState: const FluentBarProgressValue(0.8)));

      expect(counts[0], 1);
      expect(controller.itemNotifier.value.message, 'Almost there');
    });

    test('item equality still includes progress', () {
      final FluentBarItem<String> a = base().copyWith(progressState: const FluentBarProgressValue(0.1));
      final FluentBarItem<String> b = a.copyWith(progressState: const FluentBarProgressValue(0.2));

      expect(a == b, isFalse);
      expect(a.isSameIgnoringProgress(b), isTrue);
      expect(a.isSameIgnoringProgress(b.copyWith(message: 'Other')), isFalse);
    });
  });

  test('the value is replaced even when listeners are not notified', () {
    final FluentBarControllerImpl<String> controller = FluentBarControllerImpl<String>(base());
    final FluentBarItem<String> next = base();

    controller.rebindItem(next);

    expect(controller.itemNotifier.value, isNot(same(next)));
    expect(controller.itemNotifier.value.callbacks, same(next.callbacks));
    controller.dispose();
  });
}
