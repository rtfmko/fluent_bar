import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../widgets/demo_kit.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late final LiveBar _bar = LiveBar(
    id: 'config_test',
    build: () => FluentBar.info<void>('Everything about me comes from the global config.', title: 'Test bar', duration: const Duration(seconds: 8)),
  );

  @override
  void initState() {
    super.initState();
    _bar.attach();
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  static void _patch(FluentBarConfig Function(FluentBarConfig config) change) => FluentBar.patchConfig(change);

  static const Map<String, FluentBarUpdateRate> _rates = <String, FluentBarUpdateRate>{
    'low': FluentBarUpdateRate.low,
    'medium': FluentBarUpdateRate.medium,
    'high': FluentBarUpdateRate.high,
    '60 fps': FluentBarUpdateRate.fps60,
    '120 fps': FluentBarUpdateRate.fps120,
  };

  static String _code(FluentBarConfig c) {
    const FluentBarConfig d = FluentBarConfig();
    final List<String> lines = <String>[
      if (c.enableMultiRegion != d.enableMultiRegion) 'enableMultiRegion: ${c.enableMultiRegion},',
      if (c.defaultPosition != d.defaultPosition) 'defaultPosition: FluentBarPosition.${c.defaultPosition.name},',
      if (c.topInset != null) 'topInset: ${c.topInset!.round()},',
      if (c.bottomInset != null) 'bottomInset: ${c.bottomInset!.round()},',
      if (c.defaultUseSafeArea != d.defaultUseSafeArea) 'defaultUseSafeArea: ${c.defaultUseSafeArea},',
      if (c.defaultTheme != null) 'defaultTheme: ${AppState.themeOf(c).label == 'Custom (neon)' ? 'const CustomBarTheme()' : 'FluentBarTheme.${_themeField(c)}'},',
      if (c.themeStyle != d.themeStyle) 'themeStyle: FluentBarThemeStyle.${c.themeStyle.name},',
      if (c.defaultThemeMode != d.defaultThemeMode) 'defaultThemeMode: FluentBarThemeMode.${c.defaultThemeMode.name},',
      if (c.defaultShowIcons != d.defaultShowIcons) 'defaultShowIcons: ${c.defaultShowIcons},',
      if (c.defaultEntranceAnimation != d.defaultEntranceAnimation) 'defaultEntranceAnimation: FluentBarEntranceAnimation.${c.defaultEntranceAnimation.name},',
      if (c.defaultDisableAnimations != d.defaultDisableAnimations) 'defaultDisableAnimations: ${c.defaultDisableAnimations},',
      if (c.respectSystemReduceMotion != d.respectSystemReduceMotion) 'respectSystemReduceMotion: ${c.respectSystemReduceMotion},',
      if (c.defaultTransitionDuration != d.defaultTransitionDuration) 'defaultTransitionDuration: Duration(milliseconds: ${c.defaultTransitionDuration.inMilliseconds}),',
      if (c.defaultReverseTransitionDuration != d.defaultReverseTransitionDuration) 'defaultReverseTransitionDuration: Duration(milliseconds: ${c.defaultReverseTransitionDuration.inMilliseconds}),',
      if (c.duplicateComparator != null) 'duplicateComparator: sameGroupComparator, // see the Queue & duplicates screen',
      if (c.defaultDuration != d.defaultDuration) 'defaultDuration: Duration(milliseconds: XMS),'.replaceFirst('XMS', '${c.defaultDuration.inMilliseconds}'),
      if (c.enableHaptics != d.enableHaptics) 'enableHaptics: ${c.enableHaptics},',
      if (c.defaultShowTimeoutBar != d.defaultShowTimeoutBar) 'defaultShowTimeoutBar: ${c.defaultShowTimeoutBar},',
      if (c.defaultTimeoutBarPosition != d.defaultTimeoutBarPosition) 'defaultTimeoutBarPosition: FluentBarTimeoutBarPosition.${c.defaultTimeoutBarPosition.name},',
      if (c.defaultTimeoutBarDirection != d.defaultTimeoutBarDirection) 'defaultTimeoutBarDirection: FluentBarTimeoutBarDirection.${c.defaultTimeoutBarDirection.name},',
      if (c.defaultTimeoutUpdateInterval != d.defaultTimeoutUpdateInterval)
        'defaultTimeoutUpdateInterval: FluentBarUpdateRate(Duration(milliseconds: ${c.defaultTimeoutUpdateInterval.interval.inMilliseconds})),',
      if (c.defaultIsSwipeEnabled != d.defaultIsSwipeEnabled) 'defaultIsSwipeEnabled: ${c.defaultIsSwipeEnabled},',
      if (c.defaultDismissOnTap != d.defaultDismissOnTap) 'defaultDismissOnTap: ${c.defaultDismissOnTap},',
      if (c.defaultShowCloseButton != d.defaultShowCloseButton) 'defaultShowCloseButton: ${c.defaultShowCloseButton},',
      if (c.closeButtonLabel != null) "closeButtonLabel: '${c.closeButtonLabel}',",
      if (c.defaultSemantics != d.defaultSemantics) 'defaultSemantics: FluentBarSemantics.${c.defaultSemantics.name},',
      if (c.defaultPauseOnTouch != d.defaultPauseOnTouch) 'defaultPauseOnTouch: ${c.defaultPauseOnTouch},',
      if (c.defaultQueueStrategy.runtimeType != d.defaultQueueStrategy.runtimeType) 'defaultQueueStrategy: const ${c.defaultQueueStrategy.runtimeType}(),',
      if (c.maxQueueLength != d.maxQueueLength) 'maxQueueLength: ${c.maxQueueLength},',
      if (c.defaultDuplicatePolicy != d.defaultDuplicatePolicy) 'defaultDuplicatePolicy: FluentBarDuplicatePolicy.${c.defaultDuplicatePolicy.name},',
      if (c.defaultRelocationStrategy != d.defaultRelocationStrategy) 'defaultRelocationStrategy: FluentBarRelocationStrategy.${c.defaultRelocationStrategy.name},',
      if (c.progressTheme != d.progressTheme)
        'progressTheme: const FluentBarProgressTheme(style: FluentBarProgressStyle.${c.progressTheme.style.name}, showText: ${c.progressTheme.showText}, textEffect: FluentBarProgressTextEffect.${c.progressTheme.textEffect.name}, thickness: ${c.progressTheme.thickness.round()}${c.progressTheme.announceUpdates ? ', announceUpdates: true' : ''}${c.progressTheme.successIconDuration == null ? '' : ', successIconDuration: Duration(milliseconds: ${c.progressTheme.successIconDuration!.inMilliseconds})'}),',
      if (c.disabledAnalyticsEvents.isNotEmpty) 'disabledAnalyticsEvents: {${c.disabledAnalyticsEvents.map((FluentBarAnalyticsEvent e) => 'FluentBarAnalyticsEvent.${e.name}').join(', ')}},',
      if (c.typeOverrides != null) 'typeOverrides: {...}, // see the Themes & types screen',
    ];

    if (lines.isEmpty) return '// Everything is at its default value.\nFluentBar.initialize(config: const FluentBarConfig());';
    return 'FluentBar.initialize(\n  config: FluentBarConfig(\n${lines.map((String line) => '    $line').join('\n')}\n  ),\n);';
  }

  static String _themeField(FluentBarConfig c) => switch (AppState.themeOf(c).label) {
    'Liquid glass' => 'liquidGlass',
    final String label => label.toLowerCase(),
  };

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<FluentBarConfig>(
    valueListenable: FluentBar.configNotifier,
    builder: (BuildContext context, FluentBarConfig c, _) => DemoPage(
      title: 'Global config',
      showConfigAction: false,
      subtitle:
          'One place for the defaults of every bar. Priority is always: the bar itself, then its type and theme, then this config. Changes apply at once - also to bars that are already on screen.',
      bottomNavigationBar: DemoLiveBarControl(
        _bar,
        showLabel: 'Show a test bar',
        trailing: <Widget>[
          const SizedBox(width: 8),
          DemoButton('Reset', icon: Icons.restart_alt, tone: AppState.isBase(c) ? DemoTone.neutral : DemoTone.danger, onPressed: AppState.isBase(c) ? null : AppState.resetConfig),
        ],
      ),
      children: <Widget>[
        DemoSection(
          icon: Icons.code_rounded,
          id: 'config/code',
          description: 'Only the settings that differ from the defaults. Pass it to FluentBar.initialize, FluentBarScope(config: ...) or change it later with FluentBar.patchConfig.',
          child: DemoCode(_code(c), initiallyExpanded: true),
        ),
        DemoSection(
          icon: Icons.place_outlined,
          id: 'config/placement',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoChoice<FluentBarPosition>(
                label: 'Default position',
                values: FluentBarPosition.values,
                selected: c.defaultPosition,
                onChanged: (FluentBarPosition v) => _patch((FluentBarConfig c) => c.copyWith(defaultPosition: v)),
              ),
              const SizedBox(height: 8),
              DemoSwitch(
                label: 'Two regions (top + bottom)',
                hint: 'Off: one bar on screen at a time, a single queue',
                value: c.enableMultiRegion,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(enableMultiRegion: v)),
              ),
              DemoSwitch(
                label: 'Respect safe area',
                value: c.defaultUseSafeArea,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultUseSafeArea: v)),
              ),
              const SizedBox(height: 8),
              _InsetControl(
                label: 'Top inset',
                hint: 'Distance of top bars from the top edge',
                value: c.topInset,
                measured: FluentBar.measuredTopInset,
                measuredBy: 'FluentBarTopInset around the app bar',
                onChanged: (double? v) => _patch((FluentBarConfig c) => v == null ? c.copyWith(clearTopInset: true) : c.copyWith(topInset: v)),
              ),
              _InsetControl(
                label: 'Bottom inset',
                hint: 'Distance of bottom bars from the bottom edge',
                value: c.bottomInset,
                measured: FluentBar.measuredBottomInset,
                measuredBy: 'FluentBarBottomInset around the bottom panel',
                onChanged: (double? v) => _patch((FluentBarConfig c) => v == null ? c.copyWith(clearBottomInset: true) : c.copyWith(bottomInset: v)),
              ),
              const DemoNote(
                'One chain for both: the bar itself (withInsets), then its type, then this config value, then what the wrapper widget measured. "Respect safe area" is a separate thing - the system padding (notch, status bar, home gesture); the larger of the two is used, so on a device without such padding it changes nothing.',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 12),
              DemoChoice<FluentBarRelocationStrategy>(
                label: 'When a moved bar meets a busy region',
                values: FluentBarRelocationStrategy.values,
                selected: c.defaultRelocationStrategy,
                onChanged: (FluentBarRelocationStrategy v) => _patch((FluentBarConfig c) => c.copyWith(defaultRelocationStrategy: v)),
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.palette_outlined,
          id: 'config/look',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoChoice<ThemeOption>(label: 'Theme', values: AppState.themes, selected: AppState.themeOf(c), labelOf: (ThemeOption o) => o.label, onChanged: AppState.setTheme),
              const SizedBox(height: 12),
              DemoChoice<FluentBarThemeStyle>(
                label: 'Platform theme (used when no theme is set)',
                values: FluentBarThemeStyle.values,
                selected: c.themeStyle,
                onChanged: (FluentBarThemeStyle v) => _patch((FluentBarConfig c) => c.copyWith(themeStyle: v)),
              ),
              const SizedBox(height: 12),
              DemoChoice<FluentBarThemeMode>(
                label: 'Mode',
                values: FluentBarThemeMode.values,
                selected: c.defaultThemeMode,
                onChanged: (FluentBarThemeMode v) => _patch((FluentBarConfig c) => c.copyWith(defaultThemeMode: v)),
              ),
              const SizedBox(height: 12),
              DemoChoice<FluentBarEntranceAnimation>(
                label: 'Entrance animation',
                values: FluentBarEntranceAnimation.values,
                selected: c.defaultEntranceAnimation,
                onChanged: (FluentBarEntranceAnimation v) => _patch((FluentBarConfig c) => c.copyWith(defaultEntranceAnimation: v)),
              ),
              const SizedBox(height: 8),
              DemoSwitch(
                label: 'Icons',
                value: c.defaultShowIcons,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultShowIcons: v)),
              ),
              DemoSwitch(
                label: 'Disable animations',
                value: c.defaultDisableAnimations,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultDisableAnimations: v)),
              ),
              if (!c.defaultDisableAnimations) ...<Widget>[
                const SizedBox(height: 8),
                DemoSlider(
                  label: 'Entrance duration',
                  value: c.defaultTransitionDuration.inMilliseconds.toDouble(),
                  min: 100,
                  max: 1500,
                  divisions: 14,
                  format: (double v) => '${v.round()} ms',
                  onChanged: (double v) => _patch((FluentBarConfig c) => c.copyWith(defaultTransitionDuration: Duration(milliseconds: v.round()))),
                ),
                DemoSlider(
                  label: 'Exit duration',
                  value: c.defaultReverseTransitionDuration.inMilliseconds.toDouble(),
                  min: 100,
                  max: 1500,
                  divisions: 14,
                  format: (double v) => '${v.round()} ms',
                  onChanged: (double v) => _patch((FluentBarConfig c) => c.copyWith(defaultReverseTransitionDuration: Duration(milliseconds: v.round()))),
                ),
                const DemoNote('Hide and show the test bar to see the new timing.', icon: Icons.info_outline),
              ],
              const SizedBox(height: 8),
              DemoSwitch(
                label: 'Follow the system "reduce motion" setting',
                hint: 'iOS Reduce Motion, Android Remove animations. Bars then fade in instead of sliding, attention effects are skipped, icons change at once. Color changes still fade',
                value: c.respectSystemReduceMotion,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(respectSystemReduceMotion: v)),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AppState.simulateReduceMotion,
                builder: (BuildContext context, bool simulated, _) => DemoSwitch(
                  label: 'Pretend the setting is on',
                  hint: 'For this demo only, no need to change the device. Turn it on, then hide and show the test bar - or try Shake on the Behavior screen',
                  value: simulated,
                  onChanged: (bool v) => AppState.simulateReduceMotion.value = v,
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.timer_outlined,
          id: 'config/lifetime',
          description: 'How long a bar lives when neither the bar nor its type says otherwise (the built-in error type keeps its own 6 s), and the thin line that shows the time left.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoSlider(
                label: 'Default duration',
                value: c.defaultDuration.inMilliseconds / 1000,
                min: 1,
                max: 15,
                divisions: 28,
                format: (double v) => '${v.toStringAsFixed(1)} s',
                onChanged: (double v) => _patch((FluentBarConfig c) => c.copyWith(defaultDuration: Duration(milliseconds: (v * 1000).round()))),
              ),
              DemoSwitch(
                label: 'Show the timeout bar',
                value: c.defaultShowTimeoutBar,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultShowTimeoutBar: v)),
              ),
              const SizedBox(height: 8),
              DemoChoice<FluentBarTimeoutBarPosition>(
                label: 'Position',
                values: FluentBarTimeoutBarPosition.values,
                selected: c.defaultTimeoutBarPosition,
                onChanged: (FluentBarTimeoutBarPosition v) => _patch((FluentBarConfig c) => c.copyWith(defaultTimeoutBarPosition: v)),
              ),
              const SizedBox(height: 12),
              DemoChoice<FluentBarTimeoutBarDirection>(
                label: 'Direction',
                values: FluentBarTimeoutBarDirection.values,
                selected: c.defaultTimeoutBarDirection,
                onChanged: (FluentBarTimeoutBarDirection v) => _patch((FluentBarConfig c) => c.copyWith(defaultTimeoutBarDirection: v)),
              ),
              const SizedBox(height: 12),
              DemoChoice<String>(
                label: 'Refresh rate',
                values: _rates.keys.toList(),
                selected: _rates.entries.firstWhere((MapEntry<String, FluentBarUpdateRate> e) => e.value == c.defaultTimeoutUpdateInterval, orElse: () => _rates.entries.elementAt(1)).key,
                onChanged: (String v) => _patch((FluentBarConfig c) => c.copyWith(defaultTimeoutUpdateInterval: _rates[v])),
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.touch_app_outlined,
          id: 'config/gestures',
          child: Column(
            children: <Widget>[
              DemoSwitch(
                label: 'Swipe to dismiss',
                value: c.defaultIsSwipeEnabled,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultIsSwipeEnabled: v)),
              ),
              DemoSwitch(
                label: 'Tap to dismiss',
                value: c.defaultDismissOnTap,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultDismissOnTap: v)),
              ),
              DemoSwitch(
                label: 'Show the close button',
                hint: 'A cross on every bar; snacks, toasts, banners and loading bars stay without it',
                value: c.defaultShowCloseButton,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultShowCloseButton: v)),
              ),
              DemoSwitch(
                label: 'Own label of the close button for screen readers',
                hint: "'Dismiss the message' instead of the Close label of the app localization",
                value: c.closeButtonLabel != null,
                onChanged: (bool v) => _patch((FluentBarConfig c) => v ? c.copyWith(closeButtonLabel: 'Dismiss the message') : c.copyWith(clearCloseButtonLabel: true)),
              ),
              const SizedBox(height: 8),
              DemoChoice<FluentBarSemantics>(
                label: 'For a screen reader a bar is',
                values: FluentBarSemantics.values,
                selected: c.defaultSemantics,
                onChanged: (FluentBarSemantics v) => _patch((FluentBarConfig c) => c.copyWith(defaultSemantics: v)),
              ),
              const SizedBox(height: 8),
              DemoSwitch(
                label: 'Pause while touched or hovered',
                value: c.defaultPauseOnTouch,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(defaultPauseOnTouch: v)),
              ),
              DemoSwitch(
                label: 'Haptic feedback',
                hint: 'Master switch: off silences built-in vibration and custom haptic callbacks alike',
                value: c.enableHaptics,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(enableHaptics: v)),
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.reorder_rounded,
          id: 'config/queue',
          description: AppState.strategyOf(c).hint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoChoice<StrategyOption>(
                label: 'Queue strategy',
                values: AppState.strategies,
                selected: AppState.strategyOf(c),
                labelOf: (StrategyOption o) => o.label,
                onChanged: (StrategyOption v) => _patch((FluentBarConfig c) => c.copyWith(defaultQueueStrategy: v.strategy)),
              ),
              const SizedBox(height: 12),
              DemoSlider(
                label: 'Max queue length (per region)',
                value: c.maxQueueLength.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                format: (double v) => '${v.round()}',
                onChanged: (double v) => _patch((FluentBarConfig c) => c.copyWith(maxQueueLength: v.round())),
              ),
              DemoChoice<FluentBarDuplicatePolicy>(
                label: 'Duplicate policy',
                values: FluentBarDuplicatePolicy.values,
                selected: c.defaultDuplicatePolicy,
                onChanged: (FluentBarDuplicatePolicy v) => _patch((FluentBarConfig c) => c.copyWith(defaultDuplicatePolicy: v)),
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.insights_rounded,
          id: 'config/analytics-events',
          description:
              'Every event is delivered to analytics listeners by default. Switch off the ones your app does not need - they will not reach any listener. Check the result on the Analytics and Monitor screens.',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final FluentBarAnalyticsEvent event in FluentBarAnalyticsEvent.values)
                FilterChip(
                  label: Text(event.name),
                  selected: !c.disabledAnalyticsEvents.contains(event),
                  showCheckmark: true,
                  onSelected: (bool isEnabled) => _patch(
                    (FluentBarConfig c) =>
                        c.copyWith(disabledAnalyticsEvents: isEnabled ? (c.disabledAnalyticsEvents.toSet()..remove(event)) : <FluentBarAnalyticsEvent>{...c.disabledAnalyticsEvents, event}),
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.downloading_rounded,
          id: 'config/progress',
          description: 'Defaults for every progress bar. They merge field by field: a bar that sets only its color still gets the thickness and text effect from here.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoChoice<FluentBarProgressStyle>(
                label: 'Style',
                values: FluentBarProgressStyle.values,
                selected: c.progressTheme.style,
                onChanged: (FluentBarProgressStyle v) => _patch((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(style: v))),
              ),
              const SizedBox(height: 12),
              DemoChoice<FluentBarProgressTextEffect>(
                label: 'Text effect',
                values: FluentBarProgressTextEffect.values,
                selected: c.progressTheme.textEffect,
                onChanged: (FluentBarProgressTextEffect v) => _patch((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(textEffect: v))),
              ),
              const SizedBox(height: 8),
              DemoSwitch(
                label: 'Show text',
                value: c.progressTheme.showText,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(showText: v))),
              ),
              DemoSwitch(
                label: 'Read out every update',
                hint: 'Screen readers: off means only the result is announced',
                value: c.progressTheme.announceUpdates,
                onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(announceUpdates: v))),
              ),
              DemoSlider(
                label: 'Thickness',
                value: c.progressTheme.thickness,
                min: 2,
                max: 12,
                divisions: 10,
                format: (double v) => '${v.round()} px',
                onChanged: (double v) => _patch((FluentBarConfig c) => c.copyWith(progressTheme: c.progressTheme.copyWith(thickness: v))),
              ),
              DemoWrap(
                children: <Widget>[
                  DemoButton(
                    'Try it: a bar that sets only its value',
                    onPressed: () {
                      final FluentBarEntry<void>? entry = FluentBar.info<void>('Everything but the value comes from the config.').withId('config_progress').withLinearProgress(value: 0).show();
                      DemoProgressRunner.playOn(entry, completedMessage: 'Done');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InsetControl extends StatelessWidget {
  final String label;
  final String hint;
  final double? value;
  final ValueListenable<double> measured;
  final String measuredBy;
  final ValueChanged<double?> onChanged;

  const _InsetControl({required this.label, required this.hint, required this.value, required this.measured, required this.measuredBy, required this.onChanged});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: measured,
    builder: (BuildContext context, double measuredValue, _) {
      final bool isAuto = value == null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DemoSwitch(
            label: '$label: ${isAuto ? 'auto (${measuredValue.round()} px now)' : '${value!.round()} px'}',
            hint: isAuto ? '$hint. Auto = measured by $measuredBy.' : '$hint. Fixed: the measured ${measuredValue.round()} px is ignored.',
            value: isAuto,
            onChanged: (bool auto) => onChanged(auto ? null : measuredValue),
          ),
          if (!isAuto) DemoSlider(label: label, value: value!, min: 0, max: 200, divisions: 40, format: (double v) => '${v.round()} px', onChanged: onChanged),
        ],
      );
    },
  );
}
