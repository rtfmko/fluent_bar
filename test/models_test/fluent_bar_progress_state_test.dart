import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarProgressState Tests', () {
    group('Factory Constructors', () {
      test('indeterminate factory creates FluentBarProgressIndeterminate instance', () {
        const FluentBarProgressState state = FluentBarProgressState.indeterminate();

        expect(state, isA<FluentBarProgressIndeterminate>());
      });

      test('value factory creates FluentBarProgressValue instance', () {
        const FluentBarProgressState state = FluentBarProgressState.value(0.5);

        expect(state, isA<FluentBarProgressValue>());
        expect((state as FluentBarProgressValue).value, 0.5);
      });

      test('fraction factory creates FluentBarProgressFraction instance', () {
        const FluentBarProgressState state = FluentBarProgressState.fraction(2, 5);

        expect(state, isA<FluentBarProgressFraction>());
        const FluentBarProgressFraction fraction = state as FluentBarProgressFraction;
        expect(fraction.current, 2);
        expect(fraction.total, 5);
      });
    });

    group('FluentBarProgressIndeterminate Tests', () {
      test('should return null progress and false isCompleted', () {
        const FluentBarProgressIndeterminate state = FluentBarProgressIndeterminate();

        expect(state.progress, isNull);
        expect(state.isCompleted, isFalse);
      });
    });

    group('FluentBarProgressValue Tests', () {
      test('should return correct progress and completion status for valid boundaries', () {
        const FluentBarProgressValue minState = FluentBarProgressValue(0.0);
        expect(minState.progress, 0.0);
        expect(minState.isCompleted, isFalse);

        const FluentBarProgressValue midState = FluentBarProgressValue(0.42);
        expect(midState.progress, 0.42);
        expect(midState.isCompleted, isFalse);

        const FluentBarProgressValue maxState = FluentBarProgressValue(1.0);
        expect(maxState.progress, 1.0);
        expect(maxState.isCompleted, isTrue);
      });

      test('should throw AssertionError when percentage is negative', () {
        expect(() => FluentBarProgressValue(-0.01), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when percentage is greater than 1.0', () {
        expect(() => FluentBarProgressValue(1.01), throwsA(isA<AssertionError>()));
      });
    });

    group('FluentBarProgressFraction Tests', () {
      test('should calculate progress and completion status correctly', () {
        const FluentBarProgressFraction startState = FluentBarProgressFraction(0, 10);
        expect(startState.progress, 0.0);
        expect(startState.isCompleted, isFalse);

        const FluentBarProgressFraction midState = FluentBarProgressFraction(5, 10);
        expect(midState.progress, 0.5);
        expect(midState.isCompleted, isFalse);

        const FluentBarProgressFraction endState = FluentBarProgressFraction(10, 10);
        expect(endState.progress, 1.0);
        expect(endState.isCompleted, isTrue);
      });

      test('should throw AssertionError when current is negative', () {
        expect(() => FluentBarProgressFraction(-1, 5), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when total is 0', () {
        expect(() => FluentBarProgressFraction(0, 0), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when total is negative', () {
        expect(() => FluentBarProgressFraction(0, -5), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when current is greater than total', () {
        expect(() => FluentBarProgressFraction(6, 5), throwsA(isA<AssertionError>()));
      });
    });

    group('Equality', () {
      double runtime(double v) => v * 1.0;
      int runtimeInt(int v) => v + 0;

      test('value states are equal when the percentage is equal', () {
        final FluentBarProgressState a = FluentBarProgressValue(runtime(0.5));
        final FluentBarProgressState b = FluentBarProgressValue(runtime(0.5));

        expect(identical(a, b), isFalse);
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
        expect(a == FluentBarProgressValue(runtime(0.6)), isFalse);
      });

      test('fraction states are equal when both numbers are equal', () {
        final FluentBarProgressState a = FluentBarProgressFraction(runtimeInt(2), runtimeInt(5));
        final FluentBarProgressState b = FluentBarProgressFraction(runtimeInt(2), runtimeInt(5));

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
        expect(a == FluentBarProgressFraction(runtimeInt(3), runtimeInt(5)), isFalse);
        expect(a == FluentBarProgressFraction(runtimeInt(4), runtimeInt(10)), isFalse, reason: 'same ratio, but a different label');
      });

      test('states of different kinds are never equal, even with the same progress', () {
        const FluentBarProgressState value = FluentBarProgressValue(0.5);
        const FluentBarProgressState fraction = FluentBarProgressFraction(1, 2);
        const FluentBarProgressState indeterminate = FluentBarProgressIndeterminate();

        expect(value.progress, fraction.progress);
        expect(value == fraction, isFalse);
        expect(value == indeterminate, isFalse);
        expect(indeterminate, equals(const FluentBarProgressState.indeterminate()));
      });

      test('indeterminate states created at runtime are equal too', () {
        // ignore: prefer_const_constructors
        final FluentBarProgressState a = FluentBarProgressIndeterminate();
        // ignore: prefer_const_constructors
        final FluentBarProgressState b = FluentBarProgressIndeterminate();

        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
        expect(a == (const FluentBarProgressValue(0.0) as Object), isFalse);
      });

      test('items with equal progress are equal, so a repeated update does not rebuild the bar', () {
        FluentBarItem<void> item(double progress) => FluentBarItem<void>(type: FluentBarType.info, message: 'Upload', progressState: FluentBarProgressValue(runtime(progress)));

        expect(item(0.3), equals(item(0.3)));
        expect(item(0.3) == item(0.4), isFalse);
      });
    });

    group('Labels', () {
      test('format() gives a default label for every kind', () {
        expect(const FluentBarProgressValue(0.42).format(), '42%');
        expect(const FluentBarProgressFraction(3, 5).format(), '3 / 5');
        expect(const FluentBarProgressIndeterminate().format(), '');
      });

      test('format() accepts custom formatters', () {
        expect(const FluentBarProgressValue(0.5).format(formatValue: (double p) => 'half'), 'half');
        expect(const FluentBarProgressFraction(3, 5).format(formatFraction: (int c, int t) => '$c of $t'), '3 of 5');
        expect(const FluentBarProgressIndeterminate().format(formatIndeterminate: () => 'wait'), 'wait');
      });
    });

    group('Sealed Pattern Matching Tests', () {
      test('should exhaustively match all progress states in switch expression', () {
        String evaluateState(FluentBarProgressState state) {
          return switch (state) {
            FluentBarProgressIndeterminate() => 'indeterminate',
            FluentBarProgressValue(:final double value) => 'value:$value',
            FluentBarProgressFraction(:final int current, :final int total) => 'fraction:$current/$total',
            FluentBarProgressBytes(:final int received) => 'bytes:$received',
          };
        }

        expect(evaluateState(const FluentBarProgressState.indeterminate()), 'indeterminate');
        expect(evaluateState(const FluentBarProgressState.value(0.75)), 'value:0.75');
        expect(evaluateState(const FluentBarProgressState.fraction(3, 4)), 'fraction:3/4');
      });
    });
  });
}
