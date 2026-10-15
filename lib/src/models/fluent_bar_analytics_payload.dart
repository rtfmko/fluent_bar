import 'package:fluent_bar/src/internal.dart';

/// What an analytics listener receives for every event of a bar.
///
/// ```dart
/// FluentBar.addAnalyticsListener((FluentBarAnalyticsPayload payload) {
///   analytics.log(payload.event.name, {'id': payload.item.id, ...?payload.metrics?.toMap()});
/// });
/// ```
class FluentBarAnalyticsPayload {
  /// What happened.
  final FluentBarAnalyticsEvent event;

  /// The bar the event belongs to.
  final FluentBarItem<dynamic> item;

  /// The outcome of the bar; only with the `dismissed` and `queueOverflow` events.
  final FluentBarMetrics? metrics;

  /// Why the countdown stopped. Only for the paused and resumed events.
  final FluentBarPauseReason? pauseReason;

  /// Where the bar was before it moved; set for `relocated`.
  final FluentBarPosition? previousPosition;

  /// Creates a payload for [event].
  const FluentBarAnalyticsPayload({required this.event, required this.item, this.metrics, this.pauseReason, this.previousPosition});

  /// The event as a map of strings and numbers only, ready for an analytics service: what the
  /// bar is (`id`, `type_name`, `preset`, `tags`, `position`, `action_name` of its button), the extras of the event (`pause_reason`,
  /// `previous_position`) and, when the event carries them, the metrics
  /// (see [FluentBarMetrics.toFlatMap]). Absent values are left out.
  ///
  /// ```dart
  /// FluentBar.addAnalyticsListener((payload) {
  ///   FirebaseAnalytics.instance.logEvent(name: 'bar_${payload.event.name}', parameters: payload.toFlatMap());
  /// });
  /// ```
  Map<String, Object> toFlatMap() => <String, Object>{
    'id': ?item.id,
    'type_name': FluentBarType.guard(item.type).name,
    'preset': ?item.preset,
    if (item.tags.isNotEmpty) 'tags': item.tags.join(','),
    'action_name': ?item.actions?.analyticsName,
    'position': ?item.behavior.position?.name,
    'pause_reason': ?pauseReason?.name,
    'previous_position': ?previousPosition?.name,
    ...?metrics?.toFlatMap(),
  };

  @override
  String toString() =>
      'FluentBarAnalyticsPayload{event: $event, item: $item, metrics: ${metrics?.toMap()}${pauseReason == null ? '' : ', pauseReason: ${pauseReason!.name}'}${previousPosition == null ? '' : ', previousPosition: ${previousPosition!.name}'}}';
}
