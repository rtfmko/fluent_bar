import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarAnalyticsPayload Tests', () {
    test('should initialize with payload fields correctly', () {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Analytics test');
      const FluentBarMetrics metrics = FluentBarMetrics(
        id: 'test',
        visibleDuration: Duration(seconds: 1),
        plannedDuration: Duration(seconds: 3),
        dismissReason: FluentBarDismissReason.manual,
        timedOut: true,
      );

      final FluentBarAnalyticsPayload payload = FluentBarAnalyticsPayload(event: FluentBarAnalyticsEvent.shown, item: item, metrics: metrics);

      expect(payload.event, FluentBarAnalyticsEvent.shown);
      expect(payload.item, item);
      expect(payload.metrics, metrics);
      expect(payload.toString(), contains('FluentBarAnalyticsPayload'));
    });
  });
}
