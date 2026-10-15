import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFluentBarController<T> extends Fake implements FluentBarInternalController<T> {
  bool isPaused = false;
  bool isResumed = false;
  bool isClosed = false;

  Duration? newDuration;
  bool? resetTimer;
  Duration? addedDuration;
  Duration? subtractedDuration;

  double? shakeIntensity;
  double? bounceScale;

  double? pulseScale;
  Duration? pulseDuration;

  double? heartbeatScale;
  Duration? heartbeatDuration;

  double? customEffectIntensity;
  Duration? customEffectDuration;

  FluentBarEffect? triggeredEffectType;
  double? triggeredEffectIntensity;
  Duration? triggeredEffectDuration;

  FluentBarProgressState? updatedProgress;
  String? cancelFallbackMessage;

  String? updatedTitle;
  String? updatedMessage;
  T? updatedPayload;

  FluentBarActions<T>? updatedActions;

  @override
  void pause() => isPaused = true;

  @override
  void resume() => isResumed = true;

  @override
  void close({FluentBarDismissReason reason = FluentBarDismissReason.manual}) => isClosed = true;

  @override
  void updateDuration(Duration? duration, {bool resetTimer = false}) {
    newDuration = duration;
    this.resetTimer = resetTimer;
  }

  @override
  void addDuration(Duration extraDuration) => addedDuration = extraDuration;

  @override
  void subtractDuration(Duration lessDuration) => subtractedDuration = lessDuration;

  @override
  void shake({double intensity = 8.0, Duration duration = const Duration(milliseconds: 400), bool repeat = false}) {
    shakeIntensity = intensity;
  }

  @override
  void bounce({double scale = 0.1, Duration duration = const Duration(milliseconds: 400), bool repeat = false}) {
    bounceScale = scale;
  }

  @override
  void pulse({double scale = 1.05, Duration duration = const Duration(milliseconds: 600), bool repeat = false}) {
    pulseScale = scale;
    pulseDuration = duration;
  }

  @override
  void heartbeat({double scale = 1.15, Duration duration = const Duration(milliseconds: 800), bool repeat = false}) {
    heartbeatScale = scale;
    heartbeatDuration = duration;
  }

  @override
  void customEffect({double intensity = 1.0, Duration duration = const Duration(milliseconds: 500), bool repeat = false}) {
    customEffectIntensity = intensity;
    customEffectDuration = duration;
  }

  @override
  void triggerEffect(FluentBarEffect type, {double? intensity, Duration? duration, bool repeat = false}) {
    triggeredEffectType = type;
    triggeredEffectIntensity = intensity;
    triggeredEffectDuration = duration;
  }

  @override
  void updateProgress(FluentBarProgressState newProgressState, {String? completedMessage, String? completedTitle, FluentBarType? completedType}) {
    updatedProgress = newProgressState;
  }

  @override
  void cancelProgress({String? fallbackMessage, FluentBarType? fallbackType, bool dismiss = false}) {
    cancelFallbackMessage = fallbackMessage;
  }

  @override
  void updateContent({String? title, String? message, T? payload, FluentBarType? type, bool clearTitle = false}) {
    updatedTitle = title;
    updatedMessage = message;
    updatedPayload = payload;
  }

  @override
  void updateActions(FluentBarActions<T>? actions) {
    updatedActions = actions;
  }
}

class TestableFluentBarEntry<T> extends FluentBarEntry<T> {
  final FakeFluentBarController<T> fakeController;

  TestableFluentBarEntry(FluentBarItem<T> item, this.fakeController) : super(item: item);

  @override
  FluentBarInternalController<T> get controller => fakeController;
}

