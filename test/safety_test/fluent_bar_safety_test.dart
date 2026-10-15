import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenType extends FluentBarType {
  const _BrokenType();

  Never _fail() => throw StateError('type getter failed');

  @override
  String get name => _fail();

  @override
  FluentBarType get kind => _fail();

  @override
  bool? get isSwipeEnabled => _fail();

  @override
  bool? get isPersistent => _fail();

  @override
  bool? get disableAnimations => _fail();

  @override
  bool? get dismissOnTap => _fail();

  @override
  bool? get showIcon => _fail();

  @override
  bool? get showTimeoutBar => _fail();

  @override
  bool? get useSafeArea => _fail();

  @override
  Color? get backgroundColor => _fail();

  @override
  Color? get timeoutBarColor => _fail();

  @override
  Duration get duration => _fail();

  @override
  Duration? get transitionDuration => _fail();

  @override
  Duration? get reverseTransitionDuration => _fail();

  @override
  FluentBarPosition? get position => _fail();

  @override
  DismissDirection? get dismissDirection => _fail();

  @override
  FluentBarHapticType get haptic => _fail();

  @override
  FluentBarHapticType get progressCompletedHaptic => _fail();

  @override
  FluentBarPriority get priority => _fail();

  @override
  FluentBarEntranceAnimation? get entranceAnimation => _fail();

  @override
  FluentBarTimeoutBarDirection? get timeoutBarDirection => _fail();

  @override
  FluentBarProgressTheme? get progressTheme => _fail();

  @override
  FluentBarDuplicatePolicy? get duplicatePolicy => _fail();

  @override
  FluentBarRelocationStrategy? get relocationStrategy => _fail();

  @override
  FluentBarUpdateRate? get timeoutUpdateInterval => _fail();

  @override
  Widget? get icon => _fail();

  @override
  Widget Function(BuildContext context, Widget child)? get positionBuilder => _fail();

  @override
  Widget Function(BuildContext context, Animation<double> animation, Widget child)? get transitionBuilder => _fail();

  @override
  Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? get builder => _fail();

  @override
  Widget Function(BuildContext context, AnimationController controller, Widget child)? get customEffectBuilder => _fail();

  @override
  FutureOr<void> Function()? get customHaptic => _fail();

  @override
  FutureOr<void> Function()? get customProgressCompletedHaptic => _fail();
}

class _TypeWithBrokenBuilders extends FluentBarType {
  const _TypeWithBrokenBuilders();

  @override
  Widget Function(BuildContext context, Widget child)? get positionBuilder =>
      (BuildContext c, Widget child) => throw Exception('position');

  @override
  Widget Function(BuildContext context, Animation<double> animation, Widget child)? get transitionBuilder =>
      (BuildContext c, Animation<double> a, Widget child) => throw Exception('transition');

  @override
  Widget Function(BuildContext context, FluentBarEntry<dynamic> entry)? get builder =>
      (BuildContext c, FluentBarEntry<dynamic> e) => throw Exception('builder');

  @override
  FluentBarProgressTheme? get progressTheme => FluentBarProgressTheme(progressBuilder: (BuildContext c, ValueListenable<FluentBarProgressState?> n) => throw Exception('progress'));

  @override
  FutureOr<void> Function()? get customHaptic =>
      () => throw Exception('haptic');

  @override
  FutureOr<void> Function()? get customProgressCompletedHaptic =>
      () => throw Exception('progress haptic');
}

class _BrokenTheme extends FluentBarTheme {
  const _BrokenTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => throw StateError('theme failed');

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle();

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle();
}

