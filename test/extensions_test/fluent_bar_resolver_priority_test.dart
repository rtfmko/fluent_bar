import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentBarEntry<void> entryOf({
    FluentBarType type = FluentBarType.info,
    FluentBarBehavior? behavior,
    FluentBarAppearance<void>? appearance,
    FluentBarCallbacks<void>? callbacks,
    Duration? duration,
    bool? isPersistent,
  }) => FluentBarEntry<void>(
    item: FluentBarItem<void>(message: 'Test', type: type, behavior: behavior, appearance: appearance, callbacks: callbacks, duration: duration, isPersistent: isPersistent),
  );

  void expectPriority<V>({
    required FluentBarEntry<void> localEntry,
    required FluentBarType type,
    required FluentBarConfig config,
    required V Function(FluentBarEntry<void> entry, FluentBarConfig config) resolve,
    required V local,
    required V fromType,
    required V global,
  }) {
    expect(resolve(localEntry, config), local, reason: 'local must win over type and config');
    expect(resolve(entryOf(type: type), config), fromType, reason: 'type must win over config');
    expect(resolve(entryOf(), config), global, reason: 'config is the last fallback');
  }

  group('local -> type -> config', () {
    test('isSwipeEnabled', () {
      final FluentBarType type = FluentBarType.info.copyWith(isSwipeEnabled: false);
      expectPriority<bool>(
        localEntry: entryOf(type: type, behavior: const FluentBarBehavior(isSwipeEnabled: true)),
        type: type,
        config: const FluentBarConfig(defaultIsSwipeEnabled: true),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveIsSwipeEnabled(c),
        local: true,
        fromType: false,
        global: true,
      );
    });

    test('dismissOnTap', () {
      final FluentBarType type = FluentBarType.info.copyWith(dismissOnTap: true);
      expectPriority<bool>(
        localEntry: entryOf(type: type, behavior: const FluentBarBehavior(dismissOnTap: false)),
        type: type,
        config: const FluentBarConfig(defaultDismissOnTap: false),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveDismissOnTap(c),
        local: false,
        fromType: true,
        global: false,
      );
    });

    test('useSafeArea', () {
      final FluentBarType type = FluentBarType.info.copyWith(useSafeArea: false);
      expectPriority<bool>(
        localEntry: entryOf(type: type, behavior: const FluentBarBehavior(useSafeArea: true)),
        type: type,
        config: const FluentBarConfig(defaultUseSafeArea: true),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveUseSafeArea(c),
        local: true,
        fromType: false,
        global: true,
      );
    });

    test('showTimeoutBar', () {
      final FluentBarType type = FluentBarType.info.copyWith(showTimeoutBar: true);
      expectPriority<bool>(
        localEntry: entryOf(type: type, appearance: const FluentBarAppearance<void>(showTimeoutBar: false)),
        type: type,
        config: const FluentBarConfig(defaultShowTimeoutBar: false),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveShowTimeoutBar(c),
        local: false,
        fromType: true,
        global: false,
      );
    });

    test('showIcon', () {
      final FluentBarType type = FluentBarType.info.copyWith(showIcon: false);
      expectPriority<bool>(
        localEntry: entryOf(type: type, appearance: const FluentBarAppearance<void>(showIcon: true)),
        type: type,
        config: const FluentBarConfig(defaultShowIcons: true),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveShowIcon(c),
        local: true,
        fromType: false,
        global: true,
      );
    });

    test('disableAnimations', () {
      final FluentBarType type = FluentBarType.info.copyWith(disableAnimations: true);
      expectPriority<bool>(
        localEntry: entryOf(type: type, appearance: const FluentBarAppearance<void>(disableAnimations: false)),
        type: type,
        config: const FluentBarConfig(defaultDisableAnimations: false),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveDisableAnimations(c),
        local: false,
        fromType: true,
        global: false,
      );
    });

    test('transitionDuration and reverseTransitionDuration', () {
      final FluentBarType type = FluentBarType.info.copyWith(transitionDuration: const Duration(milliseconds: 200), reverseTransitionDuration: const Duration(milliseconds: 210));
      final FluentBarEntry<void> local = entryOf(
        type: type,
        appearance: const FluentBarAppearance<void>(transitionDuration: Duration(milliseconds: 100), reverseTransitionDuration: Duration(milliseconds: 110)),
      );
      const FluentBarConfig config = FluentBarConfig(defaultTransitionDuration: Duration(milliseconds: 300), defaultReverseTransitionDuration: Duration(milliseconds: 310));

      expectPriority<Duration>(
        localEntry: local,
        type: type,
        config: config,
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveTransitionDuration(c),
        local: const Duration(milliseconds: 100),
        fromType: const Duration(milliseconds: 200),
        global: const Duration(milliseconds: 300),
      );
      expectPriority<Duration>(
        localEntry: local,
        type: type,
        config: config,
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveReverseTransitionDuration(c),
        local: const Duration(milliseconds: 110),
        fromType: const Duration(milliseconds: 210),
        global: const Duration(milliseconds: 310),
      );
    });

    test('position', () {
      final FluentBarType type = FluentBarType.info.copyWith(position: FluentBarPosition.left);
      expectPriority<FluentBarPosition>(
        localEntry: entryOf(
          type: type,
          behavior: const FluentBarBehavior(position: FluentBarPosition.center),
        ),
        type: type,
        config: const FluentBarConfig(defaultPosition: FluentBarPosition.bottom),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolvePosition(c),
        local: FluentBarPosition.center,
        fromType: FluentBarPosition.left,
        global: FluentBarPosition.bottom,
      );
    });

    test('dismissDirection, then derived from position when nothing is set', () {
      final FluentBarType type = FluentBarType.info.copyWith(dismissDirection: DismissDirection.startToEnd);
      expectPriority<DismissDirection>(
        localEntry: entryOf(
          type: type,
          behavior: const FluentBarBehavior(dismissDirection: DismissDirection.endToStart),
        ),
        type: type,
        config: const FluentBarConfig(defaultDismissDirection: DismissDirection.vertical),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveDismissDirection(c),
        local: DismissDirection.endToStart,
        fromType: DismissDirection.startToEnd,
        global: DismissDirection.vertical,
      );

      const FluentBarConfig empty = FluentBarConfig();
      expect(entryOf(behavior: const FluentBarBehavior(position: FluentBarPosition.top)).resolveDismissDirection(empty), DismissDirection.up);
      expect(entryOf(behavior: const FluentBarBehavior(position: FluentBarPosition.bottom)).resolveDismissDirection(empty), DismissDirection.down);
      expect(entryOf(behavior: const FluentBarBehavior(position: FluentBarPosition.center)).resolveDismissDirection(empty), DismissDirection.horizontal);
    });

    test('duplicatePolicy (entry and item resolvers agree)', () {
      final FluentBarType type = FluentBarType.info.copyWith(duplicatePolicy: FluentBarDuplicatePolicy.ignore);
      const FluentBarConfig config = FluentBarConfig(defaultDuplicatePolicy: FluentBarDuplicatePolicy.update);
      final FluentBarEntry<void> local = entryOf(
        type: type,
        behavior: const FluentBarBehavior(duplicatePolicy: FluentBarDuplicatePolicy.allow),
      );

      expectPriority<FluentBarDuplicatePolicy>(
        localEntry: local,
        type: type,
        config: config,
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveDuplicatePolicy(c),
        local: FluentBarDuplicatePolicy.allow,
        fromType: FluentBarDuplicatePolicy.ignore,
        global: FluentBarDuplicatePolicy.update,
      );
      expectPriority<FluentBarDuplicatePolicy>(
        localEntry: local,
        type: type,
        config: config,
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.currentItem.resolveDuplicatePolicy(c),
        local: FluentBarDuplicatePolicy.allow,
        fromType: FluentBarDuplicatePolicy.ignore,
        global: FluentBarDuplicatePolicy.update,
      );
    });

    test('relocationStrategy', () {
      final FluentBarType type = FluentBarType.info.copyWith(relocationStrategy: FluentBarRelocationStrategy.forceReplace);
      expectPriority<FluentBarRelocationStrategy>(
        localEntry: entryOf(
          type: type,
          behavior: const FluentBarBehavior(relocationStrategy: FluentBarRelocationStrategy.ignore),
        ),
        type: type,
        config: const FluentBarConfig(defaultRelocationStrategy: FluentBarRelocationStrategy.queueNext),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveRelocationStrategy(c),
        local: FluentBarRelocationStrategy.ignore,
        fromType: FluentBarRelocationStrategy.forceReplace,
        global: FluentBarRelocationStrategy.queueNext,
      );
    });

    test('timeoutBarDirection', () {
      final FluentBarType type = FluentBarType.info.copyWith(timeoutBarDirection: FluentBarTimeoutBarDirection.reverse);
      expectPriority<FluentBarTimeoutBarDirection>(
        localEntry: entryOf(
          type: type,
          appearance: const FluentBarAppearance<void>(timeoutBarDirection: FluentBarTimeoutBarDirection.forward),
        ),
        type: type,
        config: const FluentBarConfig(defaultTimeoutBarDirection: FluentBarTimeoutBarDirection.forward),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveTimeoutBarDirection(c),
        local: FluentBarTimeoutBarDirection.forward,
        fromType: FluentBarTimeoutBarDirection.reverse,
        global: FluentBarTimeoutBarDirection.forward,
      );
    });

    test('entranceAnimation', () {
      final FluentBarType type = FluentBarType.info.copyWith(entranceAnimation: FluentBarEntranceAnimation.scale);
      expectPriority<FluentBarEntranceAnimation>(
        localEntry: entryOf(
          type: type,
          appearance: const FluentBarAppearance<void>(entranceAnimation: FluentBarEntranceAnimation.elastic),
        ),
        type: type,
        config: const FluentBarConfig(defaultEntranceAnimation: FluentBarEntranceAnimation.fade),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveEntranceAnimation(c),
        local: FluentBarEntranceAnimation.elastic,
        fromType: FluentBarEntranceAnimation.scale,
        global: FluentBarEntranceAnimation.fade,
      );
    });

    test('progressTheme', () {
      const FluentBarProgressTheme localTheme = FluentBarProgressTheme(thickness: 1);
      const FluentBarProgressTheme typeTheme = FluentBarProgressTheme(thickness: 2);
      const FluentBarProgressTheme globalTheme = FluentBarProgressTheme(thickness: 3);
      final FluentBarType type = FluentBarType.info.copyWith(progressTheme: typeTheme);

      expectPriority<FluentBarProgressTheme>(
        localEntry: entryOf(
          type: type,
          appearance: const FluentBarAppearance<void>(progressTheme: localTheme),
        ),
        type: type,
        config: const FluentBarConfig(progressTheme: globalTheme),
        resolve: (FluentBarEntry<void> e, FluentBarConfig c) => e.resolveProgressTheme(c),
        local: localTheme,
        fromType: typeTheme,
        global: globalTheme,
      );
    });
  });

  group('local -> type (no global level)', () {
    const FluentBarConfig config = FluentBarConfig();

    test('priority, haptic, duration, isPersistent', () {
      final FluentBarType type = FluentBarType.info.copyWith(priority: FluentBarPriority.high, haptic: FluentBarHapticType.heavy, duration: const Duration(seconds: 9), isPersistent: true);

      final FluentBarEntry<void> local = entryOf(
        type: type,
        behavior: const FluentBarBehavior(priority: FluentBarPriority.low, haptic: FluentBarHapticType.light),
        duration: const Duration(seconds: 1),
        isPersistent: false,
      );
      expect(local.resolvePriority(config), FluentBarPriority.low);
      expect(local.resolveHaptic(config), FluentBarHapticType.light);
      expect(local.resolveDuration(config), const Duration(seconds: 1));
      expect(local.resolveIsPersistent(config), isFalse);
      expect(local.resolveEffectiveDuration(config), const Duration(seconds: 1));

      final FluentBarEntry<void> typed = entryOf(type: type);
      expect(typed.resolvePriority(config), FluentBarPriority.high);
      expect(typed.resolveHaptic(config), FluentBarHapticType.heavy);
      expect(typed.resolveDuration(config), const Duration(seconds: 9));
      expect(typed.resolveIsPersistent(config), isTrue);
      expect(typed.resolveEffectiveDuration(config), isNull);
    });

    test('negative durations are clamped to zero', () {
      final FluentBarEntry<void> entry = entryOf(
        duration: const Duration(seconds: -1),
        appearance: const FluentBarAppearance<void>(transitionDuration: Duration(milliseconds: -5)),
      );
      expect(entry.resolveDuration(config), Duration.zero);
      expect(entry.resolveTransitionDuration(config), Duration.zero);
    });

    test('haptic callback: local callback -> type callback, a custom haptic always beats the enum value', () {
      void localCallback() {}
      void typeCallback() {}
      final FluentBarType type = FluentBarType.info.copyWith(customHaptic: typeCallback);

      expect(
        entryOf(
          type: type,
          callbacks: FluentBarCallbacks<void>(haptic: localCallback),
        ).resolveHapticCallback(config),
        localCallback,
      );
      expect(
        entryOf(
          type: type,
          behavior: const FluentBarBehavior(haptic: FluentBarHapticType.light),
        ).resolveHapticCallback(config),
        typeCallback,
      );
      expect(entryOf(type: type).resolveHapticCallback(config), typeCallback);
      expect(entryOf().resolveHapticCallback(config), isNull);
    });

    test('progressCompleted haptic callback follows the same order', () {
      void localCallback() {}
      void typeCallback() {}
      final FluentBarType type = FluentBarType.info.copyWith(customProgressCompletedHaptic: typeCallback, progressCompletedHaptic: FluentBarHapticType.heavy);

      FluentBarItem<void> item({FluentBarBehavior? behavior, FluentBarCallbacks<void>? callbacks}) => FluentBarItem<void>(message: 'Test', type: type, behavior: behavior, callbacks: callbacks);

      expect(item(callbacks: FluentBarCallbacks<void>(progressCompletedHaptic: localCallback)).resolveProgressCompletedHapticCallback(config), localCallback);
      final FluentBarItem<void> localType = item(behavior: const FluentBarBehavior(progressCompletedHaptic: FluentBarHapticType.light));
      expect(localType.resolveProgressCompletedHapticCallback(config), typeCallback);
      expect(localType.resolveProgressCompletedHaptic(config), FluentBarHapticType.light);
      expect(item().resolveProgressCompletedHapticCallback(config), typeCallback);
      expect(item().resolveProgressCompletedHaptic(config), FluentBarHapticType.heavy);
    });
  });

  group('config.typeOverrides', () {
    test('overridden type is used by every resolver', () {
      final FluentBarConfig config = FluentBarConfig(
        defaultPosition: FluentBarPosition.top,
        typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: FluentBarType.info.copyWith(position: FluentBarPosition.bottom, duration: const Duration(seconds: 7))},
      );

      expect(entryOf().resolvePosition(config), FluentBarPosition.bottom);
      expect(entryOf().resolveDuration(config), const Duration(seconds: 7));
      expect(entryOf(type: FluentBarType.error).resolvePosition(config), FluentBarPosition.top);
      expect(entryOf(behavior: const FluentBarBehavior(position: FluentBarPosition.center)).resolvePosition(config), FluentBarPosition.center);
    });
  });

  group('builders', () {
    Future<BuildContext> pumpContext(WidgetTester tester) async {
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
      return context;
    }

    Widget localPosition(BuildContext c, Widget child) => const Text('local');
    Widget typePosition(BuildContext c, Widget child) => const Text('type');
    Widget globalPosition(BuildContext c, Widget child) => const Text('global');

    String? textOf(Widget? widget) => widget is Text ? widget.data : null;

    testWidgets('positionBuilder: local -> type -> config', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      final FluentBarType type = FluentBarType.info.copyWith(positionBuilder: typePosition);
      final FluentBarConfig config = FluentBarConfig(defaultPositionBuilder: globalPosition);
      const Widget child = SizedBox();

      final FluentBarEntry<void> local = entryOf(
        type: type,
        behavior: FluentBarBehavior(positionBuilder: localPosition),
      );
      expect(textOf(local.resolvePositionBuilder(config)!(context, child)), 'local');
      expect(textOf(entryOf(type: type).resolvePositionBuilder(config)!(context, child)), 'type');
      expect(textOf(entryOf().resolvePositionBuilder(config)!(context, child)), 'global');
    });

    testWidgets('an explicit position on a higher level disables lower-level position builders', (WidgetTester tester) async {
      final FluentBarConfig config = FluentBarConfig(defaultPositionBuilder: globalPosition);
      final FluentBarType typeWithBuilder = FluentBarType.info.copyWith(positionBuilder: typePosition);
      final FluentBarType typeWithPosition = FluentBarType.info.copyWith(position: FluentBarPosition.bottom);

      expect(
        entryOf(
          type: typeWithBuilder,
          behavior: const FluentBarBehavior(position: FluentBarPosition.top),
        ).resolvePositionBuilder(config),
        isNull,
      );
      expect(entryOf(type: typeWithPosition).resolvePositionBuilder(config), isNull);
    });

    testWidgets('transitionBuilder: local -> type -> config, entranceAnimation shadows lower levels', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      Widget localTransition(BuildContext c, Animation<double> a, Widget child) => const Text('local');
      Widget typeTransition(BuildContext c, Animation<double> a, Widget child) => const Text('type');
      Widget globalTransition(BuildContext c, Animation<double> a, Widget child) => const Text('global');

      final FluentBarType type = FluentBarType.info.copyWith(transitionBuilder: typeTransition);
      final FluentBarConfig config = FluentBarConfig(defaultTransitionBuilder: globalTransition);
      const Widget child = SizedBox();
      const Animation<double> animation = kAlwaysCompleteAnimation;

      final FluentBarEntry<void> local = entryOf(
        type: type,
        appearance: FluentBarAppearance<void>(transitionBuilder: localTransition),
      );
      expect(textOf(local.resolveTransitionBuilder(config)!(context, animation, child)), 'local');
      expect(textOf(entryOf(type: type).resolveTransitionBuilder(config)!(context, animation, child)), 'type');
      expect(textOf(entryOf().resolveTransitionBuilder(config)!(context, animation, child)), 'global');

      final FluentBarEntry<void> localAnimation = entryOf(
        type: type,
        appearance: const FluentBarAppearance<void>(entranceAnimation: FluentBarEntranceAnimation.fade),
      );
      expect(localAnimation.resolveTransitionBuilder(config), isNull);
      expect(entryOf(type: FluentBarType.info.copyWith(entranceAnimation: FluentBarEntranceAnimation.fade)).resolveTransitionBuilder(config), isNull);
    });

    testWidgets('builder: local -> type -> config', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      Widget localBuilder(BuildContext c, FluentBarEntry<void> e) => const Text('local');
      Widget typeBuilder(BuildContext c, FluentBarEntry<dynamic> e) => const Text('type');
      Widget globalBuilder(BuildContext c, FluentBarEntry<dynamic> e) => const Text('global');

      final FluentBarType type = FluentBarType.info.copyWith(builder: typeBuilder);
      final FluentBarConfig config = FluentBarConfig(defaultBuilder: globalBuilder);

      final FluentBarEntry<void> local = entryOf(
        type: type,
        appearance: FluentBarAppearance<void>(builder: localBuilder),
      );
      expect(textOf(local.resolveBuilder(config)!(context, local)), 'local');
      final FluentBarEntry<void> typed = entryOf(type: type);
      expect(textOf(typed.resolveBuilder(config)!(context, typed)), 'type');
      final FluentBarEntry<void> plain = entryOf();
      expect(textOf(plain.resolveBuilder(config)!(context, plain)), 'global');
    });

    testWidgets('progressBuilder is part of the progress theme: bar -> type -> config', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      Widget named(String name) => Text(name);
      Widget Function(BuildContext, ValueListenable<FluentBarProgressState?>) builderOf(String name) =>
          (BuildContext c, ValueListenable<FluentBarProgressState?> n) => named(name);
      final ValueNotifier<FluentBarProgressState?> notifier = ValueNotifier<FluentBarProgressState?>(null);
      addTearDown(notifier.dispose);

      String? resolved(FluentBarEntry<void> entry, FluentBarConfig config) => textOf(entry.resolveProgressBuilder(config)?.call(context, notifier));

      final FluentBarConfig fullConfig = FluentBarConfig(progressTheme: FluentBarProgressTheme(progressBuilder: builderOf('config')));
      final FluentBarType fullType = FluentBarType.info.copyWith(progressTheme: FluentBarProgressTheme(progressBuilder: builderOf('type')));

      final FluentBarEntry<void> local = entryOf(
        type: fullType,
        appearance: FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(progressBuilder: builderOf('local'))),
      );
      expect(resolved(local, fullConfig), 'local');
      expect(resolved(entryOf(type: fullType), fullConfig), 'type');
      expect(resolved(entryOf(), fullConfig), 'config');
      expect(entryOf().resolveProgressBuilder(const FluentBarConfig()), isNull);

      final FluentBarEntry<void> colorOnly = entryOf(
        type: fullType,
        appearance: const FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(progressColor: Colors.red)),
      );
      expect(resolved(colorOnly, fullConfig), 'type');
    });

    testWidgets('a throwing builder falls back instead of crashing', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarConfig config = FluentBarConfig();
      const Widget child = SizedBox(key: Key('child'));

      final FluentBarEntry<void> entry = entryOf(
        behavior: FluentBarBehavior(positionBuilder: (BuildContext c, Widget w) => throw Exception('boom')),
        appearance: FluentBarAppearance<void>(
          builder: (BuildContext c, FluentBarEntry<void> e) => throw Exception('boom'),
          transitionBuilder: (BuildContext c, Animation<double> a, Widget w) => throw Exception('boom'),
        ),
      );

      expect(entry.resolvePositionBuilder(config)!(context, child), same(child));
      expect(entry.resolveTransitionBuilder(config)!(context, kAlwaysCompleteAnimation, child), same(child));
      expect(entry.resolveBuilder(config)!(context, entry), isNull);
    });
  });

  group('theme-level resolvers (local -> theme)', () {
    testWidgets('decoration, colors, radius, text and action settings', (WidgetTester tester) async {
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

      const FluentBarConfig config = FluentBarConfig();
      const FluentBarThemeMode mode = FluentBarThemeMode.light;
      final FluentBarTheme theme = FluentBarTheme.material.copyWith(
        actionMaxLines: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => 4,
        actionOverflow: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => TextOverflow.fade,
        actionLoaderColor: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => Colors.orange,
      );

      final FluentBarType type = FluentBarType.info.copyWith(backgroundColor: Colors.purple);
      expect(entryOf(type: type).resolveDecoration(context, theme, mode, config).color, Colors.purple);
      expect(
        entryOf(
          type: type,
          appearance: const FluentBarAppearance<void>(backgroundColor: Colors.red),
        ).resolveDecoration(context, theme, mode, config).color,
        Colors.red,
      );
      expect(
        entryOf(
          type: type,
          appearance: const FluentBarAppearance<void>(
            backgroundColor: Colors.red,
            decoration: BoxDecoration(color: Colors.green),
          ),
        ).resolveDecoration(context, theme, mode, config).color,
        Colors.green,
      );

      expect(entryOf().resolveBorderRadius(context, theme, mode, config), theme.boxDecoration(context, FluentBarType.info, theme, themeMode: mode).borderRadius);
      final FluentBarEntry<void> directional = entryOf(
        appearance: const FluentBarAppearance<void>(
          decoration: BoxDecoration(borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(7))),
        ),
      );
      expect(directional.resolveBorderRadius(context, theme, mode, config), const BorderRadius.only(topLeft: Radius.circular(7)));

      const FluentBarActions<void> plainActions = FluentBarActions<void>(label: 'OK');
      expect(plainActions.resolveActionMaxLines(context, theme, FluentBarType.info, themeMode: mode), 4);
      expect(plainActions.resolveActionOverflow(context, theme, FluentBarType.info, themeMode: mode), TextOverflow.fade);

      const FluentBarActions<void> localActions = FluentBarActions<void>(label: 'OK', maxActionLines: 2, actionOverflow: TextOverflow.clip, actionLoaderColor: Colors.teal);
      expect(localActions.resolveActionMaxLines(context, theme, FluentBarType.info, themeMode: mode), 2);
      expect(localActions.resolveActionOverflow(context, theme, FluentBarType.info, themeMode: mode), TextOverflow.clip);

      FluentBarItem<void> itemWith(FluentBarActions<void> actions) => FluentBarItem<void>(message: 'Test', type: FluentBarType.info, actions: actions);
      expect(itemWith(plainActions).resolveActionLoaderColor(context, theme, FluentBarType.info, mode), Colors.orange);
      expect(itemWith(localActions).resolveActionLoaderColor(context, theme, FluentBarType.info, mode), Colors.teal);
    });
  });
}
