import 'dart:async';
import 'dart:math';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../app/telemetry.dart';
import '../widgets/demo_kit.dart';
import '../widgets/telemetry_views.dart';

enum _Where { top, bottom, both }

enum _Filter { all, onScreen, waiting, finished, neverShown }

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  static const List<String> _subjects = <String>['Backup', 'Upload', 'Payment', 'Message', 'Sync', 'Update', 'Invite', 'Export', 'Reminder', 'Download'];

  final Random _random = Random();

  Timer? _timer;
  int _counter = 0;

  _Where _where = _Where.both;
  _Filter _filter = _Filter.all;
  double _interval = 0.8;
  bool _randomPriority = true;
  bool _withForced = false;

  bool get _isRunning => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() => setState(() {
    if (_isRunning) {
      _timer?.cancel();
      _timer = null;
    } else {
      _generate();
      _timer = Timer.periodic(Duration(milliseconds: (_interval * 1000).round()), (_) => _generate());
    }
  });

  void _setInterval(double value) {
    setState(() => _interval = value);
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (value * 1000).round()), (_) => _generate());
  }

  void _generate() {
    _counter++;

    final FluentBarPriority priority = _randomPriority ? FluentBarPriority.values[_random.nextInt(FluentBarPriority.values.length)] : FluentBarPriority.normal;
    final bool bottom = switch (_where) {
      _Where.top => false,
      _Where.bottom => true,
      _Where.both => _random.nextBool(),
    };
    final FluentBarType type = switch (priority) {
      FluentBarPriority.critical => FluentBarType.error,
      FluentBarPriority.high => FluentBarType.warning,
      FluentBarPriority.normal => FluentBarType.info,
      FluentBarPriority.low => FluentBarType.success,
    };

    FluentBarItem<void> item = FluentBar.custom<void>(
      type,
      '${priority.name} priority, ${bottom ? 'bottom' : 'top'} region',
      title: '${_subjects[_random.nextInt(_subjects.length)]} #$_counter',
      id: 'gen_$_counter',
    ).withPriority(priority).withDuration(Duration(milliseconds: 1200 + _random.nextInt(2400))).withTimeoutBar().withMeta(<String, dynamic>{'source': 'generator', 'index': _counter});

    item = bottom ? item.atBottom() : item.atTop();
    if (_withForced && _random.nextInt(8) == 0) item = item.forced();

    item.show();
  }

  bool _matches(BarRecord record) => switch (_filter) {
    _Filter.all => true,
    _Filter.onScreen => !record.isFinished && record.wasShown,
    _Filter.waiting => !record.isFinished && !record.wasShown,
    _Filter.finished => record.isFinished && record.wasShown,
    _Filter.neverShown => record.isFinished && !record.wasShown,
  };

  static String _filterLabel(_Filter filter) => switch (filter) {
    _Filter.all => 'all',
    _Filter.onScreen => 'on screen',
    _Filter.waiting => 'waiting',
    _Filter.finished => 'finished',
    _Filter.neverShown => 'never shown',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Telemetry.instance,
    builder: (BuildContext context, _) {
      final Telemetry telemetry = Telemetry.instance;
      final List<BarRecord> shownBars = telemetry.bars.where((BarRecord r) => r.wasShown).toList();
      final int averageWait = shownBars.isEmpty
          ? 0
          : (shownBars.map((BarRecord r) => r.offsetOf(r.states[FluentBarLifecycleState.visible]!)).reduce((int a, int b) => a + b) / shownBars.length).round();
      final List<BarRecord> visible = telemetry.bars.where(_matches).take(40).toList();

      return DemoPage(
        title: 'Monitor',
        subtitle: 'A traffic generator plus everything the library reports about each bar. Start the generator, watch the queues fill and drain, then tap any bar to open its full story.',
        bottomNavigationBar: DemoBottomBar(
          child: Row(
            children: <Widget>[
              Expanded(
                child: _isRunning
                    ? DemoButton('Generating - tap to stop', icon: Icons.stop_rounded, tone: DemoTone.success, onPressed: _toggle)
                    : DemoButton('Start generator', icon: Icons.play_arrow_rounded, tone: DemoTone.primary, onPressed: _toggle),
              ),
              const SizedBox(width: 8),
              DemoButton('One', icon: Icons.add, onPressed: _generate),
              const SizedBox(width: 8),
              DemoButton(
                'Burst 10',
                onPressed: () {
                  for (int i = 0; i < 10; i++) {
                    _generate();
                  }
                },
              ),
            ],
          ),
        ),
        children: <Widget>[
          DemoSection(
            icon: Icons.shuffle_rounded,
            id: 'monitor/generator',
            description: 'Each generated bar gets a random priority, lifetime and (if you allow it) region. Faster than the bars can be shown? The queues grow and the strategy starts dropping.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoChoice<_Where>(
                  label: 'Region',
                  values: _Where.values,
                  selected: _where,
                  labelOf: (_Where w) => w == _Where.both ? 'random (top / bottom)' : w.name,
                  onChanged: (_Where v) => setState(() => _where = v),
                ),
                const SizedBox(height: 12),
                DemoSlider(label: 'One bar every', value: _interval, min: 0.2, max: 3, divisions: 28, format: (double v) => '${v.toStringAsFixed(1)} s', onChanged: _setInterval),
                DemoSwitch(label: 'Random priority', hint: 'Off: every bar is "normal"', value: _randomPriority, onChanged: (bool v) => setState(() => _randomPriority = v)),
                DemoSwitch(label: 'Sometimes forced', hint: 'About one bar in eight jumps the queue', value: _withForced, onChanged: (bool v) => setState(() => _withForced = v)),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.stacked_bar_chart_rounded,
            id: 'monitor/queues',
            description: 'Settings of the queue (strategy, length, one or two regions) live on the Queue screen and in Global config.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoWrap(
                  children: <Widget>[
                    DemoStat('on screen', '${FluentBar.activeItems.length}', color: Colors.green),
                    DemoStat('waiting top', '${FluentBar.mainQueueLength}', color: Colors.indigo),
                    DemoStat('waiting bottom', '${FluentBar.bottomQueueLength}', color: Colors.indigo),
                    DemoStat('requested', '${telemetry.count(FluentBarAnalyticsEvent.requested)}', color: Colors.blue),
                    DemoStat('shown', '${telemetry.count(FluentBarAnalyticsEvent.shown)}', color: Colors.green),
                    DemoStat('dropped', '${telemetry.count(FluentBarAnalyticsEvent.queueOverflow)}', color: Colors.red),
                    DemoStat('avg wait', '$averageWait ms', color: Colors.purple),
                  ],
                ),
                const SizedBox(height: 14),
                const QueueLanes(),
                const SizedBox(height: 12),
                DemoWrap(
                  children: <Widget>[
                    DemoButton('clearQueue()', onPressed: FluentBar.clearQueue),
                    DemoButton('closeAll()', onPressed: FluentBar.closeAll),
                    DemoButton('Clear history', icon: Icons.delete_outline, onPressed: telemetry.clear),
                  ],
                ),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.timeline_rounded,
            id: 'monitor/bars',
            description: 'Newest first. The dots are the lifecycle steps: queued, showing, visible, hiding, dismissed. Tap a bar for its timings, metrics and every analytics event with all fields.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DemoChoice<_Filter>(label: 'Show', values: _Filter.values, selected: _filter, labelOf: _filterLabel, onChanged: (_Filter v) => setState(() => _filter = v)),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const DemoNote('Nothing here yet - start the generator below.', icon: Icons.hourglass_empty_rounded)
                else
                  for (final BarRecord record in visible) BarRow(record, key: ObjectKey(record)),
              ],
            ),
          ),
        ],
      );
    },
  );
}
