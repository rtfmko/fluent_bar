import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarConfig', () {
    test('has sensible defaults', () {
      const FluentBarConfig config = FluentBarConfig();

      expect(config.enableMultiRegion, isTrue);
      expect(config.defaultShowIcons, isTrue);
      expect(config.defaultDisableAnimations, isFalse);
      expect(config.defaultUseSafeArea, isTrue);
      expect(config.defaultShowTimeoutBar, isFalse);
      expect(config.defaultIsSwipeEnabled, isTrue);
      expect(config.defaultDismissOnTap, isTrue);
      expect(config.maxQueueLength, 15);
      expect(config.defaultTransitionDuration, const Duration(milliseconds: 300));
      expect(config.defaultReverseTransitionDuration, const Duration(milliseconds: 250));
      expect(config.defaultPosition, FluentBarPosition.top);
      expect(config.defaultDismissDirection, isNull);
      expect(config.defaultTimeoutBarPosition, FluentBarTimeoutBarPosition.bottom);
      expect(config.defaultQueueStrategy, isA<SmartQueueStrategy>());
      expect(config.defaultRelocationStrategy, FluentBarRelocationStrategy.queueNext);
      expect(config.defaultTimeoutUpdateInterval, FluentBarUpdateRate.medium);
      expect(config.themeStyle, FluentBarThemeStyle.auto);
      expect(config.defaultDuplicatePolicy, FluentBarDuplicatePolicy.update);
      expect(config.defaultTheme, isNull);
      expect(config.defaultThemeMode, FluentBarThemeMode.system);
      expect(config.defaultTimeoutBarDirection, FluentBarTimeoutBarDirection.forward);
      expect(config.defaultEntranceAnimation, FluentBarEntranceAnimation.slide);
      expect(config.progressTheme, const FluentBarProgressTheme());
      expect(config.typeOverrides, isNull);
      expect(config.duplicateComparator, isNull);
      expect(config.defaultPositionBuilder, isNull);
      expect(config.defaultTransitionBuilder, isNull);
      expect(config.defaultBuilder, isNull);
    });

    test('maxQueueLength is clamped to 1..100', () {
      expect(const FluentBarConfig(maxQueueLength: 0).maxQueueLength, 1);
      expect(const FluentBarConfig(maxQueueLength: -5).maxQueueLength, 1);
      expect(const FluentBarConfig(maxQueueLength: 42).maxQueueLength, 42);
      expect(const FluentBarConfig(maxQueueLength: 1000).maxQueueLength, 100);
      expect(const FluentBarConfig().copyWith(maxQueueLength: 1000).maxQueueLength, 100);
    });

    test('copyWith overrides every field that is passed', () {
      const FifoQueueStrategy queue = FifoQueueStrategy();
      const FluentBarProgressTheme progressTheme = FluentBarProgressTheme(thickness: 9);
      const Map<FluentBarType, FluentBarType> overrides = <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.success};
      bool comparator(FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => true;
      Widget position(BuildContext context, Widget child) => child;
      Widget transition(BuildContext context, Animation<double> animation, Widget child) => child;
      Widget builder(BuildContext context, FluentBarEntry<dynamic> entry) => const SizedBox();

      final FluentBarConfig modified = const FluentBarConfig().copyWith(
        enableMultiRegion: false,
        defaultShowIcons: false,
        defaultDisableAnimations: true,
        defaultUseSafeArea: false,
        defaultShowTimeoutBar: true,
        defaultIsSwipeEnabled: false,
        defaultDismissOnTap: false,
        maxQueueLength: 4,
        defaultTransitionDuration: const Duration(milliseconds: 500),
        defaultReverseTransitionDuration: const Duration(milliseconds: 400),
        defaultPosition: FluentBarPosition.bottom,
        defaultDismissDirection: DismissDirection.down,
        defaultTimeoutBarPosition: FluentBarTimeoutBarPosition.top,
        defaultQueueStrategy: queue,
        defaultRelocationStrategy: FluentBarRelocationStrategy.ignore,
        defaultTimeoutUpdateInterval: FluentBarUpdateRate.fps60,
        themeStyle: FluentBarThemeStyle.cupertino,
        defaultDuplicatePolicy: FluentBarDuplicatePolicy.ignore,
        defaultTheme: FluentBarTheme.minimal,
        defaultThemeMode: FluentBarThemeMode.dark,
        defaultTimeoutBarDirection: FluentBarTimeoutBarDirection.reverse,
        defaultEntranceAnimation: FluentBarEntranceAnimation.flip3d,
        progressTheme: progressTheme,
        typeOverrides: overrides,
        duplicateComparator: comparator,
        defaultPositionBuilder: position,
        defaultTransitionBuilder: transition,
        defaultBuilder: builder,
      );

      expect(modified.enableMultiRegion, isFalse);
      expect(modified.defaultShowIcons, isFalse);
      expect(modified.defaultDisableAnimations, isTrue);
      expect(modified.defaultUseSafeArea, isFalse);
      expect(modified.defaultShowTimeoutBar, isTrue);
      expect(modified.defaultIsSwipeEnabled, isFalse);
      expect(modified.defaultDismissOnTap, isFalse);
      expect(modified.maxQueueLength, 4);
      expect(modified.defaultTransitionDuration, const Duration(milliseconds: 500));
      expect(modified.defaultReverseTransitionDuration, const Duration(milliseconds: 400));
      expect(modified.defaultPosition, FluentBarPosition.bottom);
      expect(modified.defaultDismissDirection, DismissDirection.down);
      expect(modified.defaultTimeoutBarPosition, FluentBarTimeoutBarPosition.top);
      expect(modified.defaultQueueStrategy, same(queue));
      expect(modified.defaultRelocationStrategy, FluentBarRelocationStrategy.ignore);
      expect(modified.defaultTimeoutUpdateInterval, FluentBarUpdateRate.fps60);
      expect(modified.themeStyle, FluentBarThemeStyle.cupertino);
      expect(modified.defaultDuplicatePolicy, FluentBarDuplicatePolicy.ignore);
      expect(modified.defaultTheme, FluentBarTheme.minimal);

      final FluentBarConfig withOverrides = modified.copyWith(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.success});
      expect(withOverrides.copyWith().defaultTheme, FluentBarTheme.minimal);
      expect(withOverrides.copyWith(clearDefaultTheme: true).defaultTheme, isNull);
      expect(withOverrides.copyWith().typeOverrides, isNotNull);
      expect(withOverrides.copyWith(clearTypeOverrides: true).typeOverrides, isNull);

      final FluentBarConfig withFunctions = FluentBarConfig(
        duplicateComparator: (FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => true,
        defaultPositionBuilder: (BuildContext context, Widget child) => child,
        defaultTransitionBuilder: (BuildContext context, Animation<double> animation, Widget child) => child,
        defaultBuilder: (BuildContext context, FluentBarEntry<dynamic> entry) => const SizedBox(),
      );
      final FluentBarConfig kept = withFunctions.copyWith();
      expect(kept.duplicateComparator, isNotNull);
      expect(kept.defaultPositionBuilder, isNotNull);
      expect(kept.defaultTransitionBuilder, isNotNull);
      expect(kept.defaultBuilder, isNotNull);

      final FluentBarConfig cleared = withFunctions.copyWith(clearDuplicateComparator: true, clearDefaultPositionBuilder: true, clearDefaultTransitionBuilder: true, clearDefaultBuilder: true);
      expect(cleared.duplicateComparator, isNull);
      expect(cleared.defaultPositionBuilder, isNull);
      expect(cleared.defaultTransitionBuilder, isNull);
      expect(cleared.defaultBuilder, isNull);

      expect(withFunctions, cleared);
      expect(withFunctions.hasSameFunctionsAs(kept), isTrue);
      expect(withFunctions.hasSameFunctionsAs(cleared), isFalse);
      expect(cleared.hasSameFunctionsAs(const FluentBarConfig()), isTrue);

      FluentBarManager.instance.resetForTesting();
      int notifications = 0;
      void listener() => notifications++;
      FluentBar.configNotifier.addListener(listener);
      bool sameMessage(FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => a.message == b.message;
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(duplicateComparator: sameMessage));
      expect(notifications, 1);
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(duplicateComparator: sameMessage));
      expect(notifications, 1);
      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(clearDuplicateComparator: true));
      expect(notifications, 2);
      FluentBar.configNotifier.removeListener(listener);
      FluentBarManager.instance.resetForTesting();
      expect(modified.defaultThemeMode, FluentBarThemeMode.dark);
      expect(modified.defaultTimeoutBarDirection, FluentBarTimeoutBarDirection.reverse);
      expect(modified.defaultEntranceAnimation, FluentBarEntranceAnimation.flip3d);
      expect(modified.progressTheme, progressTheme);
      expect(modified.typeOverrides, overrides);
      expect(modified.duplicateComparator, comparator);
      expect(modified.defaultPositionBuilder, position);
      expect(modified.defaultTransitionBuilder, transition);
      expect(modified.defaultBuilder, builder);
    });

    test('copyWith without arguments keeps everything, including builders', () {
      Widget builder(BuildContext context, FluentBarEntry<dynamic> entry) => const SizedBox();
      final FluentBarConfig config = FluentBarConfig(maxQueueLength: 3, defaultBuilder: builder);
      final FluentBarConfig copied = config.copyWith();

      expect(copied, equals(config));
      expect(copied.defaultBuilder, builder);
    });

    test('resolveType applies typeOverrides', () {
      const FluentBarConfig config = FluentBarConfig(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.success});

      expect(config.resolveType(FluentBarType.info), FluentBarType.success);
      expect(config.resolveType(FluentBarType.warning), FluentBarType.warning);
      expect(const FluentBarConfig().resolveType(FluentBarType.info), FluentBarType.info);
    });

    test('equality compares values, including the content of typeOverrides', () {
      const FluentBarConfig a = FluentBarConfig(defaultShowTimeoutBar: true);
      const FluentBarConfig b = FluentBarConfig(defaultShowTimeoutBar: true);
      const FluentBarConfig different = FluentBarConfig();

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == different, isFalse);
      expect(a == ('some string' as Object), isFalse);

      const FluentBarConfig first = FluentBarConfig(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.success});
      const FluentBarConfig second = FluentBarConfig(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.success});
      const FluentBarConfig other = FluentBarConfig(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.error});

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
      expect(first == other, isFalse);
      expect(first == different, isFalse);
    });

    test('equality ignores callbacks and builders (closures cannot be compared by value)', () {
      final FluentBarConfig a = FluentBarConfig(defaultBuilder: (BuildContext context, FluentBarEntry<dynamic> entry) => const SizedBox());
      final FluentBarConfig b = FluentBarConfig(defaultBuilder: (BuildContext context, FluentBarEntry<dynamic> entry) => const SizedBox());

      expect(a, equals(b));
    });
  });
}
