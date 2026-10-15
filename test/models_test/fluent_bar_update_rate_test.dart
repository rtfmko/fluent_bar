import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarUpdateRate Tests', () {
    test('should clamp intervals below minimum to 5 milliseconds', () {
      final FluentBarUpdateRate rateZero = FluentBarUpdateRate(Duration.zero);
      final FluentBarUpdateRate rateNegative = FluentBarUpdateRate(const Duration(milliseconds: -10));

      expect(rateZero.interval.inMilliseconds, 5);
      expect(rateNegative.interval.inMilliseconds, 5);
    });

    test('should clamp intervals above maximum to 1000 milliseconds', () {
      final FluentBarUpdateRate rateHigh = FluentBarUpdateRate(const Duration(seconds: 5));

      expect(rateHigh.interval.inMilliseconds, 1000);
    });

    test('should keep valid intervals within bounds', () {
      final FluentBarUpdateRate rate = FluentBarUpdateRate(const Duration(milliseconds: 50));

      expect(rate.interval.inMilliseconds, 50);
    });

    test('should correctly handle custom and ms factories', () {
      final FluentBarUpdateRate customRate = FluentBarUpdateRate.custom(const Duration(milliseconds: 25));
      final FluentBarUpdateRate msRate = FluentBarUpdateRate.ms(30);

      expect(customRate.interval.inMilliseconds, 25);
      expect(msRate.interval.inMilliseconds, 30);
    });

    test('should provide correct predefined rates', () {
      expect(FluentBarUpdateRate.low.interval.inMilliseconds, 100);
      expect(FluentBarUpdateRate.medium.interval.inMilliseconds, 50);
      expect(FluentBarUpdateRate.high.interval.inMilliseconds, 33);
      expect(FluentBarUpdateRate.fps60.interval.inMilliseconds, 16);
      expect(FluentBarUpdateRate.fps120.interval.inMilliseconds, 8);
    });
  });
}
