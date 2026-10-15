import 'package:fluent_bar/src/internal.dart';

/// The outcome of the life of a bar. Comes with the `dismissed` event and in `onDismiss`.
class FluentBarMetrics {
  /// The id of the bar, if it has one.
  final String? id;

  /// How long the bar stayed in place, from the end of its entrance animation until it started
  /// to close. Zero if it was closed while still appearing (see [wasVisible]).
  final Duration visibleDuration;

  /// How long the bar was appearing. For a bar closed during its entrance, how far it got.
  final Duration showingDuration;

  /// Whether the bar finished appearing. `false` means it was closed (or replaced) while its
  /// entrance animation was still playing, so the user hardly saw it.
  final bool wasVisible;

  /// The planned lifetime (from the settings of the bar, its type and the config).
  final Duration? plannedDuration;

  /// How long the bar waited in the queue. Zero if it was shown at once.
  final Duration queuedDuration;

  /// How much of the time on screen the countdown stood still (touch, pause(), loading, a running action).
  final Duration pausedDuration;

  /// Why the bar was closed.
  final FluentBarDismissReason dismissReason;

  /// The bar closed by itself after living out its time.
  final bool timedOut;

  /// What the user did with the bar and how many times: tapped it, tapped the action or the close button, held it, swiped it away, dismissed it with a screen reader.
  final Map<FluentBarInteraction, int> interactions;

  /// Where the bar was when it closed.
  final FluentBarPosition? position;

  /// The bar was shown out of turn, bypassing the queue.
  final bool wasForced;

  /// How many times the bar was changed after it was requested: content, look, behavior, action,
  /// duration, or a re-show with the same id. Progress ticks sent through the controller do not count.
  final int updateCount;

  /// Whether the bar had an action button when it closed. With [wasActionTapped] it gives the
  /// share of bars whose button was used.
  final bool hadAction;

  /// How the task of a bar with progress ended; `null` if the bar had no progress or it never finished.
  final FluentBarProgressOutcome? progressOutcome;

  /// The name of the type (`info`, `success`, a custom one).
  final String? typeName;

  /// The preset label (`snack`, `toast`, `banner`, `loading`, or the one set with `withPreset`).
  final String? preset;

  /// The tags of the bar (`withTag`); empty when it has none.
  final Set<String> tags;

  /// Creates the metrics of a closed bar.
  const FluentBarMetrics({
    required this.id,
    required this.visibleDuration,
    required this.plannedDuration,
    required this.dismissReason,
    required this.timedOut,
    this.queuedDuration = Duration.zero,
    this.pausedDuration = Duration.zero,
    this.interactions = const <FluentBarInteraction, int>{},
    this.position,
    this.wasForced = false,
    this.wasVisible = true,
    this.updateCount = 0,
    this.hadAction = false,
    this.progressOutcome,
    this.showingDuration = Duration.zero,
    this.typeName,
    this.preset,
    this.tags = const <String>{},
  });

  /// How many times [interaction] happened.
  int countOf(FluentBarInteraction interaction) => interactions[interaction] ?? 0;

  /// The action button was tapped at least once, whether or not it closed the bar.
  bool get wasActionTapped => countOf(FluentBarInteraction.action) > 0;

  /// The bar itself was tapped at least once.
  bool get wasTapped => countOf(FluentBarInteraction.tap) > 0;

  /// The user did not interact with the bar at all.
  bool get wasUntouched => interactions.isEmpty;

  /// Every field as a map with snake_case keys. It holds a nested map, flags and a list; for a
  /// service that takes only strings and numbers use [toFlatMap].
  Map<String, dynamic> toMap() => <String, dynamic>{
    if (id != null) 'id': id,
    'visible_ms': visibleDuration.inMilliseconds,
    'planned_ms': plannedDuration?.inMilliseconds,
    'queued_ms': queuedDuration.inMilliseconds,
    'paused_ms': pausedDuration.inMilliseconds,
    'dismiss_reason': dismissReason.name,
    'timed_out': timedOut,
    'was_visible': wasVisible,
    'showing_ms': showingDuration.inMilliseconds,
    'was_action_tapped': wasActionTapped,
    'interactions': <String, int>{for (final MapEntry<FluentBarInteraction, int> entry in interactions.entries) entry.key.name: entry.value},
    if (position != null) 'position': position!.name,
    'was_forced': wasForced,
    'was_tapped': wasTapped,
    'was_untouched': wasUntouched,
    'update_count': updateCount,
    'had_action': hadAction,
    if (progressOutcome != null) 'progress_outcome': progressOutcome!.name,
    if (typeName != null) 'type_name': typeName,
    if (preset != null) 'preset': preset,
    if (tags.isNotEmpty) 'tags': tags.toList(),
  };

  /// The metrics as a map of strings and numbers only, for services that accept nothing else
  /// as event parameters (Firebase Analytics, Amplitude, Mixpanel and others).
  ///
  /// Compared with [toMap]: flags become `1` / `0`, each interaction gets its own key
  /// (`interaction_tap`, `interaction_action`...), and absent values are left out.
  ///
  /// ```dart
  /// FirebaseAnalytics.instance.logEvent(name: 'bar_dismissed', parameters: metrics.toFlatMap());
  /// ```
  Map<String, Object> toFlatMap() => <String, Object>{
    for (final MapEntry<String, dynamic> entry in toMap().entries)
      if (entry.value is bool) entry.key: (entry.value as bool) ? 1 : 0 else if (entry.value is String || entry.value is num) entry.key: entry.value as Object,
    for (final MapEntry<FluentBarInteraction, int> entry in interactions.entries) 'interaction_${entry.key.name}': entry.value,
    if (tags.isNotEmpty) 'tags': tags.join(','),
  };
}
