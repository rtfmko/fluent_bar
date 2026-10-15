import 'dart:async';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// Telemetry shows how an app listens to the library: one analytics listener and one error handler,
// registered once.
class TelemetryEvent {
  final DateTime time = DateTime.now();
  final FluentBarAnalyticsPayload payload;

  BarRecord? record;

  TelemetryEvent(this.payload);

  FluentBarAnalyticsEvent get event => payload.event;
}

class TelemetryError {
  final DateTime time = DateTime.now();
  final FluentBarException error;
  final StackTrace stackTrace;

  TelemetryError(this.error, this.stackTrace);
}

class BarRecord {
  final String key;
  final DateTime requestedAt = DateTime.now();
  final Map<FluentBarLifecycleState, DateTime> states = <FluentBarLifecycleState, DateTime>{};
  final List<TelemetryEvent> events = <TelemetryEvent>[];

  FluentBarItem<dynamic> item;
  FluentBarMetrics? metrics;
  bool isTracked = false;

  bool isClosed = false;

  BarRecord(this.key, this.item);

  bool get isFinished => states.containsKey(FluentBarLifecycleState.dismissed);

  bool get wasShown => states.containsKey(FluentBarLifecycleState.visible);

  int offsetOf(DateTime time) => time.difference(requestedAt).inMilliseconds;
}

class Telemetry extends ChangeNotifier {
  Telemetry._();

  static final Telemetry instance = Telemetry._();

  static const int _maxEvents = 300;
  static const int _maxBars = 80;

  final List<TelemetryEvent> events = <TelemetryEvent>[];
  final List<TelemetryError> errors = <TelemetryError>[];
  final List<BarRecord> bars = <BarRecord>[];
  final Map<FluentBarAnalyticsEvent, int> counts = <FluentBarAnalyticsEvent, int>{};

  bool _isStarted = false;
  bool _isNotifyScheduled = false;

  void start() {
    if (_isStarted) return;
    _isStarted = true;
    FluentBar.addAnalyticsListener(_onAnalytics);
    FluentBar.addErrorHandler(_onError);
  }

  int count(FluentBarAnalyticsEvent event) => counts[event] ?? 0;

  void clear() {
    events.clear();
    errors.clear();
    counts.clear();
    bars.removeWhere((BarRecord record) => record.isFinished);
    notifyListeners();
  }

  void _onAnalytics(FluentBarAnalyticsPayload payload) {
    final TelemetryEvent event = TelemetryEvent(payload);

    events.insert(0, event);
    if (events.length > _maxEvents) events.removeLast();
    counts.update(payload.event, (int value) => value + 1, ifAbsent: () => 1);

    final BarRecord record = _recordFor(payload.item);
    record.events.add(event);
    event.record = record;
    record.metrics = payload.metrics ?? record.metrics;
    if (payload.event != FluentBarAnalyticsEvent.updated && payload.event != FluentBarAnalyticsEvent.ignoredDuplicate) record.item = payload.item;

    if (!record.isTracked) scheduleMicrotask(() => _track(record));

    if (payload.event.hasMetrics) record.isClosed = true;

    _scheduleNotify();
  }

  void _onError(FluentBarException error, StackTrace stackTrace) {
    errors.insert(0, TelemetryError(error, stackTrace));
    if (errors.length > _maxEvents) errors.removeLast();
    _scheduleNotify();
  }

  BarRecord _recordFor(FluentBarItem<dynamic> item) {
    final String key = item.id ?? item.uuid;
    for (final BarRecord record in bars) {
      if (record.key == key && !record.isClosed) return record;
    }

    final BarRecord record = BarRecord(key, item)..states[FluentBarLifecycleState.queued] = DateTime.now();
    bars.insert(0, record);
    if (bars.length > _maxBars) bars.removeLast();
    return record;
  }

  void _track(BarRecord record) {
    if (record.isTracked || record.isClosed) return;

    FluentBarEntry<dynamic>? entry;
    for (final FluentBarEntry<dynamic> candidate in <FluentBarEntry<dynamic>>[...FluentBar.activeItems, ...FluentBar.allQueue]) {
      if ((candidate.item.id ?? candidate.item.uuid) == record.key) entry = candidate;
    }
    if (entry == null) {
      record.states[FluentBarLifecycleState.dismissed] = DateTime.now();
      record.isClosed = true;
      _scheduleNotify();
      return;
    }

    record.isTracked = true;
    final ValueListenable<FluentBarLifecycleState> state = entry.controller.stateNotifier;

    void onState() {
      _mark(record, state.value);
      if (state.value.isDismissed) {
        state.removeListener(onState);
        Timer.run(() => record.isClosed = true);
      }
      _scheduleNotify();
    }

    _mark(record, state.value);
    state.addListener(onState);
    _scheduleNotify();
  }

  void _mark(BarRecord record, FluentBarLifecycleState reached) {
    final DateTime now = DateTime.now();
    if (reached != FluentBarLifecycleState.dismissed) {
      for (final FluentBarLifecycleState step in FluentBarLifecycleState.values) {
        if (step.index < reached.index) record.states.putIfAbsent(step, () => now);
      }
    }
    record.states.putIfAbsent(reached, () => now);
  }

  void _scheduleNotify() {
    if (_isNotifyScheduled) return;
    _isNotifyScheduled = true;

    void notify() {
      _isNotifyScheduled = false;
      notifyListeners();
    }

    final WidgetsBinding? binding = _bindingOrNull();
    if (binding == null) {
      Timer.run(notify);
      return;
    }

    binding
      ..addPostFrameCallback((_) => notify())
      ..ensureVisualUpdate();
  }

  static WidgetsBinding? _bindingOrNull() {
    try {
      return WidgetsBinding.instance;
    } catch (_) {
      return null;
    }
  }
}
