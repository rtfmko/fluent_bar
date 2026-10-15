import 'dart:convert';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/telemetry.dart';
import 'demo_kit.dart';

Color colorOfEvent(FluentBarAnalyticsEvent event) => switch (event) {
  FluentBarAnalyticsEvent.requested => Colors.blue,
  FluentBarAnalyticsEvent.queued => Colors.indigo,
  FluentBarAnalyticsEvent.shown => Colors.green,
  FluentBarAnalyticsEvent.dismissed => Colors.blueGrey,
  FluentBarAnalyticsEvent.queueOverflow || FluentBarAnalyticsEvent.progressFailed => Colors.red,
  FluentBarAnalyticsEvent.ignoredDuplicate || FluentBarAnalyticsEvent.progressCanceled => Colors.orange,
  FluentBarAnalyticsEvent.tapped || FluentBarAnalyticsEvent.actionTapped => Colors.pink,
  FluentBarAnalyticsEvent.updated || FluentBarAnalyticsEvent.relocated => Colors.purple,
  FluentBarAnalyticsEvent.paused || FluentBarAnalyticsEvent.resumed => Colors.brown,
  FluentBarAnalyticsEvent.progressCompleted => Colors.teal,
};

String clockOf(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';

const TextStyle _mono = TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.4);

Map<String, Map<String, String>> describePayload(FluentBarAnalyticsPayload payload) {
  final FluentBarItem<dynamic> item = payload.item;
  final FluentBarBehavior behavior = item.behavior;
  final FluentBarAppearance<dynamic> appearance = item.appearance;
  final FluentBarMetrics? metrics = payload.metrics;

  Map<String, String> clean(Map<String, Object?> source) => <String, String>{
    for (final MapEntry<String, Object?> entry in source.entries)
      if (entry.value != null) entry.key: entry.value is Enum ? (entry.value! as Enum).name : entry.value.toString(),
  };

  return <String, Map<String, String>>{
    if (payload.pauseReason != null) 'Pause': <String, String>{'pauseReason': payload.pauseReason!.name},
    if (payload.previousPosition != null) 'Relocation': <String, String>{'previousPosition': payload.previousPosition!.name},
    if (metrics != null)
      'Metrics': clean(<String, Object?>{
        'dismissReason': metrics.dismissReason,
        'wasVisible': metrics.wasVisible,
        'showingDuration': '${metrics.showingDuration.inMilliseconds} ms',
        'visibleDuration': '${metrics.visibleDuration.inMilliseconds} ms',
        'queuedDuration': '${metrics.queuedDuration.inMilliseconds} ms',
        'pausedDuration': '${metrics.pausedDuration.inMilliseconds} ms',
        'interactions': metrics.interactions.isEmpty ? 'none' : metrics.interactions.entries.map((MapEntry<FluentBarInteraction, int> e) => '${e.key.name} x${e.value}').join(', '),
        'position': metrics.position,
        'wasForced': metrics.wasForced,
        'preset': metrics.preset,
        'tags': metrics.tags.isEmpty ? null : metrics.tags.join(', '),
        'plannedDuration': metrics.plannedDuration == null ? null : '${metrics.plannedDuration!.inMilliseconds} ms',
        'timedOut': metrics.timedOut,
        'wasActionTapped': metrics.wasActionTapped,
        'typeName': metrics.typeName,
      }),
    'Item': clean(<String, Object?>{
      'id': item.id,
      'preset': item.preset,
      'tags': item.tags.isEmpty ? null : item.tags.join(', '),
      'uuid': item.uuid,
      'type': FluentBarType.guard(item.type).name,
      'title': item.title,
      'message': item.message,
      'duration': item.duration == null ? null : '${item.duration!.inMilliseconds} ms',
      'isPersistent': item.isPersistent,
      'payload': item.payload,
      'meta': item.meta,
      'progress': switch (item.progressState) {
        null => null,
        final FluentBarProgressState state => state.progress == null ? 'indeterminate' : '${state.format()} (${(state.progress! * 100).round()}%)',
      },
      'action': item.actions?.label,
      'analyticsName': item.actions?.analyticsName,
    }),
    'Behavior': clean(<String, Object?>{
      'position': behavior.position,
      'priority': behavior.priority,
      'isForce': behavior.isForce ? true : null,
      'duplicatePolicy': behavior.duplicatePolicy,
      'relocationStrategy': behavior.relocationStrategy,
      'isSwipeEnabled': behavior.isSwipeEnabled,
      'dismissOnTap': behavior.dismissOnTap,
      'pauseOnTouch': behavior.pauseOnTouch,
      'semantics': behavior.semantics,
      'useSafeArea': behavior.useSafeArea,
      'haptic': behavior.haptic,
    }),
    'Appearance': clean(<String, Object?>{
      'themeMode': appearance.themeMode,
      'showCloseButton': appearance.showCloseButton,
      'entranceAnimation': appearance.entranceAnimation,
      'showIcon': appearance.showIcon,
      'showTimeoutBar': appearance.showTimeoutBar,
      'timeoutBarPosition': appearance.timeoutBarPosition,
      'backgroundColor': appearance.backgroundColor,
      'customTheme': appearance.theme?.runtimeType,
      'customBuilder': appearance.builder == null ? null : true,
    }),
  }..removeWhere((String _, Map<String, String> fields) => fields.isEmpty);
}