class _ThrowingStrategy extends FluentBarQueueStrategy {
  const _ThrowingStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) => throw Exception('enqueue');

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) => throw Exception('dequeue');
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });
  tearDown(() => FluentBar.removeErrorHandler(onError));

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig()}) async {
    manager.resetForTesting();
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Set<FluentBarErrorType> errorTypes() => errors.map((FluentBarException e) => e.type).toSet();

  group('custom type', () {
    test('built-in types are not wrapped; a custom type is wrapped once', () {
      const FluentBarType custom = _BrokenType();

      expect(FluentBarType.guard(FluentBarType.info), same(FluentBarType.info));
      expect(FluentBarType.guard(FluentBarType.error), same(FluentBarType.error));
      expect(FluentBarType.guard(custom), isNot(same(custom)));
      expect(FluentBarType.guard(custom), same(FluentBarType.guard(custom)));
      expect(FluentBarType.guard(FluentBarType.guard(custom)), same(FluentBarType.guard(custom)));
    });

    test('a healthy custom type keeps all of its values through the guard', () {
      final FluentBarType custom = FluentBarType.error.copyWith(position: FluentBarPosition.bottom, duration: const Duration(seconds: 9), showIcon: false);
      final FluentBarType guarded = FluentBarType.guard(custom);

      expect(guarded.name, 'error');
      expect(guarded.kind, same(FluentBarType.error));
      expect(guarded.position, FluentBarPosition.bottom);
      expect(guarded.duration, const Duration(seconds: 9));
      expect(guarded.showIcon, isFalse);
      expect(guarded.priority, FluentBarPriority.high);
      expect(guarded.haptic, FluentBarHapticType.heavy);
      expect(guarded.isSwipeEnabled, isFalse);
      expect(errors, isEmpty);
    });

    test('every throwing getter is reported and replaced with the default value', () {
      final FluentBarType guarded = FluentBarType.guard(const _BrokenType());

      expect(guarded.name, 'custom');
      expect(guarded.kind, same(guarded));
      expect(guarded.isSwipeEnabled, isNull);
      expect(guarded.isPersistent, isNull);
      expect(guarded.disableAnimations, isNull);
      expect(guarded.dismissOnTap, isNull);
      expect(guarded.showIcon, isNull);
      expect(guarded.showTimeoutBar, isNull);
      expect(guarded.useSafeArea, isNull);
      expect(guarded.backgroundColor, isNull);
      expect(guarded.timeoutBarColor, isNull);
      expect(guarded.duration, isNull);
      expect(guarded.transitionDuration, isNull);
      expect(guarded.reverseTransitionDuration, isNull);
      expect(guarded.position, isNull);
      expect(guarded.dismissDirection, isNull);
      expect(guarded.haptic, FluentBarHapticType.none);
      expect(guarded.progressCompletedHaptic, FluentBarHapticType.none);
      expect(guarded.priority, FluentBarPriority.normal);
      expect(guarded.entranceAnimation, isNull);
      expect(guarded.timeoutBarDirection, isNull);
      expect(guarded.progressTheme, isNull);
      expect(guarded.duplicatePolicy, isNull);
      expect(guarded.relocationStrategy, isNull);
      expect(guarded.timeoutUpdateInterval, isNull);
      expect(guarded.icon, isNull);
      expect(guarded.positionBuilder, isNull);
      expect(guarded.transitionBuilder, isNull);
      expect(guarded.builder, isNull);
      expect(guarded.customEffectBuilder, isNull);
      expect(guarded.customHaptic, isNull);
      expect(guarded.customProgressCompletedHaptic, isNull);

      expect(errors, hasLength(32));
      expect(errorTypes(), <FluentBarErrorType>{FluentBarErrorType.fluentBarType});
    });

    testWidgets('a bar with a completely broken type is shown, counts down and closes with defaults', (WidgetTester tester) async {
      await boot(tester);
      FluentBarMetrics? metrics;

      final FluentBarEntry<void>? entry = FluentBar.show<void>(
        message: 'Broken type',
        type: const _BrokenType(),
        options: FluentBarOptions<void>(callbacks: FluentBarCallbacks<void>(onDismiss: (_, FluentBarMetrics m) => metrics = m)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(entry, isNotNull);
      expect(find.text('Broken type'), findsOneWidget);
      expect(errorTypes(), <FluentBarErrorType>{FluentBarErrorType.fluentBarType});

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(FluentBar.mainActiveItem, isNull);
      expect(metrics?.dismissReason, FluentBarDismissReason.timeout);
      expect(metrics?.typeName, 'custom');
    });

    testWidgets('the same broken type registered through typeOverrides is guarded too', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(typeOverrides: <FluentBarType, FluentBarType>{FluentBarType.info: _BrokenType()}));

      FluentBar.show<void>(message: 'Overridden', isPersistent: true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Overridden'), findsOneWidget);
      expect(errorTypes(), <FluentBarErrorType>{FluentBarErrorType.fluentBarType});
      await cleanup(tester);
    });

    test('toString of an item with a broken type does not throw', () {
      final FluentBarItem<void> item = FluentBarItem<void>(type: const _BrokenType(), message: 'Message');

      expect(item.toString(), contains('type: custom'));
    });
  });

  group('custom theme', () {
    testWidgets('a throwing theme is reported and the bar is drawn with the built-in theme', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(defaultTheme: _BrokenTheme()));

      FluentBar.show<void>(message: 'Broken theme', title: 'Title', isPersistent: true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Broken theme'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(errorTypes(), <FluentBarErrorType>{FluentBarErrorType.fluentBarTheme});

      final Container container = tester.widget<Container>(find.ancestor(of: find.text('Broken theme'), matching: find.byType(Container)).first);
      expect((container.decoration! as BoxDecoration).color, isNotNull);
      await cleanup(tester);
    });

    testWidgets('a throwing theme set on a single bar does not affect other bars', (WidgetTester tester) async {
      await boot(tester);

      FluentBar.show<void>(
        message: 'Broken',
        isPersistent: true,
        options: const FluentBarOptions<void>(appearance: FluentBarAppearance<void>(theme: _BrokenTheme())),
      );
      FluentBar.show<void>(
        message: 'Healthy',
        isPersistent: true,
        options: const FluentBarOptions<void>(behavior: FluentBarBehavior(position: FluentBarPosition.bottom)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Broken'), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);
      expect(errors, isNotEmpty);
      await cleanup(tester);
    });
  });

  group('builders report their own error type', () {
    testWidgets('content builder -> customBuilderAppearance, transition builder -> customBuilderTransition', (WidgetTester tester) async {
      await boot(tester);

      FluentBar.show<void>(
        message: 'Fallback content',
        isPersistent: true,
        options: FluentBarOptions<void>(
          appearance: FluentBarAppearance<void>(
            builder: (BuildContext c, FluentBarEntry<void> e) => throw Exception('builder'),
            transitionBuilder: (BuildContext c, Animation<double> a, Widget child) => throw Exception('transition'),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Fallback content'), findsOneWidget, reason: 'the default widget is used instead of the broken builder');
      expect(errorTypes(), containsAll(<FluentBarErrorType>[FluentBarErrorType.customBuilderAppearance, FluentBarErrorType.customBuilderTransition]));
      await cleanup(tester);
    });
  });

  group('everything user-supplied throws at once', () {
    testWidgets('the bar is still shown, updated, and closed; every failure is reported', (WidgetTester tester) async {
      await boot(
        tester,
        config: FluentBarConfig(
          defaultTheme: const _BrokenTheme(),
          defaultQueueStrategy: const _ThrowingStrategy(),
          duplicateComparator: (FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) => throw Exception('comparator'),
          defaultBuilder: (BuildContext c, FluentBarEntry<dynamic> e) => throw Exception('config builder'),
          defaultPositionBuilder: (BuildContext c, Widget child) => throw Exception('config position'),
          defaultTransitionBuilder: (BuildContext c, Animation<double> a, Widget child) => throw Exception('config transition'),
          progressTheme: FluentBarProgressTheme(progressBuilder: (BuildContext c, ValueListenable<FluentBarProgressState?> n) => throw Exception('config progress')),
        ),
      );
      void brokenAnalytics(FluentBarAnalyticsPayload payload) => throw Exception('analytics');
      void brokenHandler(FluentBarException error, StackTrace stackTrace) => throw Exception('handler');
      FluentBar.addAnalyticsListener(brokenAnalytics);
      FluentBar.addErrorHandler(brokenHandler);
      addTearDown(() {
        FluentBar.removeAnalyticsListener(brokenAnalytics);
        FluentBar.removeErrorHandler(brokenHandler);
      });

      FluentBarEntry<String>? show(String message) => FluentBar.show<String>(
        message: message,
        type: const _TypeWithBrokenBuilders(),
        payload: 'payload',
        options: FluentBarOptions<String>(
          progressState: const FluentBarProgressValue(0.2),
          behavior: FluentBarBehavior(dismissOnTap: true, positionBuilder: (BuildContext c, Widget child) => throw Exception('position')),
          appearance: FluentBarAppearance<String>(
            builder: (BuildContext c, FluentBarEntry<String> e) => throw Exception('builder'),
            transitionBuilder: (BuildContext c, Animation<double> a, Widget child) => throw Exception('transition'),
            customEffectBuilder: (BuildContext c, AnimationController a, Widget child) => throw Exception('effect'),
            progressTheme: FluentBarProgressTheme(showText: true, labelBuilder: (FluentBarProgressState s) => throw Exception('label')),
          ),
          actions: FluentBarActions<String>(label: 'ACTION', closeOnAction: false, onPressed: (FluentBarController<String> c, String? p) => throw Exception('action')),
          callbacks: FluentBarCallbacks<String>(
            haptic: () => throw Exception('haptic'),
            progressCompletedHaptic: () => throw Exception('progress haptic'),
            onShow: (_) => throw Exception('onShow'),
            onTap: (_) => throw Exception('onTap'),
            onDismiss: (_, _) => throw Exception('onDismiss'),
            onProgressCompleted: (_) => throw Exception('onProgressCompleted'),
            onProgressCanceled: (_) => throw Exception('onProgressCanceled'),
          ),
        ),
      );

      final FluentBarEntry<String>? first = show('First');
      final FluentBarEntry<String>? second = show('Second');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(find.text('First'), findsOneWidget);
      expect(FluentBar.mainQueueLength, 1);

      first!.controller.updateProgress(const FluentBarProgressValue(0.6));
      first.controller.customEffect();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('ACTION'));
      await tester.pump(const Duration(seconds: 1));
      first.controller.updateProgress(const FluentBarProgressValue(1.0));
      first.controller.cancelProgress();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('First'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);

      await FluentBar.closeAll(skipAnimation: true);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(FluentBar.activeItems, isEmpty);

      expect(
        errorTypes(),
        containsAll(<FluentBarErrorType>[
          FluentBarErrorType.fluentBarTheme,
          FluentBarErrorType.queueEnqueue,
          FluentBarErrorType.queueDequeue,
          FluentBarErrorType.callbackDuplicateComparator,
          FluentBarErrorType.customBuilderAppearance,
          FluentBarErrorType.customBuilderTransition,
          FluentBarErrorType.customBuilderEffect,
          FluentBarErrorType.fluentBarResolver,
          FluentBarErrorType.actionPressed,
          FluentBarErrorType.hapticExternal,
          FluentBarErrorType.callbackShow,
          FluentBarErrorType.callbackTap,
          FluentBarErrorType.callbackDismiss,
          FluentBarErrorType.callbackProgressCompleted,
          FluentBarErrorType.callbackProgressCanceled,
          FluentBarErrorType.callbackAnalytics,
        ]),
      );
    });
  });
}
