import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBar Resolutions & Extensions Tests', () {
    FluentBarEntry<void> createItem({
      FluentBarBehavior? behavior,
      FluentBarAppearance<void>? appearance,
      Duration? duration,
      bool? isPersistent,
      FluentBarType type = FluentBarType.info,
      FluentBarProgressValue? progressState,
      FluentBarCallbacks<void>? callbacks,
    }) {
      return FluentBarEntry<void>(
        item: FluentBarItem<void>(
          id: 'test_id',
          message: 'Test Message',
          type: type,
          behavior: behavior ?? const FluentBarBehavior(),
          appearance: appearance ?? const FluentBarAppearance<void>(),
          duration: duration,
          isPersistent: isPersistent,
          progressState: progressState,
          callbacks: callbacks,
        ),
      );
    }

    test('FluentBarEntryExtensionX returns internalController and currentItem', () {
      final FluentBarEntry<void> entry = createItem();
      expect(entry.internalController, isNotNull);
      expect(entry.currentItem, isNotNull);
      expect(entry.currentItem.message, 'Test Message');
    });

    test('resolveIsSwipeEnabled respects behavior -> type -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultIsSwipeEnabled: true);

      final FluentBarEntry<void> item1 = createItem(behavior: const FluentBarBehavior(isSwipeEnabled: false));
      expect(item1.resolveIsSwipeEnabled(config), isFalse);

      final FluentBarEntry<void> item2 = createItem(type: FluentBarType.info);
      expect(item2.resolveIsSwipeEnabled(config), isTrue);
    });

    test('resolveUseSafeArea respects behavior -> config priority', () {
      const FluentBarConfig config1 = FluentBarConfig(defaultUseSafeArea: true);
      const FluentBarConfig config2 = FluentBarConfig(defaultUseSafeArea: false);

      final FluentBarEntry<void> item = createItem(behavior: const FluentBarBehavior(useSafeArea: false));
      expect(item.resolveUseSafeArea(config1), isFalse);
      expect(item.resolveUseSafeArea(config2), isFalse);

      final FluentBarEntry<void> itemDefault = createItem();
      expect(itemDefault.resolveUseSafeArea(config1), isTrue);
      expect(itemDefault.resolveUseSafeArea(config2), isFalse);
    });

    test('resolvePosition respects behavior -> type -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultPosition: FluentBarPosition.bottom);

      final FluentBarEntry<void> item = createItem(behavior: const FluentBarBehavior(position: FluentBarPosition.top));
      expect(item.resolvePosition(config), FluentBarPosition.top);

      final FluentBarEntry<void> itemConfigFallback = createItem();
      expect(itemConfigFallback.resolvePosition(config), FluentBarPosition.bottom);
    });

    test('resolveDismissDirection respects behavior -> type -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultDismissDirection: DismissDirection.up);

      final FluentBarEntry<void> item = createItem(behavior: const FluentBarBehavior(dismissDirection: DismissDirection.down));
      expect(item.resolveDismissDirection(config), DismissDirection.down);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveDismissDirection(config), DismissDirection.up);
    });

    test('resolveDuplicatePolicy respects behavior -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultDuplicatePolicy: FluentBarDuplicatePolicy.ignore);

      final FluentBarEntry<void> item = createItem(behavior: const FluentBarBehavior(duplicatePolicy: FluentBarDuplicatePolicy.update));
      expect(item.resolveDuplicatePolicy(config), FluentBarDuplicatePolicy.update);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveDuplicatePolicy(config), FluentBarDuplicatePolicy.ignore);
    });

    test('resolveThemeMode respects appearance -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultThemeMode: FluentBarThemeMode.dark);

      final FluentBarEntry<void> item = createItem(appearance: const FluentBarAppearance<void>(themeMode: FluentBarThemeMode.light));
      expect(item.resolveThemeMode(config), FluentBarThemeMode.light);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveThemeMode(config), FluentBarThemeMode.dark);
    });

    test('resolveShowProgressBar respects appearance -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultShowTimeoutBar: true);

      final FluentBarEntry<void> item = createItem(appearance: const FluentBarAppearance<void>(showTimeoutBar: false));
      expect(item.resolveShowTimeoutBar(config), isFalse);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveShowTimeoutBar(config), isTrue);
    });

    test('resolveShowIcon checks both appearance and config.showIcons flag', () {
      const FluentBarConfig configShow = FluentBarConfig(defaultShowIcons: true);
      const FluentBarConfig configHide = FluentBarConfig(defaultShowIcons: false);

      final FluentBarEntry<void> itemShow = createItem(appearance: const FluentBarAppearance<void>(showIcon: true));
      expect(itemShow.resolveShowIcon(configShow), isTrue);
      expect(itemShow.resolveShowIcon(configHide), isTrue);

      final FluentBarEntry<void> itemHide = createItem(appearance: const FluentBarAppearance<void>(showIcon: false));
      expect(itemHide.resolveShowIcon(configShow), isFalse);
    });

    test('resolveDisableAnimations, resolveTimeoutBarDirection, resolveProgressTheme respect appearance priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultDisableAnimations: false, defaultTimeoutBarDirection: FluentBarTimeoutBarDirection.forward);

      final FluentBarEntry<void> itemCustom = createItem(
        appearance: const FluentBarAppearance<void>(
          disableAnimations: true,
          timeoutBarDirection: FluentBarTimeoutBarDirection.forward,
          progressTheme: FluentBarProgressTheme(successIconColor: Colors.red),
        ),
      );

      expect(itemCustom.resolveDisableAnimations(config), isTrue);
      expect(itemCustom.resolveTimeoutBarDirection(config), FluentBarTimeoutBarDirection.forward);
      expect(itemCustom.resolveProgressTheme(config).successIconColor, Colors.red);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveDisableAnimations(config), isFalse);
      expect(itemFallback.resolveTimeoutBarDirection(config), FluentBarTimeoutBarDirection.forward);
    });

    test('resolveTransitionDuration and reverse transition handle fallbacks', () {
      const Duration customDuration = Duration(milliseconds: 500);
      const Duration reverseCustom = Duration(milliseconds: 600);
      const FluentBarConfig config = FluentBarConfig(defaultTransitionDuration: Duration(milliseconds: 300), defaultReverseTransitionDuration: Duration(milliseconds: 400));

      final FluentBarEntry<void> item = createItem(
        appearance: const FluentBarAppearance<void>(transitionDuration: customDuration, reverseTransitionDuration: reverseCustom),
      );
      expect(item.resolveTransitionDuration(config), customDuration);
      expect(item.resolveReverseTransitionDuration(config), reverseCustom);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveTransitionDuration(config), const Duration(milliseconds: 300));
      expect(itemFallback.resolveReverseTransitionDuration(config), const Duration(milliseconds: 400));
    });

    test('resolveDuration and effective duration handle persistence correctly', () {
      const FluentBarConfig config = FluentBarConfig();

      final FluentBarEntry<void> item = createItem(duration: const Duration(seconds: 2));
      expect(item.resolveDuration(config), const Duration(seconds: 2));
      expect(item.resolveIsPersistent(config), isFalse);
      expect(item.resolveEffectiveDuration(config), const Duration(seconds: 2));

      final FluentBarEntry<void> persistentItem = createItem(duration: const Duration(seconds: 2), isPersistent: true);
      expect(persistentItem.resolveIsPersistent(config), isTrue);
      expect(persistentItem.resolveEffectiveDuration(config), isNull);

      final FluentBarEntry<void> progressItem = createItem(duration: const Duration(seconds: 2), progressState: const FluentBarProgressValue(0.5));
      expect(progressItem.resolveIsPersistent(config), isTrue);
      expect(progressItem.resolveEffectiveDuration(config), isNull);
    });

    test('resolvePriority, resolveHaptic and callbacks fallback to type defaults', () {
      const FluentBarConfig config = FluentBarConfig();
      Future<void> customCb() async {}

      final FluentBarEntry<void> item = createItem(
        type: FluentBarType.error,
        callbacks: FluentBarCallbacks<void>(haptic: customCb),
      );

      expect(item.resolvePriority(config), FluentBarType.error.priority);
      expect(item.resolveHaptic(config), FluentBarType.error.haptic);
      expect(item.resolveHapticCallback(config), customCb);
    });

    testWidgets('resolveMaxTitleLines, overflows, constraints, and dimensions respect appearance -> theme priority', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final FluentBarTheme theme = FluentBarTheme.modern.copyWith(
        maxTitleLines: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 1,
        maxMessageLines: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 2,
        titleOverflow: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => TextOverflow.ellipsis,
        messageOverflow: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => TextOverflow.clip,
        iconSize: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => 24.0,
        constraints: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => const BoxConstraints(maxWidth: 300),
        margin: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => const EdgeInsets.all(8),
        padding: (BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) => const EdgeInsets.all(16),
      );

      const FluentBarConfig config = FluentBarConfig();
      const FluentBarThemeMode themeMode = FluentBarThemeMode.light;

      final FluentBarEntry<void> item = createItem(
        appearance: const FluentBarAppearance<void>(
          maxTitleLines: 2,
          maxMessageLines: 3,
          titleOverflow: TextOverflow.fade,
          messageOverflow: TextOverflow.visible,
          iconSize: 32.0,
          constraints: BoxConstraints(maxWidth: 400),
          margin: EdgeInsets.all(12),
          padding: EdgeInsets.all(20),
        ),
      );

      expect(item.resolveMaxTitleLines(capturedContext, theme, themeMode, config), 2);
      expect(item.resolveMaxMessageLines(capturedContext, theme, themeMode, config), 3);
      expect(item.resolveTitleOverflow(capturedContext, theme, themeMode, config), TextOverflow.fade);
      expect(item.resolveMessageOverflow(capturedContext, theme, themeMode, config), TextOverflow.visible);
      expect(item.resolveIconSize(capturedContext, theme, themeMode, config), 32.0);
      expect(item.resolveConstraints(capturedContext, theme, themeMode, config).maxWidth, 400);
      expect(item.resolveMargin(capturedContext, theme, themeMode, config), const EdgeInsets.all(12));
      expect(item.resolvePadding(capturedContext, theme, themeMode, config), const EdgeInsets.all(20));

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveMaxTitleLines(capturedContext, theme, themeMode, config), 1);
      expect(itemFallback.resolveMaxMessageLines(capturedContext, theme, themeMode, config), 2);
      expect(itemFallback.resolveTitleOverflow(capturedContext, theme, themeMode, config), TextOverflow.ellipsis);
      expect(itemFallback.resolveMessageOverflow(capturedContext, theme, themeMode, config), TextOverflow.clip);
      expect(itemFallback.resolveIconSize(capturedContext, theme, themeMode, config), 24.0);
      expect(itemFallback.resolveConstraints(capturedContext, theme, themeMode, config).maxWidth, 300);
    });

    test('Builder resolvers override null defaults correctly', () {
      const FluentBarConfig config = FluentBarConfig();
      Widget customBuilder(BuildContext c, FluentBarEntry<dynamic> e) => const SizedBox();
      Widget progressBuilder(BuildContext c, ValueListenable<FluentBarProgressState?> n) => const SizedBox();
      Widget transitionBuilder(BuildContext c, Animation<double> a, Widget child) => const SizedBox();
      Widget positionBuilder(BuildContext c, Widget child) => const SizedBox();

      final FluentBarEntry<void> item = createItem(
        appearance: FluentBarAppearance<void>(
          builder: customBuilder,
          transitionBuilder: transitionBuilder,
          progressTheme: FluentBarProgressTheme(progressBuilder: progressBuilder),
        ),
        behavior: FluentBarBehavior(positionBuilder: positionBuilder),
      );

      expect(item.resolveBuilder(config), isNotNull);
      expect(item.resolveProgressBuilder(config), isNotNull);
      expect(item.resolveTransitionBuilder(config), isNotNull);
      expect(item.resolvePositionBuilder(config), isNotNull);

      final FluentBarEntry<void> itemFallback = createItem();
      expect(itemFallback.resolveBuilder(config), isNull);
      expect(itemFallback.resolveProgressBuilder(config), isNull);
      expect(itemFallback.resolveTransitionBuilder(config), isNull);
      expect(itemFallback.resolvePositionBuilder(config), isNull);
    });

    testWidgets('Context dependent resolvers: resolveDecoration, resolveBorderRadius, resolveIconColor', (WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );

      const FluentBarConfig config = FluentBarConfig();
      const FluentBarTheme theme = FluentBarTheme.modern;
      const FluentBarThemeMode mode = FluentBarThemeMode.light;

      final FluentBarEntry<void> itemWithDecoration = createItem(
        appearance: const FluentBarAppearance<void>(
          backgroundColor: Colors.red,
          iconColor: Colors.blue,
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );

      final BoxDecoration decoration = itemWithDecoration.resolveDecoration(ctx, theme, mode, config);
      expect(decoration.color, Colors.green);
      expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(10)));
      expect(itemWithDecoration.resolveBorderRadius(ctx, theme, mode, config), const BorderRadius.all(Radius.circular(10)));
      expect(itemWithDecoration.resolveIconColor(ctx, theme, mode, config), Colors.blue);

      final FluentBarEntry<void> itemWithBg = createItem(appearance: const FluentBarAppearance<void>(backgroundColor: Colors.red));
      final BoxDecoration decorationBg = itemWithBg.resolveDecoration(ctx, theme, mode, config);
      expect(decorationBg.color, Colors.red);
    });

    test('resolveCustomEffectBuilder respects appearance -> type priority', () {
      const FluentBarConfig config = FluentBarConfig();

      Widget customEffectBuilder(BuildContext c, AnimationController controller, Widget child) => const SizedBox();

      final FluentBarType typeWithEffect = FluentBarType.info.copyWith(customEffectBuilder: (BuildContext c, AnimationController controller, Widget child) => const Text('Type Effect'));

      final FluentBarEntry<void> itemWithAppearance = createItem(appearance: FluentBarAppearance<void>(customEffectBuilder: customEffectBuilder));
      expect(itemWithAppearance.resolveCustomEffectBuilder(config), isNotNull);

      final FluentBarEntry<void> itemWithTypeFallback = createItem(type: typeWithEffect);
      expect(itemWithTypeFallback.resolveCustomEffectBuilder(config), isNotNull);

      final FluentBarEntry<void> itemEmpty = createItem();
      expect(itemEmpty.resolveCustomEffectBuilder(config), isNull);
    });

    test('resolveEntranceAnimation respects appearance -> type -> config priority', () {
      const FluentBarConfig config = FluentBarConfig(defaultEntranceAnimation: FluentBarEntranceAnimation.fade);

      final FluentBarType typeWithAnimation = FluentBarType.info.copyWith(entranceAnimation: FluentBarEntranceAnimation.scale);

      final FluentBarEntry<void> itemAppearance = createItem(appearance: const FluentBarAppearance<void>(entranceAnimation: FluentBarEntranceAnimation.slide));
      expect(itemAppearance.resolveEntranceAnimation(config), FluentBarEntranceAnimation.slide);

      final FluentBarEntry<void> itemType = createItem(type: typeWithAnimation);
      expect(itemType.resolveEntranceAnimation(config), FluentBarEntranceAnimation.scale);

      final FluentBarEntry<void> itemDefault = createItem();
      expect(itemDefault.resolveEntranceAnimation(config), FluentBarEntranceAnimation.fade);
    });
  });

  group('FluentBarItemResolution & FluentBarItemDuplicateX & Extensions Tests', () {
    test('isDuplicateOf compares correctly based on IDs, config, and equality', () {
      final FluentBarItem<void> item1 = FluentBarItem<void>(id: '1', message: 'A', type: FluentBarType.info);
      final FluentBarItem<void> item2 = FluentBarItem<void>(id: '1', message: 'B', type: FluentBarType.info);
      final FluentBarItem<void> item3 = FluentBarItem<void>(id: '2', message: 'C', type: FluentBarType.info);

      final FluentBarItem<void> itemNoId1 = FluentBarItem<void>(message: 'A', type: FluentBarType.info);
      final FluentBarItem<void> itemNoId2 = FluentBarItem<void>(message: 'B', type: FluentBarType.info);

      final FluentBarItem<void> itemNoId3 = FluentBarItem<void>(message: 'A', type: FluentBarType.error);

      const FluentBarConfig configStandard = FluentBarConfig();
      final FluentBarConfig configCustom = FluentBarConfig(duplicateComparator: (FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => a.message == b.message);

      expect(item1.isDuplicateOf(item2, configStandard), isTrue);
      expect(item1.isDuplicateOf(item3, configStandard), isFalse);

      expect(itemNoId1.isDuplicateOf(itemNoId2, configStandard), isFalse);
      expect(itemNoId1.isDuplicateOf(itemNoId1, configStandard), isTrue);

      expect(item1.isDuplicateOf(item2, configCustom), isFalse);
      expect(itemNoId1.isDuplicateOf(itemNoId3, configCustom), isTrue);
    });

    test('FluentBarItemResolution methods resolve correctly directly on Item', () {
      Future<void> customCb() async {}
      final FluentBarItem<void> item = FluentBarItem<void>(
        message: 'Test',
        type: FluentBarType.info,
        behavior: const FluentBarBehavior(progressCompletedHaptic: FluentBarHapticType.light),
        callbacks: FluentBarCallbacks<void>(progressCompletedHaptic: customCb),
      );
      const FluentBarConfig config = FluentBarConfig();

      expect(item.resolvedType(config), FluentBarType.info);
      expect(item.resolveProgressCompletedHaptic(config), FluentBarHapticType.light);
      expect(item.resolveProgressCompletedHapticCallback(config), customCb);
    });

    test('SafeDurationExtension nonNegative returns correct limits', () {
      expect(const Duration(seconds: 1).nonNegative, const Duration(seconds: 1));
      expect(Duration.zero.nonNegative, Duration.zero);
      expect(const Duration(seconds: -1).nonNegative, Duration.zero);
    });
  });

  test('isDuplicateOf handles errors in custom comparator gracefully and triggers error handler', () {
    final FluentBarItem<void> item1 = FluentBarItem<void>(id: '1', message: 'A', type: FluentBarType.info);
    final FluentBarItem<void> item2 = FluentBarItem<void>(id: '2', message: 'B', type: FluentBarType.info);

    final FluentBarConfig configWithError = FluentBarConfig(
      duplicateComparator: (FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) {
        throw Exception('Comparator custom error');
      },
    );

    expect(item1.isDuplicateOf(item2, configWithError), isFalse);
  });
}