Object? _plain(Object? value) => switch (value) {
  null || num() || bool() || String() => value,
  Enum() => value.name,
  Duration() => value.inMilliseconds,
  Map<Object?, Object?>() => <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in value.entries)
      if (entry.value != null) '${_plain(entry.key)}': _plain(entry.value),
  },
  Iterable<Object?>() => <Object?>[for (final Object? element in value) _plain(element)],
  _ => value.toString(),
};

// The raw view prints what a listener receives, field by field: the demo adds only the `at`
// timestamps and leaves unset fields out.
Map<String, Object?> rawPayload(FluentBarAnalyticsPayload payload) {
  final FluentBarItem<dynamic> item = payload.item;
  final FluentBarBehavior behavior = item.behavior;
  final FluentBarAppearance<dynamic> appearance = item.appearance;
  final FluentBarProgressState? progress = item.progressState;

  final Object? plain = _plain(<String, Object?>{
    'event': payload.event,
    'pauseReason': payload.pauseReason,
    'previousPosition': payload.previousPosition,
    'item': <String, Object?>{
      'id': item.id,
      'uuid': item.uuid,
      'preset': item.preset,
      'type': FluentBarType.guard(item.type).name,
      'title': item.title,
      'message': item.message,
      'duration_ms': item.duration,
      'isPersistent': item.isPersistent,
      'payload': item.payload,
      'meta': item.meta,
      'action': item.actions?.label,
      'analyticsName': item.actions?.analyticsName,
      'progress': progress == null ? null : <String, Object?>{'value': progress.progress, 'text': progress.format()},
      'behavior': <String, Object?>{
        'position': behavior.position,
        'priority': behavior.priority,
        'isForce': behavior.isForce,
        'duplicatePolicy': behavior.duplicatePolicy,
        'relocationStrategy': behavior.relocationStrategy,
        'isSwipeEnabled': behavior.isSwipeEnabled,
        'dismissOnTap': behavior.dismissOnTap,
        'pauseOnTouch': behavior.pauseOnTouch,
        'semantics': behavior.semantics,
        'useSafeArea': behavior.useSafeArea,
        'haptic': behavior.haptic,
      },
      'appearance': <String, Object?>{
        'themeMode': appearance.themeMode,
        'showCloseButton': appearance.showCloseButton,
        'entranceAnimation': appearance.entranceAnimation,
        'showIcon': appearance.showIcon,
        'showTimeoutBar': appearance.showTimeoutBar,
        'timeoutBarPosition': appearance.timeoutBarPosition,
        'backgroundColor': appearance.backgroundColor,
        'theme': appearance.theme?.runtimeType,
      },
    },
    'metrics': payload.metrics?.toMap(),
  });

  return plain! as Map<String, Object?>;
}

