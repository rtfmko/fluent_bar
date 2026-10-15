import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../app/telemetry.dart';
import '../widgets/demo_kit.dart';
import '../widgets/telemetry_views.dart';

class _BrokenTheme extends FluentBarTheme {
  const _BrokenTheme();

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) => throw StateError('boxDecoration is broken');

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle();

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => const TextStyle();
}

class _BrokenType extends FluentBarType {
  const _BrokenType();

  @override
  String get name => 'broken';

  @override
  Duration get duration => throw StateError('duration getter is broken');
}

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  FluentBarAnalyticsEvent? _filter;

  static const List<FluentBarAnalyticsEvent> _counters = <FluentBarAnalyticsEvent>[
    FluentBarAnalyticsEvent.requested,
    FluentBarAnalyticsEvent.queued,
    FluentBarAnalyticsEvent.shown,
    FluentBarAnalyticsEvent.dismissed,
    FluentBarAnalyticsEvent.updated,
    FluentBarAnalyticsEvent.tapped,
    FluentBarAnalyticsEvent.actionTapped,
    FluentBarAnalyticsEvent.paused,
    FluentBarAnalyticsEvent.relocated,
    FluentBarAnalyticsEvent.queueOverflow,
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Telemetry.instance,
    builder: (BuildContext context, _) {
      final Telemetry telemetry = Telemetry.instance;

      return DemoPage(
        title: 'Analytics & safety',
        subtitle:
            'Every step of a bar\'s life is reported to analytics listeners, and every failure - yours or the library\'s - goes to the error handler instead of crashing the app. The logs below have been recording since the app started.',
        children: <Widget>[
          DemoSection(
            icon: Icons.insights_rounded,
            id: 'analytics/stream',
            description: 'Tap a counter to filter the log by event. Tap a row to open the bar it belongs to: its lifecycle, metrics and every event with all the fields that came with it.',
            code: '''
FluentBar.addAnalyticsListener((FluentBarAnalyticsPayload payload) {
  analytics.log(payload.event.name, {
    'id': payload.item.id,
    'type': payload.item.type.name,
    'reason': payload.metrics?.dismissReason.name,
    'visibleMs': payload.metrics?.visibleDuration.inMilliseconds,
    'wasActionTapped': payload.metrics?.wasActionTapped,
  });
});

// An event knows its group: isLifecycle, isInteraction, isProgress, isRejected, isCountdown, hasMetrics.
FluentBar.addAnalyticsListener((payload) {
  if (payload.event.isInteraction) analytics.log('bar_\${payload.event.name}');
  if (payload.event.hasMetrics) analytics.log('bar_closed', payload.metrics!.toFlatMap());
  if (payload.metrics?.dismissReason.isByUser ?? false) analytics.log('bar_closed_by_user');   // also isByCode, isAutomatic
});

// So does a lifecycle state: isQueued, isOnScreen, isInteractive, isAnimating, isFinished, isDismissed.
if (!entry.controller.stateNotifier.value.isFinished) entry.update(message: 'Almost done');

// A button gets a stable name for analytics; Cancel and Retry buttons name themselves.
FluentBar.info('Order cancelled').withAction('Undo', analyticsName: 'undo_order').show();   // action_name: undo_order

// A listener is removed the same way it was added (keep a reference to the function):
FluentBar.removeAnalyticsListener(listener);
FluentBar.removeErrorHandler(handler);

// Typed payload travels with the bar and comes back in the action:
FluentBar.success<Order>('Order shipped')
    .withPayload(order)
    .withAction('Track', onPressed: (controller, order) => openTracking(order!.id))
    .show();''',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoWrap(
                  children: <Widget>[
                    for (final FluentBarAnalyticsEvent event in _counters)
                      DemoStat(
                        event.name,
                        '${telemetry.count(event)}',
                        color: colorOfEvent(event),
                        isSelected: _filter == event,
                        onTap: () => setState(() => _filter = _filter == event ? null : event),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DemoWrap(
                  children: <Widget>[
                    DemoButton(
                      'Show a rich bar',
                      tone: DemoTone.primary,
                      onPressed: () => FluentBar.success<Map<String, Object>>('Order #1042 has been shipped', payload: const <String, Object>{'orderId': 1042, 'total': 129.9})
                          .withTitle('On its way')
                          .withId('diag_${DateTime.now().millisecondsSinceEpoch}')
                          .withMeta(const <String, dynamic>{'screen': 'diagnostics', 'campaign': 'spring'})
                          .withPriority(FluentBarPriority.high)
                          .withAction('Track')
                          .withDuration(const Duration(seconds: 3))
                          .show(),
                    ),
                    DemoButton(
                      'Tap / pause / move',
                      onPressed: () {
                        final FluentBarEntry<void>? entry = FluentBar.info<void>(
                          'Tap me, hold me, or wait: I will pause, resume and move.',
                        ).withId('diag_events').withDuration(const Duration(seconds: 6)).dismissOnTap(false).onTap((_) {}).withTimeoutBar().show();
                        Future<void>.delayed(const Duration(seconds: 1), () => entry?.pause());
                        Future<void>.delayed(const Duration(seconds: 2), () => entry?.resume());
                        Future<void>.delayed(const Duration(seconds: 3), () => entry?.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom)));
                      },
                    ),
                    DemoButton(
                      'Progress bar',
                      onPressed: () => DemoProgressRunner.playOn(
                        FluentBar.info<void>('Uploading').withId('diag_progress').withLinearProgress(value: 0, showText: true).show(),
                        completedMessage: 'Uploaded',
                        motion: DemoProgressMotion.jumps,
                      ),
                    ),
                    DemoButton(
                      'Stress: 30 bars',
                      icon: Icons.speed_rounded,
                      tone: DemoTone.warning,
                      onPressed: () {
                        for (int i = 1; i <= 30; i++) {
                          FluentBar.showInfo('Stress bar $i', id: 'stress_$i', duration: const Duration(milliseconds: 600));
                        }
                      },
                    ),
                    DemoButton('Clear logs', icon: Icons.delete_outline, onPressed: telemetry.clear),
                  ],
                ),
                const SizedBox(height: 12),
                if (_filter != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DemoNote('Showing only "${_filter!.name}" events - tap the counter again to show all.', icon: Icons.filter_alt_outlined),
                  ),
                EventLog(events: _filter == null ? telemetry.events : telemetry.events.where((TelemetryEvent e) => e.event == _filter).toList()),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.health_and_safety_outlined,
            color: Colors.red,
            id: 'analytics/errors',
            description:
                'Callbacks, builders, themes and types are your code. If any of it throws, the library reports the error, falls back to a sensible default and keeps working. Press a button: the bar still appears, and the error lands in the log - tap it for the original error and the stack trace.',
            code: '''
FluentBar.addErrorHandler((FluentBarException error, StackTrace stackTrace) {
  // A warning is a misuse the library recovered from: log it. An error is worth a crash report.
  if (error.severity.isWarning) {
    logger.warning('fluent_bar: \${error.type.displayName}: \${error.error}');
    return;
  }
  crashReporter.record(error.error, stackTrace, reason: error.type.displayName);
});

// Arguments that do not fit together take the safe way and are reported as invalidCall:
entry.failProgress(message: 'Upload failed', retryLabel: 'Retry');   // no onRetry: no Retry button''',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoWrap(
                  children: <Widget>[
                    DemoButton(
                      'Action throws',
                      tone: DemoTone.danger,
                      onPressed: () => FluentBar.info<void>('Press the action - it throws.').withId('safe').withAction('Boom', onPressed: (_, _) => throw StateError('onPressed failed')).show(),
                    ),
                    DemoButton(
                      'onShow throws',
                      tone: DemoTone.danger,
                      onPressed: () => FluentBar.info<void>('My onShow callback threw, yet here I am.').withId('safe').onShow((_) => throw StateError('onShow failed')).show(),
                    ),
                    DemoButton(
                      'Progress builder throws',
                      tone: DemoTone.danger,
                      onPressed: () => FluentBar.info<void>('The progress builder failed - the standard indicator is used.')
                          .withId('safe')
                          .withLinearProgress(value: 0.4, showText: true)
                          .copyWith(
                            appearance: FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(progressBuilder: (_, _) => throw StateError('progressBuilder failed'))),
                          )
                          .show()
                          ?.completeProgress(message: 'The bar survived a failing progress builder.'),
                    ),
                    DemoButton(
                      'Content builder throws',
                      tone: DemoTone.danger,
                      onPressed: () => FluentBar.info<void>('The custom builder failed - the default layout is used.').withId('safe').withContent((_, _) => throw StateError('builder failed')).show(),
                    ),
                    DemoButton(
                      'Theme throws',
                      tone: DemoTone.danger,
                      onPressed: () => FluentBar.info<void>('The theme failed - the platform theme is used.').withId('safe').withTheme(const _BrokenTheme()).show(),
                    ),
                    DemoButton(
                      'Type getter throws',
                      tone: DemoTone.danger,
                      onPressed: () => FluentBar.showCustom<void>(const _BrokenType(), 'A getter of my type failed - the default value is used.', id: 'safe'),
                    ),
                    DemoButton(
                      'Subtract too much time',
                      tone: DemoTone.warning,
                      onPressed: () => FluentBar.showInfo<void>('Subtracting more than is left is reported as a warning.', id: 'safe')?.subtractDuration(const Duration(minutes: 5)),
                    ),
                    DemoButton(
                      'Retry without a callback',
                      tone: DemoTone.warning,
                      onPressed: () => FluentBar.info<void>('Uploading')
                          .withId('safe')
                          .withLinearProgress(value: 0.6, showText: true)
                          .show()
                          ?.failProgress(message: 'Upload failed. retryLabel came without onRetry, so there is no Retry button.', retryLabel: 'Retry'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ErrorLog(errors: telemetry.errors),
              ],
            ),
          ),
        ],
      );
    },
  );
}
