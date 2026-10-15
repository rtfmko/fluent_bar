import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarActions Tests', () {
    test('should initialize with correct default values', () {
      const FluentBarActions<void> actions = FluentBarActions<void>(label: 'Click');

      expect(actions.label, 'Click');
      expect(actions.closeOnAction, isTrue);
      expect(actions.maxActionLines, isNull);
      expect(actions.actionOverflow, isNull);
      expect(actions.throttleDuration, const Duration(milliseconds: 400));
      expect(actions.actionLoaderColor, isNull);
      expect(actions.actionLoadingWidget, isNull);
      expect(actions.child, isNull);
      expect(actions.onPressed, isNull);
      expect(actions.builder, isNull);
    });

    test('should support copyWith for empty, partial and full updates', () {
      const FluentBarActions<void> actions = FluentBarActions<void>(label: 'Old');

      final FluentBarActions<void> copiedEmpty = actions.copyWith();
      expect(copiedEmpty, equals(actions));

      Future<void> dummyPressed(FluentBarController<void> controller, void payload) async {}
      Widget dummyBuilder(BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode themeMode) => const SizedBox();
      const SizedBox widgetChild = SizedBox();
      const SizedBox loadingWidget = SizedBox(width: 1);

      expect(actions.copyWith(actionLoaderColor: Colors.red).actionLoaderColor, Colors.red);
      expect(actions.copyWith(actionLoadingWidget: loadingWidget).actionLoadingWidget, loadingWidget);
      expect(actions.copyWith(throttleDuration: Duration.zero).throttleDuration, Duration.zero);

      expect(actions.copyWith(label: 'New').label, 'New');
      expect(actions.copyWith(child: widgetChild).child, widgetChild);
      expect(actions.copyWith(closeOnAction: false).closeOnAction, isFalse);
      expect(actions.copyWith(onPressed: dummyPressed).onPressed, dummyPressed);
      expect(actions.copyWith(builder: dummyBuilder).builder, dummyBuilder);
      expect(actions.copyWith(maxActionLines: 3).maxActionLines, 3);
      expect(actions.copyWith(actionOverflow: TextOverflow.clip).actionOverflow, TextOverflow.clip);

      final FluentBarActions<void> modified = actions.copyWith(
        label: 'New',
        child: widgetChild,
        closeOnAction: false,
        onPressed: dummyPressed,
        builder: dummyBuilder,
        actionOverflow: TextOverflow.clip,
        maxActionLines: 2,
      );

      expect(modified.label, 'New');
      expect(modified.child, widgetChild);
      expect(modified.closeOnAction, isFalse);
      expect(modified.onPressed, dummyPressed);
      expect(modified.builder, dummyBuilder);
      expect(modified.actionOverflow, TextOverflow.clip);
      expect(modified.maxActionLines, 2);
    });

    test('should correctly implement equality and hashCode contract', () {
      const FluentBarActions<void> actions1 = FluentBarActions<void>(label: 'Action', closeOnAction: true, maxActionLines: 1);

      const FluentBarActions<void> actions2 = FluentBarActions<void>(label: 'Action', closeOnAction: true, maxActionLines: 1);

      const FluentBarActions<void> actionsDifferent = FluentBarActions<void>(label: 'Different', closeOnAction: false);

      expect(actions1, equals(actions2));
      expect(actions1.hashCode, equals(actions2.hashCode));
      expect(actions1 == actions1, isTrue);

      const Object otherObject = 'some string';
      expect(actions1 == otherObject, isFalse);

      expect(actions1 == actionsDifferent, isFalse);
      expect(actions1.hashCode == actionsDifferent.hashCode, isFalse);
    });
  });

  group('FluentBarAppearance Tests', () {
    test('should initialize with correct default values', () {
      const FluentBarAppearance<void> appearance = FluentBarAppearance<void>();

      expect(appearance.showIcon, isNull);
      expect(appearance.disableAnimations, isNull);
      expect(appearance.showTimeoutBar, isNull);
      expect(appearance.maxTitleLines, isNull);
      expect(appearance.maxMessageLines, isNull);
      expect(appearance.themeMode, isNull);
      expect(appearance.timeoutBarDirection, isNull);
      expect(appearance.progressTheme, isNull);
      expect(appearance.icon, isNull);
      expect(appearance.iconSize, isNull);
      expect(appearance.iconColor, isNull);
      expect(appearance.backgroundColor, isNull);
      expect(appearance.decoration, isNull);
      expect(appearance.constraints, isNull);
      expect(appearance.margin, isNull);
      expect(appearance.padding, isNull);
      expect(appearance.titleOverflow, isNull);
      expect(appearance.messageOverflow, isNull);
      expect(appearance.transitionDuration, isNull);
      expect(appearance.reverseTransitionDuration, isNull);
      expect(appearance.builder, isNull);
      expect(appearance.transitionBuilder, isNull);
    });

    test('should support copyWith for empty, partial and full updates', () {
      const FluentBarAppearance<void> appearance = FluentBarAppearance<void>();

      final FluentBarAppearance<void> copiedEmpty = appearance.copyWith();
      expect(copiedEmpty, equals(appearance));

      Widget dummyBuilder(BuildContext context, FluentBarEntry<void> entry) => const SizedBox();
      Widget dummyTransition(BuildContext context, Animation<double> animation, Widget child) => child;
      const SizedBox iconWidget = SizedBox();

      expect(appearance.copyWith(builder: dummyBuilder).builder, dummyBuilder);
      expect(appearance.copyWith(transitionBuilder: dummyTransition).transitionBuilder, dummyTransition);
      expect(appearance.copyWith(transitionDuration: const Duration(milliseconds: 100)).transitionDuration, const Duration(milliseconds: 100));
      expect(appearance.copyWith(reverseTransitionDuration: const Duration(milliseconds: 150)).reverseTransitionDuration, const Duration(milliseconds: 150));
      expect(appearance.copyWith(maxTitleLines: 3).maxTitleLines, 3);
      expect(appearance.copyWith(maxMessageLines: 4).maxMessageLines, 4);
      expect(appearance.copyWith(titleOverflow: TextOverflow.clip).titleOverflow, TextOverflow.clip);
      expect(appearance.copyWith(messageOverflow: TextOverflow.clip).messageOverflow, TextOverflow.clip);
      expect(appearance.copyWith(showIcon: false).showIcon, isFalse);
      expect(appearance.copyWith(icon: iconWidget).icon, iconWidget);
      expect(appearance.copyWith(themeMode: FluentBarThemeMode.dark).themeMode, FluentBarThemeMode.dark);
      expect(appearance.copyWith(showTimeoutBar: true).showTimeoutBar, isTrue);

      final FluentBarAppearance<void> modified = appearance.copyWith(
        builder: dummyBuilder,
        transitionBuilder: dummyTransition,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        maxTitleLines: 2,
        maxMessageLines: 5,
        titleOverflow: TextOverflow.fade,
        messageOverflow: TextOverflow.fade,
        showIcon: false,
        icon: iconWidget,
        themeMode: FluentBarThemeMode.dark,
        showTimeoutBar: true,
      );

      expect(modified.builder, dummyBuilder);
      expect(modified.transitionBuilder, dummyTransition);
      expect(modified.transitionDuration, const Duration(milliseconds: 300));
      expect(modified.reverseTransitionDuration, const Duration(milliseconds: 200));
      expect(modified.maxTitleLines, 2);
      expect(modified.maxMessageLines, 5);
      expect(modified.titleOverflow, TextOverflow.fade);
      expect(modified.messageOverflow, TextOverflow.fade);
      expect(modified.showIcon, isFalse);
      expect(modified.icon, iconWidget);
      expect(modified.themeMode, FluentBarThemeMode.dark);
      expect(modified.showTimeoutBar, isTrue);
    });

    test('should correctly implement equality and hashCode contract', () {
      const FluentBarAppearance<dynamic> appearance1 = FluentBarAppearance<dynamic>(maxTitleLines: 2, showIcon: true, themeMode: FluentBarThemeMode.dark);

      const FluentBarAppearance<dynamic> appearance2 = FluentBarAppearance<dynamic>(maxTitleLines: 2, showIcon: true, themeMode: FluentBarThemeMode.dark);

      const FluentBarAppearance<dynamic> appearanceDifferent = FluentBarAppearance<dynamic>(maxTitleLines: 5);

      expect(appearance1, equals(appearance2));
      expect(appearance1.hashCode, equals(appearance2.hashCode));

      expect(appearance1 == appearance1, isTrue);

      const Object otherObject = 'some string';
      expect(appearance1 == otherObject, isFalse);

      expect(appearance1 == appearanceDifferent, isFalse);
      expect(appearance1.hashCode == appearanceDifferent.hashCode, isFalse);
    });
  });

  group('FluentBarBehavior Tests', () {
    test('should initialize with correct default values', () {
      const FluentBarBehavior behavior = FluentBarBehavior();

      expect(behavior.isForce, isFalse);
      expect(behavior.isSwipeEnabled, isNull);
      expect(behavior.useSafeArea, isNull);
      expect(behavior.priority, isNull);
      expect(behavior.position, isNull);
      expect(behavior.dismissDirection, isNull);
      expect(behavior.duplicatePolicy, isNull);
      expect(behavior.timeoutUpdateInterval, isNull);
      expect(behavior.haptic, isNull);
    });

    test('should support copyWith for partial, empty and full updates', () {
      const FluentBarBehavior behavior = FluentBarBehavior();

      final FluentBarBehavior copiedEmpty = behavior.copyWith();
      expect(copiedEmpty, equals(behavior));

      expect(behavior.copyWith(isForce: true).isForce, isTrue);
      expect(behavior.copyWith(isSwipeEnabled: false).isSwipeEnabled, isFalse);
      expect(behavior.copyWith(useSafeArea: true).useSafeArea, isTrue);
      expect(behavior.copyWith(priority: FluentBarPriority.high).priority, FluentBarPriority.high);
      expect(behavior.copyWith(position: FluentBarPosition.bottom).position, FluentBarPosition.bottom);
      expect(behavior.copyWith(dismissDirection: DismissDirection.down).dismissDirection, DismissDirection.down);
      expect(behavior.copyWith(duplicatePolicy: FluentBarDuplicatePolicy.ignore).duplicatePolicy, FluentBarDuplicatePolicy.ignore);
      expect(behavior.copyWith(timeoutUpdateInterval: FluentBarUpdateRate.fps60).timeoutUpdateInterval, FluentBarUpdateRate.fps60);
      expect(behavior.copyWith(haptic: FluentBarHapticType.heavy).haptic, FluentBarHapticType.heavy);

      final FluentBarBehavior modified = behavior.copyWith(
        isForce: true,
        isSwipeEnabled: false,
        useSafeArea: false,
        priority: FluentBarPriority.high,
        position: FluentBarPosition.bottom,
        dismissDirection: DismissDirection.down,
        duplicatePolicy: FluentBarDuplicatePolicy.updateAndResetTimer,
        timeoutUpdateInterval: FluentBarUpdateRate.fps120,
        haptic: FluentBarHapticType.medium,
      );

      expect(modified.isForce, isTrue);
      expect(modified.isSwipeEnabled, isFalse);
      expect(modified.useSafeArea, isFalse);
      expect(modified.priority, FluentBarPriority.high);
      expect(modified.position, FluentBarPosition.bottom);
      expect(modified.dismissDirection, DismissDirection.down);
      expect(modified.duplicatePolicy, FluentBarDuplicatePolicy.updateAndResetTimer);
      expect(modified.timeoutUpdateInterval, FluentBarUpdateRate.fps120);
      expect(modified.haptic, FluentBarHapticType.medium);
    });

    test('should correctly implement equality and hashCode contract', () {
      const FluentBarBehavior behavior1 = FluentBarBehavior(
        priority: FluentBarPriority.high,
        isForce: true,
        position: FluentBarPosition.bottom,
        isSwipeEnabled: false,
        useSafeArea: true,
        haptic: FluentBarHapticType.light,
      );

      const FluentBarBehavior behavior2 = FluentBarBehavior(
        priority: FluentBarPriority.high,
        isForce: true,
        position: FluentBarPosition.bottom,
        isSwipeEnabled: false,
        useSafeArea: true,
        haptic: FluentBarHapticType.light,
      );

      const FluentBarBehavior behaviorDifferent = FluentBarBehavior(priority: FluentBarPriority.low);

      expect(behavior1, equals(behavior2));
      expect(behavior1.hashCode, equals(behavior2.hashCode));

      expect(behavior1 == behavior1, isTrue);

      const Object otherObject = 'some string';
      expect(behavior1 == otherObject, isFalse);

      expect(behavior1 == behaviorDifferent, isFalse);
      expect(behavior1.hashCode == behaviorDifferent.hashCode, isFalse);
    });
  });

  group('FluentBarCallbacks Tests', () {
    test('should initialize with correct default values', () {
      const FluentBarCallbacks<String> callbacks = FluentBarCallbacks<String>();

      expect(callbacks.haptic, isNull);
      expect(callbacks.progressCompletedHaptic, isNull);
      expect(callbacks.onShow, isNull);
      expect(callbacks.onTap, isNull);
      expect(callbacks.onDismiss, isNull);
      expect(callbacks.onProgressCompleted, isNull);
      expect(callbacks.onProgressCanceled, isNull);
    });

    test('should support copyWith for empty, partial and full updates', () {
      const FluentBarCallbacks<String> callbacks = FluentBarCallbacks<String>();

      final FluentBarCallbacks<String> copiedEmpty = callbacks.copyWith();
      expect(copiedEmpty.haptic, isNull);
      expect(copiedEmpty.progressCompletedHaptic, isNull);
      expect(copiedEmpty.onShow, isNull);
      expect(copiedEmpty.onTap, isNull);
      expect(copiedEmpty.onDismiss, isNull);
      expect(copiedEmpty.onProgressCompleted, isNull);
      expect(copiedEmpty.onProgressCanceled, isNull);

      FutureOr<void> dummyHaptic() {}
      FutureOr<void> dummyProgressHaptic() {}
      void dummyShow(FluentBarItem<String> item) {}
      void dummyTap(String? payload) {}
      void dummyDismiss(FluentBarItem<String> item, FluentBarMetrics metrics) {}
      void dummyProgressCompleted(FluentBarItem<String> item) {}
      void dummyProgressCanceled(FluentBarItem<String> item) {}

      expect(callbacks.copyWith(haptic: dummyHaptic).haptic, dummyHaptic);
      expect(callbacks.copyWith(progressCompletedHaptic: dummyProgressHaptic).progressCompletedHaptic, dummyProgressHaptic);
      expect(callbacks.copyWith(onShow: dummyShow).onShow, dummyShow);
      expect(callbacks.copyWith(onTap: dummyTap).onTap, dummyTap);
      expect(callbacks.copyWith(onDismiss: dummyDismiss).onDismiss, dummyDismiss);
      expect(callbacks.copyWith(onProgressCompleted: dummyProgressCompleted).onProgressCompleted, dummyProgressCompleted);
      expect(callbacks.copyWith(onProgressCanceled: dummyProgressCanceled).onProgressCanceled, dummyProgressCanceled);

      final FluentBarCallbacks<String> modified = callbacks.copyWith(
        haptic: dummyHaptic,
        progressCompletedHaptic: dummyProgressHaptic,
        onShow: dummyShow,
        onTap: dummyTap,
        onDismiss: dummyDismiss,
        onProgressCompleted: dummyProgressCompleted,
        onProgressCanceled: dummyProgressCanceled,
      );

      expect(modified.haptic, dummyHaptic);
      expect(modified.progressCompletedHaptic, dummyProgressHaptic);
      expect(modified.onShow, dummyShow);
      expect(modified.onTap, dummyTap);
      expect(modified.onDismiss, dummyDismiss);
      expect(modified.onProgressCompleted, dummyProgressCompleted);
      expect(modified.onProgressCanceled, dummyProgressCanceled);
    });
  });
}