Map<String, Object?> rawLifecycle(BarRecord record) => <String, Object?>{
  for (final FluentBarLifecycleState state in FluentBarLifecycleState.values)
    if (record.states[state] != null) state.name: clockOf(record.states[state]!),
};

List<Object?> rawEvents(BarRecord record) => <Object?>[
  for (final TelemetryEvent event in record.events) <String, Object?>{'at': clockOf(event.time), 'offset_ms': record.offsetOf(event.time), ...rawPayload(event.payload)},
];

class RawBlock extends StatelessWidget {
  final String title;
  final String source;
  final Object? data;

  const RawBlock({super.key, required this.title, required this.source, required this.data});

  static const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

  static final RegExp _token = RegExp(r'("(?:[^"\\]|\\.)*")(\s*:)?|\b(?:true|false|null)\b|-?\d+(?:\.\d+)?');

  static List<TextSpan> _highlight(String json, ColorScheme scheme) {
    final List<TextSpan> spans = <TextSpan>[];
    int last = 0;

    for (final RegExpMatch match in _token.allMatches(json)) {
      if (match.start > last) spans.add(TextSpan(text: json.substring(last, match.start)));

      final String? text = match.group(1);
      if (text == null) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(color: scheme.tertiary, fontWeight: FontWeight.w600),
          ),
        );
      } else if (match.group(2) != null) {
        spans
          ..add(
            TextSpan(
              text: text,
              style: TextStyle(color: scheme.primary),
            ),
          )
          ..add(TextSpan(text: match.group(2)));
      } else {
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(color: scheme.onSurface),
          ),
        );
      }
      last = match.end;
    }

    if (last < json.length) spans.add(TextSpan(text: json.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String json = _pretty.convert(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DemoLabel(title),
                      Text(source, style: _mono.copyWith(color: scheme.primary)),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy JSON',
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: json));
                    FluentBar.showToast('JSON copied', id: 'code_copied');
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText.rich(
                TextSpan(
                  style: _mono.copyWith(color: scheme.onSurfaceVariant),
                  children: _highlight(json, scheme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PayloadDetails extends StatelessWidget {
  final FluentBarAnalyticsPayload payload;

  const PayloadDetails(this.payload, {super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final MapEntry<String, Map<String, String>> group in describePayload(payload).entries) ...<Widget>[
          Padding(padding: const EdgeInsets.only(top: 8, bottom: 2), child: DemoLabel(group.key)),
          for (final MapEntry<String, String> field in group.value.entries)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 140,
                  child: Text(field.key, style: _mono.copyWith(color: scheme.onSurfaceVariant)),
                ),
                Expanded(
                  child: SelectableText(field.value, style: _mono.copyWith(color: scheme.onSurface)),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

class EventTag extends StatelessWidget {
  final FluentBarAnalyticsEvent event;

  const EventTag(this.event, {super.key});

  @override
  Widget build(BuildContext context) => _Pill(event.name, colorOfEvent(event));
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
    child: Text(
      text,
      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

(String, Color) statusOf(BarRecord record) {
  if (record.isFinished && !record.wasShown) return ('never shown', Colors.orange);
  if (record.isFinished) return ('dismissed', Colors.blueGrey);

  final FluentBarLifecycleState current = FluentBarLifecycleState.values.lastWhere(record.states.containsKey, orElse: () => FluentBarLifecycleState.queued);
  return (current.name, current.isQueued ? Colors.indigo : Colors.green);
}

class LifecycleSteps extends StatelessWidget {
  final BarRecord record;
  final bool isCompact;

  const LifecycleSteps(this.record, {super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color accent = statusOf(record).$2;
    const List<FluentBarLifecycleState> steps = FluentBarLifecycleState.values;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: isCompact ? 4 : 6),
                child: Container(height: 2, color: record.states.containsKey(steps[i]) ? accent : scheme.outlineVariant),
              ),
            ),
          _Step(label: steps[i].name, offset: record.states[steps[i]] == null ? null : record.offsetOf(record.states[steps[i]]!), color: accent, isCompact: isCompact),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final int? offset;
  final Color color;
  final bool isCompact;

  const _Step({required this.label, required this.offset, required this.color, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isReached = offset != null;
    final double size = isCompact ? 10 : 14;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReached ? color : Colors.transparent,
            border: Border.all(color: isReached ? color : scheme.outlineVariant, width: 2),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: isCompact ? 9.5 : 11, fontWeight: isReached ? FontWeight.w700 : FontWeight.w400, color: isReached ? scheme.onSurface : scheme.onSurfaceVariant),
        ),
        if (!isCompact)
          Text(
            isReached ? '+$offset ms' : '-',
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class BarRow extends StatelessWidget {
  final BarRecord record;

  const BarRow(this.record, {super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final FluentBarItem<dynamic> item = record.item;
    final (String status, Color color) = statusOf(record);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: record.isFinished ? Colors.transparent : color.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showBarSheet(context, record),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title ?? item.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _Pill(status, color),
                    if (item.preset != null) ...<Widget>[const SizedBox(width: 4), _Pill(item.preset!, Colors.teal)],
                    if (item.behavior.position != null) ...<Widget>[const SizedBox(width: 4), _Pill(item.behavior.position!.name, scheme.tertiary)],
                    if (item.behavior.priority != null) ...<Widget>[const SizedBox(width: 4), _Pill(item.behavior.priority!.name, scheme.primary)],
                    if (item.behavior.isForce) ...<Widget>[const SizedBox(width: 4), const _Pill('forced', Colors.red)],
                    const SizedBox(width: 2),
                    Text('${record.events.length}', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 8),
                LifecycleSteps(record, isCompact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showBarSheet(BuildContext context, BarRecord record, {TelemetryEvent? focus}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    minChildSize: 0.35,
    maxChildSize: 0.95,
    builder: (BuildContext context, ScrollController scrollController) => _BarSheet(record: record, focus: focus, scrollController: scrollController),
  ),
);

class _BarSheet extends StatefulWidget {
  final BarRecord record;
  final TelemetryEvent? focus;
  final ScrollController scrollController;

  const _BarSheet({required this.record, required this.focus, required this.scrollController});

  @override
  State<_BarSheet> createState() => _BarSheetState();
}

class _BarSheetState extends State<_BarSheet> {
  late TelemetryEvent? _open = widget.focus;
  bool _isRaw = false;

  final GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focus == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? target = _focusKey.currentContext;
      if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), alignment: 0.1);
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Telemetry.instance,
    builder: (BuildContext context, _) {
      final ThemeData theme = Theme.of(context);
      final ColorScheme scheme = theme.colorScheme;
      final BarRecord record = widget.record;
      final FluentBarItem<dynamic> item = record.item;
      final FluentBarMetrics? metrics = record.metrics;
      final (String status, Color color) = statusOf(record);

      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(item.title ?? item.message, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (item.preset != null) ...<Widget>[_Pill(item.preset!, Colors.teal), const SizedBox(width: 4)],
              _Pill(status, color),
            ],
          ),
          if (item.title != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(item.message, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          const SizedBox(height: 4),
          SelectableText('id: ${record.key}   requested at ${clockOf(record.requestedAt)}', style: _mono.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: false, icon: Icon(Icons.insights, size: 16), label: Text('Summary')),
              ButtonSegment<bool>(value: true, icon: Icon(Icons.data_object, size: 16), label: Text('Raw data')),
            ],
            selected: <bool>{_isRaw},
            onSelectionChanged: (Set<bool> selection) => setState(() => _isRaw = selection.first),
          ),
          const SizedBox(height: 16),
          if (_isRaw) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Exactly what the library hands to the app. The summary tab is drawn from these sources and nothing else.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            RawBlock(title: 'Lifecycle', source: 'entry.controller.stateNotifier', data: rawLifecycle(record)),
            if (metrics != null) RawBlock(title: 'Metrics', source: 'payload.metrics.toMap()', data: metrics.toMap()),
            RawBlock(title: 'Analytics events (${record.events.length})', source: 'FluentBar.addAnalyticsListener((payload) { ... })', data: rawEvents(record)),
          ],
          if (!_isRaw) ...<Widget>[const DemoLabel('Lifecycle'), const SizedBox(height: 10), LifecycleSteps(record)],
          if (!_isRaw && metrics != null) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DemoStat('dismiss reason', metrics.dismissReason.name, color: Colors.blueGrey),
                DemoStat('appearing', '${metrics.showingDuration.inMilliseconds} ms', color: Colors.teal),
                DemoStat(metrics.wasVisible ? 'in place' : 'never fully shown', '${metrics.visibleDuration.inMilliseconds} ms', color: metrics.wasVisible ? Colors.green : Colors.orange),
                if (metrics.plannedDuration != null) DemoStat('planned', '${metrics.plannedDuration!.inMilliseconds} ms', color: Colors.blue),
                DemoStat('waited in queue', '${metrics.queuedDuration.inMilliseconds} ms', color: Colors.indigo),
                DemoStat('paused', '${metrics.pausedDuration.inMilliseconds} ms', color: Colors.brown),
                DemoStat(
                  'user did',
                  metrics.wasUntouched ? 'nothing' : metrics.interactions.entries.map((MapEntry<FluentBarInteraction, int> e) => e.value > 1 ? '${e.key.name} x${e.value}' : e.key.name).join(', '),
                  color: Colors.pink,
                ),
                if (metrics.updateCount > 0) DemoStat('updates', '${metrics.updateCount}', color: Colors.purple),
                if (metrics.hadAction) DemoStat('action button', metrics.wasActionTapped ? 'pressed' : 'not pressed', color: Colors.deepOrange),
                if (metrics.progressOutcome != null) DemoStat('progress', metrics.progressOutcome!.name, color: Colors.teal),
              ],
            ),
          ],
          if (!_isRaw) ...<Widget>[const SizedBox(height: 18), DemoLabel('Analytics events (${record.events.length})'), const SizedBox(height: 6)],
          for (final TelemetryEvent event in _isRaw ? const <TelemetryEvent>[] : record.events)
            _SheetEvent(
              key: identical(event, widget.focus) ? _focusKey : null,
              record: record,
              event: event,
              isOpen: identical(event, _open),
              onTap: () => setState(() => _open = identical(event, _open) ? null : event),
            ),
        ],
      );
    },
  );
}

class _SheetEvent extends StatelessWidget {
  final BarRecord record;
  final TelemetryEvent event;
  final bool isOpen;
  final VoidCallback onTap;

  const _SheetEvent({super.key, required this.record, required this.event, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final FluentBarMetrics? metrics = event.payload.metrics;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: isOpen ? scheme.primary.withValues(alpha: 0.08) : scheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 74,
                    child: Text('+${record.offsetOf(event.time)} ms', style: _mono.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  EventTag(event.event),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metrics != null
                          ? '${metrics.dismissReason.name}, ${metrics.visibleDuration.inMilliseconds} ms on screen'
                          : (event.payload.pauseReason != null ? 'reason: ${event.payload.pauseReason!.name}' : clockOf(event.time)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Icon(isOpen ? Icons.expand_less : Icons.expand_more, size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
              if (isOpen) PayloadDetails(event.payload),
            ],
          ),
        ),
      ),
    );
  }
}

class EventLog extends StatelessWidget {
  final List<TelemetryEvent> events;
  final double height;

  const EventLog({super.key, required this.events, this.height = 340});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: events.isEmpty
          ? Center(
              child: Text('No events here yet.', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                final TelemetryEvent event = events[index];
                final FluentBarMetrics? metrics = event.payload.metrics;
                final String name = event.payload.item.id ?? event.payload.item.message;

                return InkWell(
                  onTap: event.record == null ? null : () => showBarSheet(context, event.record!, focus: event),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: <Widget>[
                        Text(
                          clockOf(event.time),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        EventTag(event.event),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            metrics == null ? name : '$name  -  ${metrics.dismissReason.name}, ${metrics.visibleDuration.inMilliseconds} ms',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: scheme.onSurface),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ErrorLog extends StatelessWidget {
  final List<TelemetryError> errors;
  final double height;

  const ErrorLog({super.key, required this.errors, this.height = 220});

  static void _showSheet(BuildContext context, TelemetryError entry) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);
      final bool isWarning = entry.error.severity.isWarning;

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(entry.error.type.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                _Pill(entry.error.severity.name, isWarning ? Colors.orange : Colors.red),
              ],
            ),
            const SizedBox(height: 4),
            Text(clockOf(entry.time), style: _mono.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            const DemoLabel('Original error'),
            const SizedBox(height: 4),
            SelectableText('${entry.error.error}', style: _mono),
            const SizedBox(height: 14),
            const DemoLabel('Stack trace'),
            const SizedBox(height: 4),
            SelectableText(entry.stackTrace.toString().split('\n').take(14).join('\n'), style: _mono.copyWith(fontSize: 11)),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: errors.isEmpty
          ? Center(
              child: Text('No errors reported yet.', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: errors.length,
              itemBuilder: (BuildContext context, int index) {
                final TelemetryError entry = errors[index];
                final bool isWarning = entry.error.severity.isWarning;

                return InkWell(
                  onTap: () => _showSheet(context, entry),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: <Widget>[
                        Text(
                          clockOf(entry.time),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Icon(isWarning ? Icons.warning_amber_rounded : Icons.error_outline, size: 14, color: isWarning ? Colors.orange : Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${entry.error.type.displayName}: ${entry.error.error}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: scheme.onSurface),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class QueueLanes extends StatelessWidget {
  const QueueLanes({super.key});

  static Color _colorOf(FluentBarEntry<dynamic> entry) => switch (entry.item.behavior.priority) {
    FluentBarPriority.critical => Colors.red,
    FluentBarPriority.high => Colors.orange,
    FluentBarPriority.low => Colors.green,
    _ => Colors.blue,
  };

  Widget _lane(BuildContext context, String label, FluentBarEntry<dynamic>? active, List<FluentBarEntry<dynamic>> queue) {
    final ThemeData theme = Theme.of(context);

    Widget chip(FluentBarEntry<dynamic> entry, {bool isActive = false}) {
      final Color color = _colorOf(entry);
      return Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isActive ? 0.9 : 0.14),
          borderRadius: BorderRadius.circular(8),
          border: entry.item.behavior.isForce ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(
          entry.item.title ?? entry.item.id ?? 'bar',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : theme.colorScheme.onSurface),
        ),
      );
    }

    return Row(
      children: <Widget>[
        SizedBox(width: 58, child: DemoLabel(label)),
        Expanded(
          child: SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                if (active != null) chip(active, isActive: true),
                if (active == null && queue.isEmpty)
                  Center(
                    child: Text('empty', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                for (final FluentBarEntry<dynamic> entry in queue) chip(entry),
              ],
            ),
          ),
        ),
        Text(
          '${queue.length} / ${FluentBar.currentConfig.maxQueueLength}',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[Telemetry.instance, FluentBar.allQueueLengthNotifier, FluentBar.configNotifier]),
    builder: (BuildContext context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _lane(context, 'Top', FluentBar.mainActiveItem, FluentBar.mainQueue),
        const SizedBox(height: 6),
        _lane(context, 'Bottom', FluentBar.bottomActiveItem, FluentBar.bottomQueue),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Filled chip = on screen, light chips = waiting. Color = priority, outline = forced.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    ),
  );
}