void main() {
  group('FluentBarProgressStateLabel Extension Tests', () {
    test('format() returns correct strings for FluentBarProgressValue', () {
      const FluentBarProgressState state = FluentBarProgressState.value(0.75);

      expect(state.format(), '75%');

      expect(state.format(formatValue: (double v) => 'Progress: ${v * 100}'), 'Progress: 75.0');
    });

    test('format() returns correct strings for FluentBarProgressFraction', () {
      const FluentBarProgressState state = FluentBarProgressState.fraction(3, 5);

      expect(state.format(), '3 / 5');

      expect(state.format(formatFraction: (int c, int t) => '$c of $t'), '3 of 5');
    });

    test('format() returns correct strings for FluentBarProgressIndeterminate', () {
      const FluentBarProgressState state = FluentBarProgressState.indeterminate();

      expect(state.format(), '');

      expect(state.format(formatIndeterminate: () => 'Loading...'), 'Loading...');
    });
  });

  group('FluentBarItemActionsX Extension Tests', () {
    late FakeFluentBarController<void> fakeController;
    late TestableFluentBarEntry<void> entry;

    setUp(() {
      fakeController = FakeFluentBarController<void>();
      entry = TestableFluentBarEntry<void>(FluentBarItem<void>(message: 'Test', type: FluentBarType.info), fakeController);
    });

    test('pause and resume delegate to controller', () {
      entry.pause();
      expect(fakeController.isPaused, isTrue);

      entry.resume();
      expect(fakeController.isResumed, isTrue);
    });

    test('shake and bounce delegate with correct parameters', () {
      entry.shake(intensity: 12.0);
      expect(fakeController.shakeIntensity, 12.0);

      entry.bounce(scale: 0.5);
      expect(fakeController.bounceScale, 0.5);
    });

    test('pulse, heartbeat, customEffect and triggerEffect delegate with correct parameters', () {
      entry.pulse(scale: 1.1, duration: const Duration(milliseconds: 300));
      expect(fakeController.pulseScale, 1.1);
      expect(fakeController.pulseDuration, const Duration(milliseconds: 300));

      entry.heartbeat(scale: 1.2, duration: const Duration(milliseconds: 400));
      expect(fakeController.heartbeatScale, 1.2);
      expect(fakeController.heartbeatDuration, const Duration(milliseconds: 400));

      entry.customEffect(intensity: 1.5, duration: const Duration(milliseconds: 250));
      expect(fakeController.customEffectIntensity, 1.5);
      expect(fakeController.customEffectDuration, const Duration(milliseconds: 250));

      entry.triggerEffect(FluentBarEffect.shake, intensity: 5.0, duration: const Duration(milliseconds: 100));
      expect(fakeController.triggeredEffectType, FluentBarEffect.shake);
      expect(fakeController.triggeredEffectIntensity, 5.0);
      expect(fakeController.triggeredEffectDuration, const Duration(milliseconds: 100));
    });

    test('updateDuration, addDuration and subtractDuration delegate to the controller', () {
      entry.updateDuration(const Duration(seconds: 4), resetTimer: true);
      expect(fakeController.newDuration, const Duration(seconds: 4));
      expect(fakeController.resetTimer, isTrue);

      entry.addDuration(const Duration(seconds: 5));
      expect(fakeController.addedDuration, const Duration(seconds: 5));

      entry.subtractDuration(const Duration(seconds: 2));
      expect(fakeController.subtractedDuration, const Duration(seconds: 2));
    });

    test('close delegates to controller', () {
      entry.close();
      expect(fakeController.isClosed, isTrue);
    });

    test('updateProgress, updateFraction, updateValue delegate correctly', () {
      entry.updateValue(0.4);
      expect(fakeController.updatedProgress, isA<FluentBarProgressValue>());
      expect((fakeController.updatedProgress as FluentBarProgressValue).value, 0.4);

      entry.updateFraction(2, 4);
      expect(fakeController.updatedProgress, isA<FluentBarProgressFraction>());
      expect((fakeController.updatedProgress as FluentBarProgressFraction).current, 2);
      expect((fakeController.updatedProgress as FluentBarProgressFraction).total, 4);
    });

    test('cancelProgress delegates correctly', () {
      entry.cancelProgress(fallbackMessage: 'Canceled');
      expect(fakeController.cancelFallbackMessage, 'Canceled');
    });

    test('update (content) delegates correctly', () {
      entry.update(title: 'New Title', message: 'New Message');
      expect(fakeController.updatedTitle, 'New Title');
      expect(fakeController.updatedMessage, 'New Message');
    });

    test('updateActions delegates correctly', () {
      const FluentBarActions<void> actions = FluentBarActions<void>();
      entry.updateActions(actions);
      expect(fakeController.updatedActions, actions);
    });
  });

  group('FluentBarItemExt & Entry show/force Extensions Tests', () {
    testWidgets('FluentBarItemExt show and force call FluentBar static methods correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: <NavigatorObserver>[FluentBarObserver.instance],
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final FluentBarItem<void> item = FluentBarItem<void>(message: 'Item Extension Test', type: FluentBarType.info);

      final FluentBarEntry<void>? entryFromItemShow = item.show();
      await tester.pump();

      expect(entryFromItemShow, isNotNull);
      expect(find.text('Item Extension Test'), findsOneWidget);

      entryFromItemShow?.close();
      await tester.pumpAndSettle();

      final FluentBarEntry<void>? entryFromItemForce = item.force();
      await tester.pump();

      expect(entryFromItemForce, isNotNull);
      expect(find.text('Item Extension Test'), findsOneWidget);

      entryFromItemForce?.close();
      await tester.pumpAndSettle();
    });

    testWidgets('FluentBarEntryActionsX show and force delegate to FluentBarManager correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: <NavigatorObserver>[FluentBarObserver.instance],
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final FluentBarEntry<void> entry = FluentBarEntry<void>(
        item: FluentBarItem<void>(message: 'Entry Extension Test', type: FluentBarType.info),
      );

      final FluentBarEntry<void>? shownEntry = entry.show();
      await tester.pump();

      expect(shownEntry, isNotNull);
      expect(find.text('Entry Extension Test'), findsOneWidget);

      shownEntry?.close();
      await tester.pumpAndSettle();

      final FluentBarEntry<void> forcedEntry = entry.force();
      await tester.pump();

      expect(forcedEntry, isNotNull);
      expect(find.text('Entry Extension Test'), findsOneWidget);

      forcedEntry.close();
      await tester.pumpAndSettle();
    });
  });
}
