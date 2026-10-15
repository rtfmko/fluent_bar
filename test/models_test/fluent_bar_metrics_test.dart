import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarMetrics', () {
    test('defaults describe a bar nobody touched', () {
      const FluentBarMetrics metrics = FluentBarMetrics(
        id: null,
        visibleDuration: Duration(seconds: 2),
        plannedDuration: Duration(seconds: 5),
        dismissReason: FluentBarDismissReason.manual,
        timedOut: false,
      );

      expect(metrics.id, isNull);
      expect(metrics.visibleDuration, const Duration(seconds: 2));
      expect(metrics.plannedDuration, const Duration(seconds: 5));
      expect(metrics.queuedDuration, Duration.zero);
      expect(metrics.pausedDuration, Duration.zero);
      expect(metrics.dismissReason, FluentBarDismissReason.manual);
      expect(metrics.timedOut, isFalse);
      expect(metrics.interactions, isEmpty);
      expect(metrics.wasUntouched, isTrue);
      expect(metrics.wasActionTapped, isFalse);
      expect(metrics.wasTapped, isFalse);
      expect(metrics.countOf(FluentBarInteraction.swipe), 0);
      expect(metrics.position, isNull);
      expect(metrics.wasForced, isFalse);
      expect(metrics.typeName, isNull);
      expect(metrics.preset, isNull);
    });

    test('interactions are counted and summarized', () {
      const FluentBarMetrics metrics = FluentBarMetrics(
        id: 'test',
        visibleDuration: Duration(seconds: 3),
        plannedDuration: null,
        dismissReason: FluentBarDismissReason.swipe,
        timedOut: false,
        interactions: <FluentBarInteraction, int>{FluentBarInteraction.tap: 3, FluentBarInteraction.action: 1, FluentBarInteraction.swipe: 1},
      );

      expect(metrics.wasUntouched, isFalse);
      expect(metrics.wasTapped, isTrue);
      expect(metrics.wasActionTapped, isTrue);
      expect(metrics.countOf(FluentBarInteraction.tap), 3);
      expect(metrics.countOf(FluentBarInteraction.hold), 0);
    });

    test('toMap carries everything in a flat, loggable form', () {
      const FluentBarMetrics metrics = FluentBarMetrics(
        id: 'test',
        visibleDuration: Duration(milliseconds: 1500),
        plannedDuration: Duration(seconds: 4),
        queuedDuration: Duration(milliseconds: 700),
        pausedDuration: Duration(milliseconds: 300),
        dismissReason: FluentBarDismissReason.timeout,
        timedOut: true,
        interactions: <FluentBarInteraction, int>{FluentBarInteraction.action: 2},
        position: FluentBarPosition.bottom,
        wasForced: true,
        typeName: 'info',
        preset: 'snack',
      );

      expect(metrics.toMap(), <String, dynamic>{
        'id': 'test',
        'visible_ms': 1500,
        'planned_ms': 4000,
        'queued_ms': 700,
        'paused_ms': 300,
        'dismiss_reason': 'timeout',
        'timed_out': true,
        'was_visible': true,
        'showing_ms': 0,
        'was_action_tapped': true,
        'interactions': <String, int>{'action': 2},
        'position': 'bottom',
        'was_forced': true,
        'was_tapped': false,
        'was_untouched': false,
        'update_count': 0,
        'had_action': false,
        'type_name': 'info',
        'preset': 'snack',
      });
    });

    test('toMap omits what is not set', () {
      const FluentBarMetrics metrics = FluentBarMetrics(id: null, visibleDuration: Duration(seconds: 1), plannedDuration: null, dismissReason: FluentBarDismissReason.manual, timedOut: false);

      final Map<String, dynamic> map = metrics.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('type_name'), isFalse);
      expect(map.containsKey('position'), isFalse);
      expect(map.containsKey('preset'), isFalse);
      expect(map['planned_ms'], isNull);
      expect(map['interactions'], isEmpty);
    });
  });
}
